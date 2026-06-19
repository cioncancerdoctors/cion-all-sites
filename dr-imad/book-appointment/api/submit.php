<?php
/* ─────────────────────────────────────────────────────────────
   submit.php — Lead form handler
   Validates → saves files → forwards to n8n → CSV backup
   Field names: name, phone, concern, city, attachments[]
   No consent checkbox. Consent is implied by form submission.
───────────────────────────────────────────────────────────── */

$N8N_WEBHOOK   = 'https://kushagrag86.app.n8n.cloud/webhook/cion-lead';
$N8N_TIMEOUT   = 8;
$RATE_LIMIT    = 3;
$RATE_WINDOW   = 3600;
$DUP_WINDOW    = 1800;

$DIR            = __DIR__;
$UPLOAD_DIR     = $DIR . '/uploads/';
$RATE_FILE      = $DIR . '/rate-limit.json';
$DUP_FILE       = $DIR . '/recent-phones.json';
$ERROR_LOG      = $DIR . '/errors.log';
$LEAD_CSV       = $DIR . '/leads.csv';

$ALLOWED_MIME   = ['application/pdf','image/jpeg','image/jpg','image/png'];
$ALLOWED_EXT    = ['pdf','jpg','jpeg','png'];
$MAX_FILE_SIZE  = 10 * 1024 * 1024; // 10MB
$MAX_FILES      = 3;

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

// ── Only POST allowed ──
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

function jsonError($msg, $code = 400) {
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg]);
    exit;
}
function logError($msg) {
    global $ERROR_LOG;
    @file_put_contents($ERROR_LOG, date('[Y-m-d H:i:s] ') . $msg . PHP_EOL, FILE_APPEND | LOCK_EX);
}
function getIp() {
    foreach (['HTTP_CF_CONNECTING_IP','HTTP_X_FORWARDED_FOR','REMOTE_ADDR'] as $k) {
        if (!empty($_SERVER[$k])) return trim(explode(',', $_SERVER[$k])[0]);
    }
    return '0.0.0.0';
}

// ── Lead scoring ──
function scoreLead($intent, $concern, $sessionScore) {
    $hotIntents  = ['surgery_consultation','second_opinion','hipec_consultation','appointment','free_second_opinion'];
    $warmIntents = ['consultation','cost_consultation','pet_ct','online_second_opinion'];
    if (in_array($intent, $hotIntents))  return 'Hot';
    if (in_array($intent, $warmIntents)) return 'Warm';
    if ($sessionScore >= 50)             return 'Hot';
    if ($sessionScore >= 20)             return 'Warm';
    $hotWords = ['hipec','pipac','whipple','surgery','operated','inoperable','stage','cancer','urgent','second opinion'];
    if ($concern) {
        foreach ($hotWords as $w) {
            if (stripos($concern, $w) !== false) return 'Hot';
        }
    }
    return 'Low';
}

// ── 1. Honeypot ──
if (!empty($_POST['website'])) {
    echo json_encode(['success' => true]);
    exit;
}

// ── 2. Timestamp bot check ──
$formAge = intval($_POST['form_age_ms'] ?? 0);
if ($formAge > 0 && $formAge < 2000) {
    echo json_encode(['success' => true]);
    exit;
}

// ── 3. Read fields ──
$name    = trim($_POST['name']    ?? '');
$phone   = preg_replace('/\D/', '', $_POST['phone'] ?? '');
$concern = trim($_POST['concern'] ?? '');
$city    = trim($_POST['city']    ?? '');

// ── 4. Validate ──
if (!$name)  jsonError('Name required');

if (strlen($phone) === 12 && substr($phone, 0, 2) === '91') $phone = substr($phone, 2);
if (strlen($phone) === 11 && substr($phone, 0, 1) === '0')  $phone = substr($phone, 1);
if (strlen($phone) !== 10 || !preg_match('/^[6-9]/', $phone)) {
    jsonError('Please enter a valid 10-digit Indian mobile number');
}

// ── 5. Rate limiting ──
$ip       = getIp();
$rateData = json_decode(@file_get_contents($RATE_FILE), true) ?: [];
$now      = time();
$rateData = array_filter($rateData, function($t) use ($now, $RATE_WINDOW) { return ($now - $t) < $RATE_WINDOW; });
$ipHits   = array_filter($rateData, function($t, $k) use ($ip) { return $k === $ip; }, ARRAY_FILTER_USE_BOTH);
if (count($ipHits) >= $RATE_LIMIT) {
    jsonError('Too many submissions. Please call +91 90634 90160 directly.', 429);
}
$rateData[$ip . '_' . $now] = $now;
@file_put_contents($RATE_FILE, json_encode($rateData), LOCK_EX);

// ── 6. Duplicate phone check ──
$dupData = json_decode(@file_get_contents($DUP_FILE), true) ?: [];
$dupData = array_filter($dupData, function($t) use ($now, $DUP_WINDOW) { return ($now - $t) < $DUP_WINDOW; });
if (isset($dupData[$phone])) {
    jsonError('A request with this number was just received. Our team will contact you shortly.');
}
$dupData[$phone] = $now;
@file_put_contents($DUP_FILE, json_encode($dupData), LOCK_EX);

// ── 7. Handle file uploads ──
$attachedFiles = [];
if (!empty($_FILES['attachments']['name'][0])) {
    if (!is_dir($UPLOAD_DIR)) {
        @mkdir($UPLOAD_DIR, 0755, true);
        // Block direct execution of uploaded files
        @file_put_contents($UPLOAD_DIR . '.htaccess',
            "Options -Indexes\n" .
            "<FilesMatch '.'>\n  SetHandler default-handler\n  Options -ExecCGI\n</FilesMatch>\n" .
            "php_flag engine off\n"
        );
    }
    $fileCount = count(array_filter($_FILES['attachments']['name']));
    if ($fileCount > $MAX_FILES) jsonError('Maximum ' . $MAX_FILES . ' files allowed.');

    foreach ($_FILES['attachments']['name'] as $i => $origName) {
        if (empty($origName)) continue;
        if ($_FILES['attachments']['error'][$i] !== UPLOAD_ERR_OK) {
            logError("File upload error {$_FILES['attachments']['error'][$i]} for $origName");
            continue;
        }
        if ($_FILES['attachments']['size'][$i] > $MAX_FILE_SIZE) {
            jsonError("File \"$origName\" exceeds 10MB limit.");
        }
        $finfo    = new finfo(FILEINFO_MIME_TYPE);
        $mime     = $finfo->file($_FILES['attachments']['tmp_name'][$i]);
        $ext      = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
        if (!in_array($mime, $ALLOWED_MIME) || !in_array($ext, $ALLOWED_EXT)) {
            jsonError("File \"$origName\" type not allowed. Use PDF, JPG or PNG.");
        }
        $safeFile = bin2hex(random_bytes(16)) . '.' . $ext;
        $dest     = $UPLOAD_DIR . $safeFile;
        if (move_uploaded_file($_FILES['attachments']['tmp_name'][$i], $dest)) {
            $attachedFiles[] = $safeFile;
        } else {
            logError("Could not move uploaded file $origName");
        }
    }
}

// ── 8. Build payload ──
$leadId    = $_POST['event_id'] ?? bin2hex(random_bytes(8));
$intent    = $_POST['form_intent'] ?? $_POST['intent'] ?? 'consultation';
$timestamp = date('Y-m-d H:i:s');

$payload = [
    'timestamp'               => $timestamp,
    'lead_id'                 => $leadId,
    'event_id'                => $leadId,
    'name'                    => $name,
    'phone'                   => $phone,
    'concern'                 => $concern,
    'city'                    => $city,
    'doctor_name'             => $_POST['doctor_name']        ?? '',
    'doctor_speciality'       => $_POST['doctor_speciality']  ?? '',
    'cancer_type'             => $_POST['cancer_type']        ?? '',
    'offer_type'              => $_POST['offer_type']         ?? '',
    'page_type'               => $_POST['page_type']          ?? '',
    'intent'                  => $intent,
    'funnel_stage'            => $_POST['funnel_stage']       ?? '',
    'landing_page_url'        => $_POST['landing_page_url']   ?? '',
    'hostname'                => $_POST['hostname']           ?? '',
    'utm_source'              => $_POST['utm_source']         ?? '',
    'utm_medium'              => $_POST['utm_medium']         ?? '',
    'utm_campaign'            => $_POST['utm_campaign']       ?? '',
    'utm_adset'               => $_POST['utm_adset']          ?? '',
    'utm_ad'                  => $_POST['utm_ad']             ?? '',
    'gclid'                   => $_POST['gclid']              ?? '',
    'fbclid'                  => $_POST['fbclid']             ?? '',
    'session_score'           => intval($_POST['session_score'] ?? 0),
    'lead_temp'               => scoreLead($intent, $concern, intval($_POST['session_score'] ?? 0)),
    'consent_version'         => $_POST['consent_version']    ?? '',
    'attached_files'          => $attachedFiles,
    'attached_file_count'     => count($attachedFiles),
    'ip'                      => $ip,
];

// ── 9. Forward to n8n ──
$n8nSuccess = false;
$ch = curl_init($N8N_WEBHOOK);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode($payload),
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    CURLOPT_TIMEOUT        => $N8N_TIMEOUT,
    CURLOPT_CONNECTTIMEOUT => $N8N_TIMEOUT,
    CURLOPT_SSL_VERIFYPEER => true,
]);
$response  = curl_exec($ch);
$httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

if ($httpCode >= 200 && $httpCode < 300) {
    $n8nSuccess = true;
} else {
    logError("n8n failed. HTTP $httpCode. cURL: $curlError. Lead: $leadId");
}

// ── 10. CSV backup (always) ──
$csvRow = [
    $timestamp,
    $leadId,
    $name,
    $phone,
    $city,
    $payload['utm_source'],
    $payload['landing_page_url'],
    $payload['lead_temp'],
    implode('|', $attachedFiles),
    $n8nSuccess ? 'forwarded' : 'n8n_failed',
];
if (!file_exists($LEAD_CSV)) {
    @file_put_contents($LEAD_CSV, "timestamp,lead_id,name,phone,city,source,page,lead_temp,files,status\n");
}
@file_put_contents($LEAD_CSV, '"' . implode('","', array_map(function($v) {
    return str_replace('"', '""', $v);
}, $csvRow)) . '"' . PHP_EOL, FILE_APPEND | LOCK_EX);

// ── 11. Respond ──
echo json_encode([
    'success'  => true,
    'event_id' => $leadId,
]);
