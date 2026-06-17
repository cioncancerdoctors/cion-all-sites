<?php
header('Content-Type: application/json; charset=utf-8');

// Token lives OUTSIDE public_html — never in git.
// Deploy once via hPanel File Manager: /home/u885652959/private/cion-config.php
$configPath = '/home/u885652959/private/cion-config.php';
if (!file_exists($configPath)) {
    http_response_code(500);
    error_log('[CION] Config file missing: ' . $configPath);
    echo json_encode(['success' => false, 'error' => 'Server configuration error.']);
    exit;
}
require_once $configPath;

$SOURCE    = 'IM-Web';
$LEADS_LOG = __DIR__ . '/leads.log';
$ERROR_LOG = __DIR__ . '/errors.log';

// Bot honeypot
if (!empty($_POST['website'])) { echo json_encode(['success' => true]); exit; }

// POST only
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); exit; }

// Read fields
$name    = trim($_POST['name']    ?? '');
$phone   = preg_replace('/\D/', '', $_POST['phone'] ?? '');
$city    = trim($_POST['city']    ?? '');
$concern = trim($_POST['concern'] ?? '');

// Normalize Indian phone
if (strlen($phone) === 12 && str_starts_with($phone, '91')) $phone = substr($phone, 2);
if (strlen($phone) === 11 && str_starts_with($phone, '0'))  $phone = substr($phone, 1);

// Validate
if (!$name || strlen($phone) !== 10 || !preg_match('/^[6-9]/', $phone)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Please enter your name and a valid 10-digit mobile number.']);
    exit;
}

// ── HubSpot: check if contact exists by phone ──
$ch = curl_init('https://api.hubapi.com/crm/v3/objects/contacts/search');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode([
        'filterGroups' => [[
            'filters' => [['propertyName' => 'phone', 'operator' => 'EQ', 'value' => $phone]]
        ]],
        'properties' => ['phone'],
        'limit'      => 1,
    ]),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Authorization: Bearer ' . CION_HS_TOKEN],
    CURLOPT_TIMEOUT    => 8,
]);
$searchResult = json_decode(curl_exec($ch), true);
curl_close($ch);

$existingId = $searchResult['results'][0]['id'] ?? null;

// Properties to send — only standard HubSpot fields
$props = array_filter([
    'firstname'      => $name,
    'phone'          => $phone,
    'city'           => $city,
    'hs_lead_status' => 'NEW',
]);

// ── Create or update contact ──
if ($existingId) {
    $ch = curl_init('https://api.hubapi.com/crm/v3/objects/contacts/' . $existingId);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => 'PATCH',
        CURLOPT_POSTFIELDS     => json_encode(['properties' => $props]),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Authorization: Bearer ' . CION_HS_TOKEN],
        CURLOPT_TIMEOUT        => 8,
    ]);
} else {
    $ch = curl_init('https://api.hubapi.com/crm/v3/objects/contacts');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode(['properties' => $props]),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Authorization: Bearer ' . CION_HS_TOKEN],
        CURLOPT_TIMEOUT        => 8,
    ]);
}
$hsResp = curl_exec($ch);
$hsCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$ok = $hsCode >= 200 && $hsCode < 300;

// ── Log every lead (always) ──
$eventId = uniqid($SOURCE . '-', true);
@file_put_contents(
    $LEADS_LOG,
    implode(' | ', [date('Y-m-d H:i:s'), $eventId, $SOURCE, $name, $phone, $city, $ok ? 'hs_ok' : 'hs_fail']) . PHP_EOL,
    FILE_APPEND | LOCK_EX
);

if (!$ok) {
    @file_put_contents(
        $ERROR_LOG,
        date('[Y-m-d H:i:s] ') . "HubSpot HTTP $hsCode: $hsResp" . PHP_EOL,
        FILE_APPEND | LOCK_EX
    );
}

echo json_encode(['success' => true, 'event_id' => $eventId]);
