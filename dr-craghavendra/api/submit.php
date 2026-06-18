<?php
header('Content-Type: application/json; charset=utf-8');

$HS_TOKEN = 'REDACTED';
$HS_BASE  = 'https://api.hubapi.com/crm/v3/objects';
$LOG_FILE = __DIR__ . '/leads.log';
$ERR_FILE = __DIR__ . '/errors.log';

// ── Auto-detect site + page from browser referer ──
$referer  = $_SERVER['HTTP_REFERER'] ?? '';
$host     = parse_url($referer, PHP_URL_HOST) ?? 'unknown';
$path     = trim(parse_url($referer, PHP_URL_PATH) ?? '/', '/') ?: 'home';

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

$source  = $siteMap[$host] ?? $host;
$pageUrl = $referer ?: 'direct';

// ── Guards ──
if (!empty($_POST['website'])) { echo '{"success":true}'; exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); exit; }

// ── Input ──
$name    = trim($_POST['name']    ?? '');
$phone   = preg_replace('/\D/', '', $_POST['phone'] ?? '');
$city    = trim($_POST['city']    ?? '');
$concern = trim($_POST['concern'] ?? '');

// Normalize Indian mobile (substr instead of str_starts_with for PHP 7 safety)
if (strlen($phone) === 12 && substr($phone, 0, 2) === '91') $phone = substr($phone, 2);
if (strlen($phone) === 11 && substr($phone, 0, 1) === '0')  $phone = substr($phone, 1);

// Validate
if (!$name || strlen($phone) !== 10 || !preg_match('/^[6-9]/', $phone)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Name and valid 10-digit mobile required.']);
    exit;
}

// ── HubSpot helper ──
function hs(string $method, string $url, array $body): array {
    global $HS_TOKEN;
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_POSTFIELDS     => json_encode($body),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Authorization: Bearer ' . $HS_TOKEN],
        CURLOPT_TIMEOUT        => 8,
    ]);
    $resp = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($resp, true) ?? []];
}

// ── 1. Find existing contact by phone ──
$search    = hs('POST', "$HS_BASE/contacts/search", [
    'filterGroups' => [[
        'filters' => [['propertyName' => 'phone', 'operator' => 'EQ', 'value' => $phone]]
    ]],
    'properties' => ['phone'],
    'limit' => 1,
]);
$contactId = $search['data']['results'][0]['id'] ?? null;

// ── 2. Create or update contact ──
$props = array_filter([
    'firstname'      => $name,
    'phone'          => $phone,
    'city'           => $city,
    'hs_lead_status' => 'NEW',
]);

if ($contactId) {
    hs('PATCH', "$HS_BASE/contacts/$contactId", ['properties' => $props]);
} else {
    $create    = hs('POST', "$HS_BASE/contacts", ['properties' => $props]);
    $contactId = $create['data']['id'] ?? null;
}

// ── 3. Attach note with full context ──
if ($contactId) {
    $note = implode("\n", array_filter([
        "Source:  $source",
        "Page:    $path",
        "URL:     $pageUrl",
        $concern ? "Concern: $concern" : null,
        $city    ? "City:    $city"    : null,
    ]));
    hs('POST', "$HS_BASE/notes", [
        'properties'   => ['hs_note_body' => $note, 'hs_timestamp' => date('c')],
        'associations' => [[
            'to'    => ['id' => $contactId],
            'types' => [['associationCategory' => 'HUBSPOT_DEFINED', 'associationTypeId' => 202]],
        ]],
    ]);
}

// ── 4. Log and respond ──
$ok      = !empty($contactId);
$eventId = uniqid($source . '-', true);

@file_put_contents($LOG_FILE,
    implode(' | ', [date('Y-m-d H:i:s'), $eventId, $source, $path, $name, $phone, $city, $ok ? 'ok' : 'fail']) . PHP_EOL,
    FILE_APPEND | LOCK_EX
);

if (!$ok) {
    @file_put_contents($ERR_FILE,
        date('[Y-m-d H:i:s] ') . "HubSpot failed | $source | $path | phone=$phone" . PHP_EOL,
        FILE_APPEND | LOCK_EX
    );
    // Report the real failure so the form shows the error + WhatsApp fallback
    http_response_code(502);
    echo json_encode(['success' => false, 'error' => 'Could not save your details. Please call or WhatsApp +91 90634 90160.']);
    exit;
}

echo json_encode(['success' => true, 'event_id' => $eventId]);
