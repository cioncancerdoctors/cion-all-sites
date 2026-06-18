<?php
header('Content-Type: application/json; charset=utf-8');

// HubSpot token: load from a private config OUTSIDE the web root if present, else
// fall back to the inline token. To remove the inline token: rotate it in HubSpot,
// create /home/u885652959/private/cion-config.php defining CION_HS_TOKEN, then this
// fallback becomes dead and can be deleted. See seo-engine/cion-config.TEMPLATE.php.
$__cfg = '/home/u885652959/private/cion-config.php';
if (is_file($__cfg)) { require_once $__cfg; }
$HS_TOKEN = defined('CION_HS_TOKEN') ? CION_HS_TOKEN : 'REDACTED';

$HS_BASE  = 'https://api.hubapi.com/crm/v3/objects';
$LOG_FILE = __DIR__ . '/leads.log';
$ERR_FILE = __DIR__ . '/errors.log';

$siteMap = [
    'cioncancerdrimad.com'          => 'IM-Web',
    'cioncancerdrvinay.com'         => 'VM-Web',
    'cioncancerdrmurali.com'        => 'MK-Web',
    'cioncancerdrsandeep.com'       => 'SD-Web',
    'cioncancerdrkiranmayee.com'    => 'KM-Web',
    'cioncancerdrbasudev.com'       => 'BD-Web',
    'cioncancerdrraghvendra.com'    => 'RG-Web',
    'cioncancerdrcraghavendra.info' => 'CR-Web',
    'cioncancerdrowais.com'         => 'OW-Web',
];

// ── Origin / Referer ──
$refererHost = parse_url($_SERVER['HTTP_REFERER'] ?? '', PHP_URL_HOST) ?: '';
$originHost  = parse_url($_SERVER['HTTP_ORIGIN']  ?? '', PHP_URL_HOST) ?: '';
$host        = isset($siteMap[$originHost]) ? $originHost : $refererHost;
$path        = trim(parse_url($_SERVER['HTTP_REFERER'] ?? '/', PHP_URL_PATH) ?? '/', '/') ?: 'home';
$source      = $siteMap[$host] ?? ($host ?: 'unknown');
$pageUrl     = $_SERVER['HTTP_REFERER'] ?? 'direct';

// ── Guards ──
if (!empty($_POST['website'])) { echo '{"success":true}'; exit; }                 // honeypot
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); exit; }
// Abuse: only accept submissions whose Origin or Referer is one of our own domains.
if (!isset($siteMap[$originHost]) && !isset($siteMap[$refererHost])) {
    http_response_code(403);
    echo json_encode(['success' => false, 'error' => 'Forbidden.']);
    exit;
}

// ── Input ──
$name    = trim($_POST['name']    ?? '');
$phone   = preg_replace('/\D/', '', $_POST['phone'] ?? '');
$city    = trim($_POST['city']    ?? '');
$concern = trim($_POST['concern'] ?? '');

// Normalize Indian mobile (substr for PHP 7 safety)
if (strlen($phone) === 12 && substr($phone, 0, 2) === '91') $phone = substr($phone, 2);
if (strlen($phone) === 11 && substr($phone, 0, 1) === '0')  $phone = substr($phone, 1);

if (!$name || strlen($phone) !== 10 || !preg_match('/^[6-9]/', $phone)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Name and valid 10-digit mobile required.']);
    exit;
}

// ── Rate limiting (file-based, defence in depth) ──
function rate_ok($key, $maxHits, $windowSec) {
    $f = sys_get_temp_dir() . '/cionrl_' . sha1($key);
    $now = time(); $kept = [];
    if (is_file($f)) {
        foreach (explode(',', (string)@file_get_contents($f)) as $t) {
            $t = (int)$t; if ($t > $now - $windowSec) $kept[] = $t;
        }
    }
    if (count($kept) >= $maxHits) return false;
    $kept[] = $now;
    @file_put_contents($f, implode(',', $kept), LOCK_EX);
    return true;
}
$ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0';
$ip = trim(explode(',', $ip)[0]);
if (!rate_ok('ip:' . $ip, 30, 3600) || !rate_ok('ph:' . $phone, 4, 86400)) {
    http_response_code(429);
    echo json_encode(['success' => false, 'error' => 'Too many requests. Please call or WhatsApp +91 90634 90160.']);
    exit;
}

$phone = '+91' . $phone;   // E.164 to match HubSpot's existing format (dedupe)

// ── HubSpot helper ──
function hs(string $method, string $url, array $body): array {
    global $HS_TOKEN;
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_POSTFIELDS     => json_encode($body),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Authorization: Bearer ' . $HS_TOKEN],
        CURLOPT_CONNECTTIMEOUT => 3,
        CURLOPT_TIMEOUT        => 7,
    ]);
    $resp = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($resp, true) ?? []];
}

// ── Per-phone lock so concurrent submits don't both create the contact ──
$lockFp = @fopen(sys_get_temp_dir() . '/cionlock_' . sha1($phone), 'c');
if ($lockFp) flock($lockFp, LOCK_EX);

// 1. Find existing contact by phone
$search    = hs('POST', "$HS_BASE/contacts/search", [
    'filterGroups' => [['filters' => [['propertyName' => 'phone', 'operator' => 'EQ', 'value' => $phone]]]],
    'properties'   => ['phone'],
    'limit'        => 1,
]);
$contactId = $search['data']['results'][0]['id'] ?? null;

// 2. Create (with lead status) or update (without resetting lead status)
$base = array_filter(['firstname' => $name, 'phone' => $phone, 'city' => $city]);
if ($contactId) {
    hs('PATCH', "$HS_BASE/contacts/$contactId", ['properties' => $base]);
} else {
    $create    = hs('POST', "$HS_BASE/contacts", ['properties' => $base + ['hs_lead_status' => 'NEW']]);
    $contactId = $create['data']['id'] ?? null;
}

if ($lockFp) { flock($lockFp, LOCK_UN); fclose($lockFp); }

// 3. Attach note (check the result)
$noteOk = true;
if ($contactId) {
    $note = implode("\n", array_filter([
        "Source:  $source", "Page: $path", "URL: $pageUrl",
        $concern ? "Concern: $concern" : null,
        $city    ? "City: $city"       : null,
    ]));
    $noteRes = hs('POST', "$HS_BASE/notes", [
        'properties'   => ['hs_note_body' => $note, 'hs_timestamp' => date('c')],
        'associations' => [['to' => ['id' => $contactId], 'types' => [['associationCategory' => 'HUBSPOT_DEFINED', 'associationTypeId' => 202]]]],
    ]);
    $noteOk = ($noteRes['code'] >= 200 && $noteRes['code'] < 300);
}

// 4. Log (mask phone, no full number) and respond
$ok        = !empty($contactId);
$eventId   = uniqid($source . '-', true);
$maskPhone = '+91****' . substr($phone, -4);

@file_put_contents($LOG_FILE,
    implode(' | ', [date('Y-m-d H:i:s'), $eventId, $source, $path, $name, $maskPhone, ($ok ? 'ok' : 'fail') . ($ok && !$noteOk ? '/note-failed' : '')]) . PHP_EOL,
    FILE_APPEND | LOCK_EX
);

if (!$ok) {
    @file_put_contents($ERR_FILE,
        date('[Y-m-d H:i:s] ') . "HubSpot create failed | $source | $path | $maskPhone | code=" . ($create['code'] ?? '?') . PHP_EOL,
        FILE_APPEND | LOCK_EX);
    http_response_code(502);
    echo json_encode(['success' => false, 'error' => 'Could not save your details. Please call or WhatsApp +91 90634 90160.']);
    exit;
}
if (!$noteOk) {
    @file_put_contents($ERR_FILE,
        date('[Y-m-d H:i:s] ') . "Note failed (contact $contactId saved) | $source | $maskPhone | code=" . ($noteRes['code'] ?? '?') . PHP_EOL,
        FILE_APPEND | LOCK_EX);
}

echo json_encode(['success' => true, 'event_id' => $eventId]);
