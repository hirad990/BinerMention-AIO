<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

if ($method === 'GET' && ($path === '/' || str_ends_with(rtrim($path, '/'), '/index.php'))) {
    http_response_code(200);
    echo json_encode([
        'ok' => true,
        'service' => 'BinerMention API',
        'version' => '0.1.0',
        'status' => 'bootstrap',
        'message' => 'API is reachable; social endpoints are not configured yet.'
    ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

http_response_code(404);
echo json_encode([
    'ok' => false,
    'error' => 'not_found',
    'message' => 'This API endpoint has not been implemented.'
], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
