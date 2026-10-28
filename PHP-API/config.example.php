<?php
declare(strict_types=1);

/*
 * Copy config.example.php to config.local.php and enter cPanel database details.
 * config.local.php is excluded from git. Environment variables take precedence.
 */
$config = [
    'db_host' => getenv('BINERMENTION_DB_HOST') ?: 'localhost',
    'db_name' => getenv('BINERMENTION_DB_NAME') ?: '',
    'db_user' => getenv('BINERMENTION_DB_USER') ?: '',
    'db_pass' => getenv('BINERMENTION_DB_PASS') ?: '',
    'app_url' => 'https://binercraft.ir/mention-api-pub',
    'allowed_origins' => [], // Add the exact production web origin, e.g. https://binercraft.ir
    'upload_dir' => __DIR__ . '/uploads',
    'upload_url' => 'https://binercraft.ir/mention-api-pub/uploads',
    'max_upload_bytes' => 25 * 1024 * 1024,
    'token_ttl_days' => 30,
];

$local = __DIR__ . '/config.local.php';
if (is_file($local)) {
    $localConfig = require $local;
    if (is_array($localConfig)) {
        $config = array_replace($config, $localConfig);
    }
}
foreach (['db_host' => 'BINERMENTION_DB_HOST', 'db_name' => 'BINERMENTION_DB_NAME', 'db_user' => 'BINERMENTION_DB_USER', 'db_pass' => 'BINERMENTION_DB_PASS'] as $key => $env) {
    $value = getenv($env);
    if ($value !== false && $value !== '') $config[$key] = $value;
}
return $config;
