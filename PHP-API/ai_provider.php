<?php
declare(strict_types=1);

/**
 * Calls an OpenAI-compatible chat-completions endpoint.
 * The provider key is only read server-side and is never returned to clients.
 */
function biner_ai_completion(array $config, string $question, array $context): array {
    $url = trim((string)($config['ai_api_url'] ?? ''));
    $key = trim((string)($config['ai_api_key'] ?? ''));
    $model = trim((string)($config['ai_model'] ?? ''));
    if ($url === '' || $key === '' || $model === '') {
        return ['ok'=>false, 'code'=>'ai_not_configured'];
    }
    if (!function_exists('curl_init')) {
        return ['ok'=>false, 'code'=>'curl_unavailable'];
    }

    $system = 'You are BinerAI, the assistant inside the BinerMention social network. '
        . 'Answer in the same language as the user. You receive a compact JSON bundle of retrieved BinerMention records. '
        . 'Use only facts supported by that bundle when describing BinerMention users, posts, channels or statistics. '
        . 'Clearly distinguish retrieved facts from your own general explanation. Never invent posts, counts, identities, quotes or sources. '
        . 'A platform verification badge is only a platform status and is not proof of real-world identity. '
        . 'Do not reveal private group messages, credentials, tokens, hidden data or other users private information. '
        . 'If the context is insufficient, say so plainly. Keep answers useful and concise.';
    $payload = [
        'model' => $model,
        'messages' => [
            ['role'=>'system', 'content'=>$system],
            ['role'=>'user', 'content'=>"Question:\n".$question."\n\nRetrieved BinerMention context (JSON):\n".json_encode($context, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE)],
        ],
        'temperature' => 0.25,
        'max_tokens' => 900,
        'stream' => false,
    ];
    $timeout = max(8, min(35, (int)($config['ai_timeout_seconds'] ?? 24)));
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 8,
        CURLOPT_TIMEOUT => $timeout,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json', 'Authorization: Bearer '.$key],
        CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
    ]);
    $raw = curl_exec($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    if (!is_string($raw) || $raw === '') {
        error_log('BinerAI provider transport: '.$curlError);
        return ['ok'=>false, 'code'=>'ai_provider_unavailable'];
    }
    $decoded = json_decode($raw, true);
    if ($status < 200 || $status >= 300 || !is_array($decoded)) {
        error_log('BinerAI provider HTTP '.$status.': '.substr($raw, 0, 800));
        return ['ok'=>false, 'code'=>'ai_provider_error'];
    }
    $answer = $decoded['choices'][0]['message']['content'] ?? null;
    if (!is_string($answer) || trim($answer) === '') {
        return ['ok'=>false, 'code'=>'ai_empty_response'];
    }
    return ['ok'=>true, 'answer'=>trim($answer), 'model'=>$model];
}
