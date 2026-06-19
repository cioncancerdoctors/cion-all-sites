<?php
/* ─────────────────────────────────────────────────────────────
   submit.php — CION Cancer Clinics form gateway
   Validates → forwards to n8n → CSV backup (minimal fields only)
───────────────────────────────────────────────────────────── */

// ── Config ──
$N8N_WEBHOOK   = 'https://kushagrag86.app.n8n.cloud/webhook/cion-lead';
$IP_HASH_SALT  = 'cion-imad-ip-salt-change-me-2026';   // change this in production
$RATE_LIMIT    = 3;       // max submissions per IP per hour
$DUP_WINDOW    = 1800;    // duplicate phone block in seconds (30 min)
$MIN_FORM_AGE  = 2000;    // ms — reject if form submitted faster
$N8N_TIMEOUT   = 5;       // seconds

// ── Storage paths (above webroot ideally; using local for Hostinger compat) ──
$DIR             = __DIR__;
$LEAD_CSV        = $DIR . '/leads.csv';
$RATE_LIMIT_FILE = $DIR . '/rate-limit.json';
$DUP_FILE        = $DIR . '/recent-phones.json';
$ERROR_LOG       = $DIR . '/errors.log';

// ── Headers ──
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

// ── Only POST allowed ──
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

// ── Helpers ──
function jsonError($msg, $code = 400) {
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg]);
    exit;
}
function logError($msg) {
    global $ERROR_LOG;
    @file_put_contents($ERROR_LOG, '[' . date('c') . '] ' . $msg . "\n", FILE_APPEND);
}
function getClientIp() {
    foreach (['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'REMOTE_ADDR'] as $k) {
        if (!empty($_SERVER[$k])) {
            $ip = explode(',', $_SERVER[$k])[0];
            return trim($ip);
        }
    }
    return '0.0.0.0';
}


// ── Lead scoring: Hot / Warm / Low ──
function scoreLead($intent, $concern, $sessionScore) {
    $hotIntents  = ['surgery_consultation','second_opinion','hipec_consultation','appointment'];
    $warmIntents = ['consultation','cost_consultation','pet_ct','second_opinion'];
    if (in_array($intent, $hotIntents))  return 'Hot';
    if (in_array($intent, $warmIntents)) return 'Warm';
    if ($sessionScore >= 50)            return 'Hot';
    if ($sessionScore >= 20)            return 'Warm';
    // keyword check in concern
    $hotWords = ['hipec','pipac','whipple','surgery','operated','inoperable','stage','cancer','urgent'];
    if ($concern) {
        foreach ($hotWords as $w) {
            if (stripos($concern, $w) !== false) return 'Hot';
        }
    }
    return 'Low';
}

// ── 1) Honeypot ──
if (!empty($_POST['website_url'])) {
    // Silent success to confuse bots
    echo json_encode(['success' => true]);
    exit;
}

// ── 2) Form age (anti-bot) ──
$formAge = intval($_POST['form_age_ms'] ?? 0);
if ($formAge > 0 && $formAge < $MIN_FORM_AGE) {
    logError('Form age too short: ' . $formAge . 'ms');
    jsonError('Submission too fast');
}

// ── 3) Required fields ──
$name    = trim($_POST['name'] ?? '');
$phone   = preg_replace('/\D/', '', $_POST['phone'] ?? '');
$concern = trim($_POST['condition_interest_key'] ?? '');
$city    = trim($_POST['patient_city'] ?? '');
$consent = ($_POST['consent_marketing'] ?? '') === 'yes';

if (!$name)    jsonError('Name required');
if (!$concern) jsonError('Cancer concern required');
if (!$city)    jsonError('City required');
if (!$consent) jsonError('Consent required');

// ── 4) Phone validation (Indian 10-digit, starts with 6-9) ──
if (strlen($phone) === 12 && substr($phone, 0, 2) === '91') $phone = substr($phone, 2);
if (strlen($phone) === 11 && substr($phone, 0, 1) === '0')  $phone = substr($phone, 1);
if (strlen($phone) !== 10 || !preg_match('/^[6-9]/', $phone)) {
    jsonError('Please enter a valid 10-digit Indian mobile number');
}

// ── 5) Rate limit (3/IP/hour) ──
$ip = getClientIp();
$now = time();
$rateData = [];
if (file_exists($RATE_LIMIT_FILE)) {
    $rateData = json_decode(@file_get_contents($RATE_LIMIT_FILE), true) ?: [];
}
// Clean old entries
foreach ($rateData as $k => $entry) {
    if ($entry['expires'] < $now) unset($rateData[$k]);
}
$ipKey = md5($ip);
if (isset($rateData[$ipKey])) {
    if ($rateData[$ipKey]['count'] >= $RATE_LIMIT) {
        logError('Rate limit exceeded: ' . $ip);
        jsonError('Too many submissions. Please call +91 90634 90160 directly.', 429);
    }
    $rateData[$ipKey]['count']++;
} else {
    $rateData[$ipKey] = ['count' => 1, 'expires' => $now + 3600];
}
@file_put_contents($RATE_LIMIT_FILE, json_encode($rateData), LOCK_EX);

// ── 6) Duplicate phone within 30 min ──
$dupData = [];
if (file_exists($DUP_FILE)) {
    $dupData = json_decode(@file_get_contents($DUP_FILE), true) ?: [];
}
foreach ($dupData as $p => $ts) {
    if ($ts < $now - $DUP_WINDOW) unset($dupData[$p]);
}
if (isset($dupData[$phone])) {
    jsonError('A request with this phone was just received. Our team will contact you shortly.');
}
$dupData[$phone] = $now;
@file_put_contents($DUP_FILE, json_encode($dupData), LOCK_EX);

// ── 7) Build payload for n8n ──
$ipHash = hash('sha256', $ip . $IP_HASH_SALT);
$serverTimestamp = date('c');
$leadId = $_POST['event_id'] ?? bin2hex(random_bytes(8));

$payload = [
    // visible
    'name'                    => $name,
    'phone'                   => $phone,
    'condition_interest_key'  => $concern,
    'patient_city'            => $city,
    'consent_marketing'       => 'yes',

    // page context
    'doctor_name_key'         => $_POST['doctor_name_key'] ?? '',
    'doctor_specialty_key'    => $_POST['doctor_specialty_key'] ?? '',
    'page_type'               => $_POST['page_type'] ?? '',
    'page_name'               => $_POST['page_name'] ?? '',
    'lp_variant'              => $_POST['lp_variant'] ?? '',
    'offer_type'              => $_POST['offer_type'] ?? '',
    'condition_page'          => $_POST['condition_page'] ?? '',
    'hostname'                => $_POST['hostname'] ?? '',
    'landing_page_url'        => $_POST['landing_page_url'] ?? '',
    'referrer'                => $_POST['referrer'] ?? '',

    // attribution
    'utm_source'              => $_POST['utm_source'] ?? '',
    'utm_medium'              => $_POST['utm_medium'] ?? '',
    'utm_campaign'            => $_POST['utm_campaign'] ?? '',
    'utm_content'             => $_POST['utm_content'] ?? '',
    'utm_term'                => $_POST['utm_term'] ?? '',
    'gclid'                   => $_POST['gclid'] ?? '',
    'fbclid'                  => $_POST['fbclid'] ?? '',
    'campaign_id'             => $_POST['campaign_id'] ?? '',
    'adset_id'                => $_POST['adset_id'] ?? '',
    'ad_id'                   => $_POST['ad_id'] ?? '',

    // session + dedup
    'session_score'           => intval($_POST['session_score'] ?? 0),
    'lead_temp'               => scoreLead($_POST['form_intent'] ?? $intent, $_POST['concern'] ?? '', intval($_POST['session_score'] ?? 0)),
    'event_id'                => $leadId,
    'meta_lead_id'            => $leadId,

    // consent + server-added
    'consent_version'         => $_POST['consent_version'] ?? 'v1.0-2026-05-04',
    'consent_timestamp'       => $_POST['consent_timestamp'] ?? $serverTimestamp,
    'server_timestamp'        => $serverTimestamp,
    'ip_hash'                 => $ipHash,
    'user_agent'              => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 250),

    // Phase 2 prep — empty initially, filled by call-centre via HubSpot
    'meta_event_name'         => '',
    'meta_event_timestamp'    => '',
    'meta_event_value_inr'    => 0,
];

// ── 8) Forward to n8n ──
$n8nSuccess = false;
$ch = curl_init($N8N_WEBHOOK);
curl_setopt_array($ch, [
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode($payload),
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => $N8N_TIMEOUT,
    CURLOPT_CONNECTTIMEOUT => $N8N_TIMEOUT,
]);
$response   = curl_exec($ch);
$httpCode   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError  = curl_error($ch);
curl_close($ch);

if ($httpCode >= 200 && $httpCode < 300) {
    $n8nSuccess = true;
} else {
    logError("n8n forward failed. HTTP $httpCode. cURL: $curlError. Lead ID: $leadId");
}

// ── 9) Local CSV backup (MINIMAL fields only — NO cancer concern saved locally) ──
$csvRow = [
    $serverTimestamp,
    $leadId,
    $name,
    $phone,
    $city,
    $payload['utm_source'],
    $payload['page_name'],
    $n8nSuccess ? 'forwarded' : 'n8n_failed',
];
if (!file_exists($LEAD_CSV)) {
    @file_put_contents($LEAD_CSV, "timestamp,lead_id,name,phone,city,source,page,status\n");
}
@file_put_contents($LEAD_CSV, '"' . implode('","', array_map(function($v) { return str_replace('"', '""', $v); }, $csvRow)) . "\"\n", FILE_APPEND | LOCK_EX);

// ── 10) Respond ──
// Always return success to user (we have CSV backup even if n8n fails)
echo json_encode([
    'success'  => true,
    'event_id' => $leadId,
]);
