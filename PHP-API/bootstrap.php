<?php
declare(strict_types=1);

$config = require __DIR__ . '/config.example.php';
if (empty($config['db_name']) || empty($config['db_user'])) {
    throw new RuntimeException('Database is not configured. Copy config.example.php to config.local.php and enter the cPanel database credentials.');
}
$dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $config['db_host'], $config['db_name']);
$pdo = new PDO($dsn, $config['db_user'], $config['db_pass'], [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
]);

function json_response(array $data, int $status = 200): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}
function fail(string $message, int $status = 400, string $code = 'bad_request'): never {
    json_response(['ok' => false, 'error' => $code, 'message' => $message], $status);
}
function input_json(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $data = json_decode($raw, true);
    if (!is_array($data)) fail('Request body must be a JSON object.', 400, 'invalid_json');
    return $data;
}
function clean_text(mixed $value, int $max = 280): string {
    if (!is_string($value)) return '';
    $value = trim($value);
    if (mb_strlen($value) > $max) fail("Text exceeds {$max} characters.", 422, 'validation_error');
    return $value;
}
function current_user(PDO $pdo, bool $required = true): ?array {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+([A-Za-z0-9._~-]{32,200})$/i', $header, $m)) {
        if ($required) fail('A valid Bearer token is required.', 401, 'unauthorized');
        return null;
    }
    $hash = hash('sha256', $m[1]);
    $q = $pdo->prepare('SELECT u.id,u.username,u.email,u.display_name,u.bio,u.avatar_media_id,u.website,u.created_at FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=? AND s.expires_at > UTC_TIMESTAMP() AND u.is_active=1 LIMIT 1');
    $q->execute([$hash]);
    $user = $q->fetch();
    if (!$user && $required) fail('Session expired or invalid. Please log in again.', 401, 'invalid_token');
    return $user ?: null;
}
function issue_session(PDO $pdo, int $userId, array $config): string {
    $token = bin2hex(random_bytes(32));
    $hash = hash('sha256', $token);
    $q = $pdo->prepare('INSERT INTO sessions (user_id,token_hash,expires_at,created_at) VALUES (?,?,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? DAY),UTC_TIMESTAMP())');
    $q->execute([$userId, $hash, (int)$config['token_ttl_days']]);
    return $token;
}
function user_public(array $u): array {
    return ['id'=>(int)$u['id'],'username'=>$u['username'],'display_name'=>$u['display_name'],'bio'=>$u['bio'] ?? '', 'avatar_media_id'=>isset($u['avatar_media_id'])?(int)$u['avatar_media_id']:null,'website'=>$u['website'] ?? null,'created_at'=>$u['created_at']];
}
function post_row(PDO $pdo, int $postId, ?int $viewerId): ?array {
    $sql = "SELECT p.id,p.user_id,p.body,p.media_id,p.reply_to_id,p.created_at,p.updated_at,u.username,u.display_name,u.avatar_media_id,
      (SELECT COUNT(*) FROM likes l WHERE l.post_id=p.id) likes_count,
      (SELECT COUNT(*) FROM reposts r WHERE r.post_id=p.id) reposts_count,
      (SELECT COUNT(*) FROM posts c WHERE c.reply_to_id=p.id AND c.is_deleted=0) replies_count,
      " . ($viewerId ? "EXISTS(SELECT 1 FROM likes vl WHERE vl.post_id=p.id AND vl.user_id=".(int)$viewerId.")" : "0") . " liked,
      " . ($viewerId ? "EXISTS(SELECT 1 FROM reposts vr WHERE vr.post_id=p.id AND vr.user_id=".(int)$viewerId.")" : "0") . " reposted
      FROM posts p JOIN users u ON u.id=p.user_id WHERE p.id=? AND p.is_deleted=0";
    $q=$pdo->prepare($sql); $q->execute([$postId]); $p=$q->fetch();
    if (!$p) return null;
    foreach (['id','user_id','media_id','reply_to_id','likes_count','reposts_count','replies_count'] as $k) $p[$k] = $p[$k] === null ? null : (int)$p[$k];
    $p['liked']=(bool)$p['liked']; $p['reposted']=(bool)$p['reposted'];
    return $p;
}
function rate_limit(PDO $pdo, string $bucket, int $limit = 120, int $seconds = 60): void {
    $key = hash('sha256', $bucket);
    $q=$pdo->prepare('INSERT INTO api_rate_limits (bucket_hash,window_started_at,request_count) VALUES (?,UTC_TIMESTAMP(),1) ON DUPLICATE KEY UPDATE request_count=IF(window_started_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL ? SECOND),1,request_count+1),window_started_at=IF(window_started_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL ? SECOND),UTC_TIMESTAMP(),window_started_at)');
    $q->execute([$key,$seconds,$seconds]);
    $q=$pdo->prepare('SELECT request_count,window_started_at FROM api_rate_limits WHERE bucket_hash=?');
    $q->execute([$key]); $r=$q->fetch();
    if ($r && (int)$r['request_count'] > $limit) {
        header('Retry-After: '.max(1,$seconds-(time()-strtotime($r['window_started_at'].' UTC'))));
        fail('Too many requests. Please try again shortly.',429,'rate_limited');
    }
}
function notify(PDO $pdo, int $recipient, int $actor, string $type, ?int $postId = null): void {
    if ($recipient === $actor) return;
    $q=$pdo->prepare('INSERT INTO notifications (user_id,actor_user_id,type,post_id,created_at) VALUES (?,?,?,?,UTC_TIMESTAMP())');
    $q->execute([$recipient,$actor,$type,$postId]);
}
