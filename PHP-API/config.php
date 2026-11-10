<?php
declare(strict_types=1);
$config = require __DIR__ . '/config.example.php';
$local = __DIR__ . '/config.local.php';
if (is_file($local)) {
    $override = require $local;
    if (is_array($override)) $config = array_replace($config, $override);
}
foreach ([
    'db_host'=>'BINERMENTION_DB_HOST',
    'db_name'=>'BINERMENTION_DB_NAME',
    'db_user'=>'BINERMENTION_DB_USER',
    'db_pass'=>'BINERMENTION_DB_PASS',
    'ai_api_url'=>'BINERMENTION_AI_API_URL',
    'ai_api_key'=>'BINERMENTION_AI_API_KEY',
    'ai_model'=>'BINERMENTION_AI_MODEL',
] as $key=>$env) {
    $v = getenv($env);
    if ($v !== false && $v !== '') $config[$key] = $v;
}
return $config;
