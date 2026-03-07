<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$path = is_string($path) ? $path : '/';

$mysqlHost = getenv('MYSQL_HOST') ?: 'mysql';
$mysqlPort = (int) (getenv('MYSQL_PORT') ?: '3306');
$redisHost = getenv('REDIS_HOST') ?: 'redis';
$redisPort = (int) (getenv('REDIS_PORT') ?: '6379');

function respond(int $statusCode, array $payload): void
{
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_SLASHES);
}

function tcpCheck(string $host, int $port, float $timeoutSeconds = 1.2): array
{
    $errno = 0;
    $errstr = '';
    $connection = @fsockopen($host, $port, $errno, $errstr, $timeoutSeconds);

    if ($connection === false) {
        return [
            'ok' => false,
            'error' => $errstr !== '' ? $errstr : "errno:$errno",
        ];
    }

    fclose($connection);
    return ['ok' => true];
}

if ($path === '/health') {
    respond(200, [
        'service' => 'php-demo',
        'status' => 'ok',
        'timestamp' => gmdate(DATE_ATOM),
    ]);
    return;
}

if ($path === '/ready') {
    $checks = [
        'mysql' => tcpCheck($mysqlHost, $mysqlPort),
        'redis' => tcpCheck($redisHost, $redisPort),
    ];

    $ok = true;
    foreach ($checks as $check) {
        if (($check['ok'] ?? false) !== true) {
            $ok = false;
            break;
        }
    }

    respond($ok ? 200 : 503, [
        'service' => 'php-demo',
        'ok' => $ok,
        'checks' => $checks,
        'timestamp' => gmdate(DATE_ATOM),
    ]);
    return;
}

if ($path === '/') {
    respond(200, [
        'service' => 'php-demo',
        'message' => 'PHP demo service behind Apache reverse proxy.',
        'timestamp' => gmdate(DATE_ATOM),
    ]);
    return;
}

respond(404, [
    'service' => 'php-demo',
    'error' => 'not_found',
    'path' => $path,
]);
