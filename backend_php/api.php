<?php
declare(strict_types=1);

// ==================================================
// Thoi Khoa Bieu API
// - Always returns JSON
// - Does not expose PHP source code
// - Handles CORS/OPTIONS for Flutter
// ==================================================

ini_set('display_errors', '0');
ini_set('html_errors', '0');
error_reporting(E_ALL);
date_default_timezone_set('Asia/Ho_Chi_Minh');

if (function_exists('header_remove')) {
    header_remove('X-Powered-By');
}

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-App-Key, X-App-Version');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/config.php';

set_error_handler(
    static function (int $severity, string $message, string $file, int $line): bool {
        throw new ErrorException($message, 0, $severity, $file, $line);
    }
);

set_exception_handler(
    static function (Throwable $error): void {
        error_log('[api.php] ' . $error->getMessage() . ' @ ' . $error->getFile() . ':' . $error->getLine());
        respond(false, [], 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.', 'server_error', 500);
    }
);

main();

function main(): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'GET') {
        $legacyAction = trim((string)($_GET['action'] ?? ''));
        $legacyShareId = trim((string)($_GET['shareId'] ?? $_GET['id'] ?? ''));
        $accept = mb_strtolower((string)($_SERVER['HTTP_ACCEPT'] ?? ''));
        $expectsHtml = str_contains($accept, 'text/html') || str_contains($accept, 'application/xhtml+xml');
        if (($legacyAction === 'share.get' || $expectsHtml) && $legacyShareId !== '') {
            header('Location: ' . buildPublicShareUrl($legacyShareId), true, 302);
            exit;
        }
        if ($expectsHtml) {
            header('Location: ' . rtrim((string)APP_BASE_URL, '/') . '/share', true, 302);
            exit;
        }
    }
    // Browser/Safari health check.
    // This returns JSON instead of downloading the PHP file, and does not expose source code.
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'GET') {
        ok([
            'status' => 'ok',
            'api' => 'thoikhoabieu',
            'version' => '1.0.0',
            'serverTime' => gmdate(DATE_ATOM),
            'baseUrl' => defined('APP_BASE_URL') ? APP_BASE_URL : '',
        ], 'API hoạt động.');
    }

    requireAppKey();
    $pdo = db();
    $request = parseRequest();
    $action = trim((string)($request['action'] ?? ''));
    $data = $request['data'] ?? [];
    if ($action === '') {
        fail('invalid_action', 'Thiếu action API.');
    }
    if (!is_array($data)) {
        $data = [];
    }

    $publicActions = [
        'system.ping',
        'auth.register',
        'auth.login',
        'auth.resetPassword',
        'share.get',
        'profileCard.get',
    ];
    $viewer = in_array($action, $publicActions, true) ? currentUser($pdo) : requireAuth($pdo);

    switch ($action) {
        case 'system.ping':
            ok([
                'status' => 'ok',
                'serverTime' => gmdate(DATE_ATOM),
                'baseUrl' => APP_BASE_URL,
            ]);
            return;

        case 'auth.register':
            handleAuthRegister($pdo, $data);
            return;
        case 'auth.login':
            handleAuthLogin($pdo, $data);
            return;
        case 'auth.logout':
            handleAuthLogout($pdo);
            return;
        case 'auth.me':
            ok(['user' => serializeUser(requireAuth($pdo))]);
            return;
        case 'auth.resetPassword':
            ok([], 'Nếu email tồn tại, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.');
            return;

        case 'profile.get':
            ok(['user' => serializeUser(requireAuth($pdo))]);
            return;
        case 'profile.update':
            handleProfileUpdate($pdo, requireAuth($pdo), $data);
            return;
        case 'profile.uploadAvatar':
            handleAvatarUpload($pdo, requireAuth($pdo));
            return;

        case 'schedule.list': {
            $user = requireAuth($pdo);
            ok(['schedules' => listSchedules($pdo, (int)$user['id'])]);
            return;
        }
        case 'schedule.today': {
            $user = requireAuth($pdo);
            ok(['schedules' => listSchedules($pdo, (int)$user['id'], (int)date('N'))]);
            return;
        }
        case 'schedule.week': {
            $user = requireAuth($pdo);
            ok(['schedules' => listSchedules($pdo, (int)$user['id'])]);
            return;
        }
        case 'schedule.create':
            handleScheduleCreate($pdo, requireAuth($pdo), $data);
            return;
        case 'schedule.update':
            handleScheduleUpdate($pdo, requireAuth($pdo), $data);
            return;
        case 'schedule.delete':
            handleScheduleDelete($pdo, requireAuth($pdo), $data);
            return;

        case 'task.list': {
            $user = requireAuth($pdo);
            ok(['tasks' => listTaskRows($pdo, (int)$user['id'])]);
            return;
        }
        case 'task.create':
            handleTaskUpsert($pdo, requireAuth($pdo), $data, false);
            return;
        case 'task.update':
            handleTaskUpsert($pdo, requireAuth($pdo), $data, true);
            return;
        case 'task.delete':
            handleTaskDelete($pdo, requireAuth($pdo), $data);
            return;

        case 'exam.list': {
            $user = requireAuth($pdo);
            ok(['exams' => listExamRows($pdo, (int)$user['id'])]);
            return;
        }
        case 'exam.create':
            handleExamUpsert($pdo, requireAuth($pdo), $data, false);
            return;
        case 'exam.update':
            handleExamUpsert($pdo, requireAuth($pdo), $data, true);
            return;
        case 'exam.delete':
            handleExamDelete($pdo, requireAuth($pdo), $data);
            return;

        case 'studyLog.list':
            handleStudyLogList($pdo, requireAuth($pdo), $data);
            return;
        case 'studyLog.create':
        case 'studyLog.update':
            handleStudyLogUpsert($pdo, requireAuth($pdo), $data);
            return;

        case 'settings.get': {
            $user = requireAuth($pdo);
            ok(['settings' => getSettingsSection($pdo, (int)$user['id'], 'app_settings_json')]);
            return;
        }
        case 'settings.update':
            handleSettingsUpdate($pdo, requireAuth($pdo), $data);
            return;
        case 'notification.settings':
            handleSettingsSection($pdo, requireAuth($pdo), $data, 'notification_settings_json', 'settings');
            return;
        case 'widget.settings':
            handleSettingsSection($pdo, requireAuth($pdo), $data, 'widget_settings_json', 'settings');
            return;
        case 'widget.sync':
            ok(['syncedAt' => gmdate(DATE_ATOM)], 'Đã đồng bộ widget.');
            return;
        case 'dynamicIsland.settings':
            handleSettingsSection($pdo, requireAuth($pdo), $data, 'dynamic_island_settings_json', 'settings');
            return;
        case 'dynamicIsland.sync':
            ok(['syncedAt' => gmdate(DATE_ATOM)], 'Đã đồng bộ Dynamic Island.');
            return;
        case 'notification.sync':
            ok(['syncedAt' => gmdate(DATE_ATOM)], 'Đã đồng bộ thông báo.');
            return;

        case 'stats.summary':
        case 'stats.week': {
            $user = requireAuth($pdo);
            $schedules = listSchedules($pdo, (int)$user['id']);
            $totalMinutes = 0;
            $subjectStats = [];
            $dailyMinutes = array_fill(1, 7, 0);
            foreach ($schedules as $schedule) {
                $minutes = max(0, (int)$schedule['endTime'] - (int)$schedule['startTime']);
                $totalMinutes += $minutes;
                $day = max(1, min(7, (int)$schedule['dayOfWeek']));
                $dailyMinutes[$day] += $minutes;
                $subject = (string)$schedule['subjectName'];
                if (!isset($subjectStats[$subject])) {
                    $subjectStats[$subject] = [
                        'subjectName' => $subject,
                        'minutes' => 0,
                        'classCount' => 0,
                    ];
                }
                $subjectStats[$subject]['minutes'] += $minutes;
                $subjectStats[$subject]['classCount']++;
            }
            ok([
                'totalHours' => round($totalMinutes / 60, 1),
                'totalMinutes' => $totalMinutes,
                'completedPercent' => 0,
                'todayClassCount' => count(listSchedules($pdo, (int)$user['id'], (int)date('N'))),
                'weekClassCount' => count($schedules),
                'subjectStats' => array_values($subjectStats),
                'dailyMinutes' => array_values($dailyMinutes),
            ]);
            return;
        }

        case 'share.create':
            handleShareCreate($pdo, requireAuth($pdo), $data);
            return;
        case 'share.get':
            handleShareGet($pdo, $data, $viewer);
            return;
        case 'share.update':
            handleShareUpdate($pdo, requireAuth($pdo), $data);
            return;
        case 'share.delete':
            handleShareDelete($pdo, requireAuth($pdo), $data);
            return;
        case 'share.import':
            handleShareImport($pdo, requireAuth($pdo), $data);
            return;
        case 'share.myLinks':
            handleMyShares($pdo, requireAuth($pdo));
            return;

        case 'friend.list':
            handleFriendList($pdo, requireAuth($pdo));
            return;
        case 'friend.requests':
            handleFriendRequests($pdo, requireAuth($pdo));
            return;
        case 'friend.search':
            handleFriendSearch($pdo, requireAuth($pdo), $data);
            return;
        case 'friend.request':
            handleFriendRequest($pdo, requireAuth($pdo), $data);
            return;
        case 'friend.accept':
            handleFriendAccept($pdo, requireAuth($pdo), $data);
            return;
        case 'friend.reject':
            handleFriendReject($pdo, requireAuth($pdo), $data);
            return;
        case 'friend.remove':
            handleFriendRemove($pdo, requireAuth($pdo), $data);
            return;

        case 'location.list':
            handleLocationList($pdo, requireAuth($pdo));
            return;
        case 'location.create':
        case 'location.update':
            handleLocationUpsert($pdo, requireAuth($pdo), $data);
            return;
        case 'location.delete':
            handleLocationDelete($pdo, requireAuth($pdo), $data);
            return;

        case 'profileCard.create':
            handleProfileCardCreate($pdo, requireAuth($pdo), $data);
            return;
        case 'profileCard.list':
            handleProfileCardList($pdo, requireAuth($pdo));
            return;
        case 'profileCard.get':
            handleProfileCardGet($pdo, $data);
            return;

        case 'backup.export':
            handleBackupExport($pdo, requireAuth($pdo));
            return;
        case 'backup.import':
            handleBackupImport($pdo, requireAuth($pdo), $data);
            return;
        default:
            fail('invalid_action', 'Action API không được hỗ trợ.', 404);
            return;
    }
}
function parseRequest(): array
{
    $contentType = strtolower((string)($_SERVER['CONTENT_TYPE'] ?? ''));
    if (str_contains($contentType, 'multipart/form-data')) {
        $data = [];
        if (isset($_POST['data'])) {
            $data = decodeJsonObject((string)$_POST['data']);
        }
        return ['action' => (string)($_POST['action'] ?? ''), 'data' => $data];
    }

    $raw = file_get_contents('php://input');
    if (!is_string($raw) || trim($raw) === '') {
        return ['action' => '', 'data' => []];
    }
    $payload = json_decode($raw, true);
    if (!is_array($payload)) {
        fail('invalid_json', 'Dữ liệu gửi lên không hợp lệ.');
    }
    return [
        'action' => (string)($payload['action'] ?? ''),
        'data' => is_array($payload['data'] ?? null) ? $payload['data'] : [],
    ];
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
    return $pdo;
}

function requireAppKey(): void
{
    $appKey = trim((string)($_SERVER['HTTP_X_APP_KEY'] ?? ''));

    if ($appKey === '' && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $appKey = trim((string)($headers['X-App-Key'] ?? $headers['x-app-key'] ?? ''));
    }

    if ($appKey === '' || !defined('APP_KEY') || !hash_equals(APP_KEY, $appKey)) {
        fail('forbidden', 'Ứng dụng không hợp lệ.', 403);
    }
}

function currentUser(PDO $pdo): ?array
{
    $token = bearerToken();
    if ($token === null) {
        return null;
    }
    $stmt = $pdo->prepare(
        'SELECT u.*, t.id AS token_row_id
         FROM auth_tokens t
         INNER JOIN users u ON u.id = t.user_id
         WHERE t.token_hash = :token_hash
           AND t.revoked_at IS NULL
           AND (t.expires_at IS NULL OR t.expires_at > NOW())
         LIMIT 1'
    );
    $stmt->execute(['token_hash' => hash('sha256', $token)]);
    $user = $stmt->fetch();
    if (!$user) {
        return null;
    }
    $pdo->prepare('UPDATE auth_tokens SET last_used_at = NOW() WHERE id = :id')
        ->execute(['id' => $user['token_row_id']]);
    unset($user['token_row_id']);
    return $user;
}

function requireAuth(PDO $pdo): array
{
    $user = currentUser($pdo);
    if (!$user) {
        fail('token_expired', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.', 401);
    }
    return $user;
}

function bearerToken(): ?string
{
    $header = trim((string)(
        $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? $_SERVER['Authorization']
        ?? ''
    ));

    if ($header === '' && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $header = trim((string)($headers['Authorization'] ?? $headers['authorization'] ?? ''));
    }

    if ($header === '' || !preg_match('/Bearer\s+(.+)/i', $header, $matches)) {
        return null;
    }
    $token = trim($matches[1]);
    return $token !== '' ? $token : null;
}

function issueToken(PDO $pdo, int $userId): string
{
    $token = rtrim(strtr(base64_encode(random_bytes(48)), '+/', '-_'), '=');
    $stmt = $pdo->prepare(
        'INSERT INTO auth_tokens (
            user_id, token_hash, created_at, expires_at, last_used_at, user_agent, ip_address
         ) VALUES (
            :user_id, :token_hash, NOW(), DATE_ADD(NOW(), INTERVAL 90 DAY), NOW(), :user_agent, :ip_address
         )'
    );
    $stmt->execute([
        'user_id' => $userId,
        'token_hash' => hash('sha256', $token),
        'user_agent' => substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255),
        'ip_address' => substr((string)($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45),
    ]);
    return $token;
}

function revokeCurrentToken(PDO $pdo): void
{
    $token = bearerToken();
    if ($token === null) {
        return;
    }
    $pdo->prepare('UPDATE auth_tokens SET revoked_at = NOW() WHERE token_hash = :token_hash')
        ->execute(['token_hash' => hash('sha256', $token)]);
}

function ok(array $data = [], string $message = 'OK'): void
{
    respond(true, $data, $message, 'ok', 200);
}

function fail(string $code, string $message, int $status = 400): void
{
    respond(false, [], $message, $code, $status);
}

function respond(bool $success, array $data, string $message, string $code, int $status): void
{
    http_response_code($status);
    echo json_encode([
        'success' => $success,
        'code' => $code,
        'message' => $message,
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requireString(array $data, string $key, int $minLength = 1, int $maxLength = 255): string
{
    $value = trim((string)($data[$key] ?? ''));
    $length = mb_strlen($value);
    if ($length < $minLength || $length > $maxLength) {
        fail('invalid_input', 'Dữ liệu gửi lên chưa hợp lệ.');
    }
    return $value;
}

function normalizeEmail(string $value): string
{
    $email = mb_strtolower(trim($value));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('invalid_input', 'Email không hợp lệ.');
    }
    return $email;
}

function normalizeUsername(string $value): string
{
    $normalized = mb_strtolower(trim($value));
    $normalized = preg_replace('/[^a-z0-9_]+/u', '', transliterate($normalized)) ?? '';
    return substr($normalized, 0, 32);
}

function transliterate(string $value): string
{
    $table = [
        'à' => 'a', 'á' => 'a', 'ạ' => 'a', 'ả' => 'a', 'ã' => 'a',
        'â' => 'a', 'ầ' => 'a', 'ấ' => 'a', 'ậ' => 'a', 'ẩ' => 'a', 'ẫ' => 'a',
        'ă' => 'a', 'ằ' => 'a', 'ắ' => 'a', 'ặ' => 'a', 'ẳ' => 'a', 'ẵ' => 'a',
        'è' => 'e', 'é' => 'e', 'ẹ' => 'e', 'ẻ' => 'e', 'ẽ' => 'e',
        'ê' => 'e', 'ề' => 'e', 'ế' => 'e', 'ệ' => 'e', 'ể' => 'e', 'ễ' => 'e',
        'ì' => 'i', 'í' => 'i', 'ị' => 'i', 'ỉ' => 'i', 'ĩ' => 'i',
        'ò' => 'o', 'ó' => 'o', 'ọ' => 'o', 'ỏ' => 'o', 'õ' => 'o',
        'ô' => 'o', 'ồ' => 'o', 'ố' => 'o', 'ộ' => 'o', 'ổ' => 'o', 'ỗ' => 'o',
        'ơ' => 'o', 'ờ' => 'o', 'ớ' => 'o', 'ợ' => 'o', 'ở' => 'o', 'ỡ' => 'o',
        'ù' => 'u', 'ú' => 'u', 'ụ' => 'u', 'ủ' => 'u', 'ũ' => 'u',
        'ư' => 'u', 'ừ' => 'u', 'ứ' => 'u', 'ự' => 'u', 'ử' => 'u', 'ữ' => 'u',
        'ỳ' => 'y', 'ý' => 'y', 'ỵ' => 'y', 'ỷ' => 'y', 'ỹ' => 'y',
        'đ' => 'd',
    ];
    return strtr($value, $table);
}

function uniqueUsername(PDO $pdo, string $name, string $email): string
{
    $base = normalizeUsername($name);
    if ($base === '') {
        $base = normalizeUsername((string)strtok($email, '@'));
    }
    if ($base === '') {
        $base = 'user';
    }

    $candidate = $base;
    $suffix = 1;
    while (true) {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE username = :username OR id_user = :username LIMIT 1');
        $stmt->execute(['username' => $candidate]);
        if (!$stmt->fetch()) {
            return $candidate;
        }
        $suffix++;
        $candidate = $base . $suffix;
    }
}

function readMinutes(mixed $value): int
{
    if (is_numeric($value)) {
        return (int)$value;
    }
    $string = trim((string)$value);
    if ($string === '') {
        return 0;
    }
    if (preg_match('/^(\d{1,2}):(\d{2})$/', $string, $matches)) {
        return ((int)$matches[1] * 60) + (int)$matches[2];
    }
    return (int)$string;
}

function readNullableFloat(mixed $value): ?float
{
    if ($value === null || $value === '') {
        return null;
    }
    return is_numeric($value) ? (float)$value : null;
}

function boolToInt(mixed $value): int
{
    if (is_bool($value)) {
        return $value ? 1 : 0;
    }
    if (is_numeric($value)) {
        return ((int)$value) === 1 ? 1 : 0;
    }
    $normalized = mb_strtolower(trim((string)$value));
    return in_array($normalized, ['1', 'true', 'yes', 'on'], true) ? 1 : 0;
}

function nullableString(mixed $value): ?string
{
    if ($value === null) {
        return null;
    }
    $string = trim((string)$value);
    return $string === '' ? null : $string;
}

function toSqlDateTime(mixed $value): ?string
{
    if ($value === null) {
        return null;
    }
    $string = trim((string)$value);
    if ($string === '') {
        return null;
    }
    $timestamp = strtotime($string);
    if ($timestamp === false) {
        return null;
    }
    return date('Y-m-d H:i:s', $timestamp);
}

function normalizeDate(string $value): string
{
    $timestamp = strtotime($value);
    if ($timestamp === false) {
        return date('Y-m-d');
    }
    return date('Y-m-d', $timestamp);
}

function decodeJsonObject(string $json): array
{
    $decoded = json_decode($json, true);
    return is_array($decoded) && !array_is_list($decoded) ? $decoded : [];
}

function decodeJsonList(string $json): array
{
    $decoded = json_decode($json, true);
    return is_array($decoded) ? array_values($decoded) : [];
}

function jsonEncode(mixed $value): string
{
    $json = json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    return is_string($json) ? $json : '{}';
}

function isoDateTime(?string $value): ?string
{
    if ($value === null || trim($value) === '') {
        return null;
    }
    $timestamp = strtotime($value);
    return $timestamp === false ? null : gmdate(DATE_ATOM, $timestamp);
}

function isoDate(?string $value): string
{
    if ($value === null || trim($value) === '') {
        return gmdate('Y-m-d\T00:00:00\Z');
    }
    $timestamp = strtotime($value);
    return $timestamp === false ? gmdate('Y-m-d\T00:00:00\Z') : gmdate('Y-m-d\T00:00:00\Z', $timestamp);
}

function defaultAppSettings(): array
{
    return [
        'themeMode' => 'system',
        'accentColor' => 0xFF6A8DFF,
        'liquidGlassEnabled' => true,
        'animationsEnabled' => true,
        'dynamicIslandEnabled' => false,
        'liveActivitiesEnabled' => false,
    ];
}

function defaultNotificationSettings(): array
{
    return [
        'enabled' => true,
        'nextClassReminderEnabled' => true,
        'reminderMinutesBefore' => 15,
        'homeworkReminderEnabled' => true,
        'examReminderEnabled' => true,
        'soundEnabled' => true,
        'defaultSound' => 'default',
        'permissionStatus' => 'unknown',
    ];
}

function ensureSettingsRow(PDO $pdo, int $userId): void
{
    $stmt = $pdo->prepare(
        'INSERT INTO settings (
            user_id, app_settings_json, notification_settings_json, widget_settings_json, dynamic_island_settings_json, updated_at
         ) VALUES (
            :user_id, :app_settings_json, :notification_settings_json, :widget_settings_json, :dynamic_island_settings_json, NOW()
         )
         ON DUPLICATE KEY UPDATE updated_at = NOW()'
    );
    $stmt->execute([
        'user_id' => $userId,
        'app_settings_json' => jsonEncode(defaultAppSettings()),
        'notification_settings_json' => jsonEncode(defaultNotificationSettings()),
        'widget_settings_json' => jsonEncode([]),
        'dynamic_island_settings_json' => jsonEncode([
            'dynamicIslandEnabled' => false,
            'liveActivitiesEnabled' => false,
        ]),
    ]);
}

function getSettingsSection(PDO $pdo, int $userId, string $column): array
{
    ensureSettingsRow($pdo, $userId);
    $stmt = $pdo->prepare("SELECT {$column} FROM settings WHERE user_id = :user_id LIMIT 1");
    $stmt->execute(['user_id' => $userId]);
    $row = $stmt->fetch();
    return decodeJsonObject((string)($row[$column] ?? '{}'));
}

function saveSettingsSection(PDO $pdo, int $userId, string $column, array $data): void
{
    ensureSettingsRow($pdo, $userId);
    $stmt = $pdo->prepare("UPDATE settings SET {$column} = :json_value, updated_at = NOW() WHERE user_id = :user_id");
    $stmt->execute([
        'json_value' => jsonEncode($data),
        'user_id' => $userId,
    ]);
}

function findUserById(PDO $pdo, int $id): array
{
    $stmt = $pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $id]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy người dùng.', 404);
    }
    return $row;
}

function findUserByUid(PDO $pdo, string $uid): array
{
    $stmt = $pdo->prepare('SELECT * FROM users WHERE uid = :uid LIMIT 1');
    $stmt->execute(['uid' => $uid]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy người dùng.', 404);
    }
    return $row;
}

function findUserByPublicIdentifier(PDO $pdo, string $identifier): array
{
    $value = trim($identifier);
    if ($value === '') {
        fail('invalid_input', 'Thiếu mã người dùng.', 400);
    }
    if (ctype_digit($value)) {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE id_profile = :id_profile LIMIT 1');
        $stmt->execute(['id_profile' => (int)$value]);
        $row = $stmt->fetch();
        if ($row) {
            return $row;
        }
    }
    $idUser = normalizeUsername($value);
    $stmt = $pdo->prepare(
        'SELECT *
         FROM users
         WHERE uid = :raw_value
            OR id_user = :id_user
            OR username = :id_user
         LIMIT 1'
    );
    $stmt->execute([
        'raw_value' => $value,
        'id_user' => $idUser,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy người dùng.', 404);
    }
    return $row;
}

function findScheduleRow(PDO $pdo, int $userId, string $scheduleId): array
{
    $stmt = $pdo->prepare(
        'SELECT * FROM schedules WHERE user_id = :user_id AND schedule_id = :schedule_id AND deleted_at IS NULL LIMIT 1'
    );
    $stmt->execute([
        'user_id' => $userId,
        'schedule_id' => $scheduleId,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy lịch học.', 404);
    }
    return $row;
}

function findTaskRow(PDO $pdo, int $userId, string $taskId): array
{
    $stmt = $pdo->prepare(
        'SELECT * FROM tasks WHERE user_id = :user_id AND task_id = :task_id AND deleted_at IS NULL LIMIT 1'
    );
    $stmt->execute([
        'user_id' => $userId,
        'task_id' => $taskId,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy công việc.', 404);
    }
    return $row;
}

function findExamRow(PDO $pdo, int $userId, string $examId): array
{
    $stmt = $pdo->prepare(
        'SELECT * FROM exams WHERE user_id = :user_id AND exam_id = :exam_id AND deleted_at IS NULL LIMIT 1'
    );
    $stmt->execute([
        'user_id' => $userId,
        'exam_id' => $examId,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy lịch thi.', 404);
    }
    return $row;
}

function findStudyLogRow(PDO $pdo, int $userId, string $logId): array
{
    $stmt = $pdo->prepare('SELECT * FROM study_logs WHERE user_id = :user_id AND log_id = :log_id LIMIT 1');
    $stmt->execute([
        'user_id' => $userId,
        'log_id' => $logId,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy nhật ký học.', 404);
    }
    return $row;
}

function findShareRow(PDO $pdo, string $shareId): array
{
    $stmt = $pdo->prepare('SELECT * FROM public_shares WHERE share_id = :share_id LIMIT 1');
    $stmt->execute(['share_id' => $shareId]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy link chia sẻ.', 404);
    }
    return $row;
}

function findLocationRow(PDO $pdo, int $userId, string $locationId): array
{
    $stmt = $pdo->prepare(
        'SELECT * FROM classroom_locations
         WHERE user_id = :user_id AND location_id = :location_id AND deleted_at IS NULL
         LIMIT 1'
    );
    $stmt->execute([
        'user_id' => $userId,
        'location_id' => $locationId,
    ]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy vị trí lớp học.', 404);
    }
    return $row;
}

function findProfileCardRow(PDO $pdo, string $cardId): array
{
    $stmt = $pdo->prepare('SELECT * FROM profile_cards WHERE card_id = :card_id AND deleted_at IS NULL LIMIT 1');
    $stmt->execute(['card_id' => $cardId]);
    $row = $stmt->fetch();
    if (!$row) {
        fail('not_found', 'Không tìm thấy profile card.', 404);
    }
    return $row;
}

function serializeUser(array $row): array
{
    $socialLinks = decodeJsonObject((string)($row['social_links_json'] ?? '{}'));
    $idUser = trim((string)($row['id_user'] ?? '')) ?: (string)$row['username'];
    $idProfile = (int)($row['id_profile'] ?? 0);
    if ($idProfile <= 0) {
        $idProfile = (int)$row['id'];
    }
    return [
        'id' => (string)$row['uid'],
        'uid' => (string)$row['uid'],
        'idUser' => $idUser,
        'id_user' => $idUser,
        'idProfile' => $idProfile,
        'id_profile' => $idProfile,
        'name' => (string)$row['name'],
        'displayName' => (string)$row['name'],
        'email' => (string)$row['email'],
        'username' => $idUser,
        'bio' => (string)$row['bio'],
        'avatarUrl' => nullableString($row['avatar_url']),
        'photoURL' => nullableString($row['avatar_url']),
        'themeMode' => (string)$row['theme_mode'],
        'profileTheme' => (string)$row['profile_theme'],
        'favoriteSubject' => (string)$row['favorite_subject'],
        'accentColor' => (int)$row['accent_color'],
        'studyStreak' => (int)$row['study_streak'],
        'isProfilePublic' => (int)$row['is_profile_public'] === 1,
        'allowFriendsToViewTimetable' => (int)$row['allow_friends_to_view_timetable'] === 1,
        'hideStatistics' => (int)$row['hide_statistics'] === 1,
        'hideStreak' => (int)$row['hide_streak'] === 1,
        'socialLinks' => $socialLinks === [] ? new stdClass() : $socialLinks,
        'createdAt' => isoDateTime($row['created_at']),
        'updatedAt' => isoDateTime($row['updated_at']),
        'lastSyncedAt' => isoDateTime($row['updated_at']),
    ];
}

function serializeSchedule(array $row): array
{
    return [
        'id' => (string)$row['schedule_id'],
        'scheduleId' => (string)$row['schedule_id'],
        'subjectName' => (string)$row['subject_name'],
        'dayOfWeek' => (int)$row['day_of_week'],
        'startTime' => (int)$row['start_time'],
        'endTime' => (int)$row['end_time'],
        'room' => (string)$row['room'],
        'teacher' => (string)$row['teacher'],
        'note' => (string)$row['note'],
        'color' => (int)$row['color'],
        'locationAddress' => (string)$row['location_address'],
        'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
        'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
        'appleMapsUrl' => nullableString($row['apple_maps_url']),
        'googleMapsUrl' => nullableString($row['google_maps_url']),
        'repeatWeekly' => (int)$row['repeat_weekly'] === 1,
        'reminderEnabled' => (int)$row['reminder_enabled'] === 1,
        'reminderMinutesBefore' => (int)$row['reminder_minutes_before'],
        'createdAt' => isoDateTime($row['created_at']),
        'updatedAt' => isoDateTime($row['updated_at']),
    ];
}

function serializeStudyLog(array $row): array
{
    return [
        'id' => (string)$row['log_id'],
        'scheduleId' => (string)$row['schedule_id'],
        'subjectName' => (string)$row['subject_name'],
        'date' => isoDate($row['date']),
        'status' => (string)$row['status'],
        'noteAfterClass' => (string)$row['note_after_class'],
        'completedAt' => isoDateTime($row['completed_at']),
    ];
}

function buildPublicShareUrl(string $shareId): string
{
    return rtrim((string)APP_BASE_URL, '/') . '/share/' . rawurlencode($shareId);
}

function buildAppShareUrl(string $shareId): string
{
    return 'thoikhoabieu://share/' . rawurlencode($shareId);
}

function isShareExpired(array $row): bool
{
    if (empty($row['expires_at'])) {
        return false;
    }
    $expiresAt = strtotime((string)$row['expires_at']);
    return $expiresAt !== false && $expiresAt <= time();
}

function serializeShare(array $row): array
{
    $shareId = (string)$row['share_id'];
    $owner = findUserById(db(), (int)$row['owner_id']);
    $ownerIdUser = trim((string)($owner['id_user'] ?? '')) ?: (string)$owner['username'];
    return [
        'id' => $shareId,
        'ownerId' => (string)$row['owner_uid'],
        'ownerIdUser' => $ownerIdUser,
        'ownerIdProfile' => (int)($owner['id_profile'] ?? $owner['id']),
        'ownerName' => (string)$row['owner_name'],
        'title' => (string)$row['title'],
        'shareType' => (string)$row['share_type'],
        'schedules' => decodeJsonList((string)$row['schedules_json']),
        'subjects' => decodeJsonList((string)$row['subjects_json']),
        'deepLink' => buildAppShareUrl($shareId),
        'qrData' => buildPublicShareUrl($shareId),
        'publicUrl' => buildPublicShareUrl($shareId),
        'isActive' => (int)$row['is_active'] === 1,
        'theme' => (string)$row['theme'],
        'viewCount' => (int)$row['view_count'],
        'profilePhoto' => nullableString($row['profile_photo']),
        'createdAt' => isoDateTime($row['created_at']),
        'updatedAt' => isoDateTime($row['updated_at']),
        'expiresAt' => isoDateTime($row['expires_at']),
        'deletedAt' => isoDateTime($row['deleted_at']),
    ];
}

function serializeLocation(array $row): array
{
    return [
        'id' => (string)$row['location_id'],
        'userId' => findUserById(db(), (int)$row['user_id'])['uid'],
        'scheduleId' => (string)$row['schedule_id'],
        'roomName' => (string)$row['room_name'],
        'address' => (string)$row['address'],
        'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
        'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
        'appleMapsUrl' => nullableString($row['apple_maps_url']),
        'googleMapsUrl' => nullableString($row['google_maps_url']),
        'createdAt' => isoDateTime($row['created_at']),
        'updatedAt' => isoDateTime($row['updated_at']),
    ];
}

function serializeProfileCard(array $row): array
{
    $payload = decodeJsonObject((string)$row['payload_json']);
    $payload['id'] = $payload['id'] ?? (string)$row['card_id'];
    $payload['ownerId'] = $payload['ownerId'] ?? (string)$row['owner_uid'];
    $payload['createdAt'] = $payload['createdAt'] ?? isoDateTime($row['created_at']);
    $payload['updatedAt'] = $payload['updatedAt'] ?? isoDateTime($row['updated_at']);
    return $payload;
}

function listSchedules(PDO $pdo, int $userId, ?int $dayOfWeek = null): array
{
    $sql = 'SELECT * FROM schedules WHERE user_id = :user_id AND deleted_at IS NULL';
    $params = ['user_id' => $userId];
    if ($dayOfWeek !== null) {
        $sql .= ' AND day_of_week = :day_of_week';
        $params['day_of_week'] = $dayOfWeek;
    }
    $sql .= ' ORDER BY day_of_week ASC, start_time ASC, created_at DESC';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return array_map('serializeSchedule', $stmt->fetchAll());
}

function listTaskRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM tasks WHERE user_id = :user_id AND deleted_at IS NULL ORDER BY created_at DESC');
    $stmt->execute(['user_id' => $userId]);
    return array_map(
        static function (array $row): array {
            $payload = decodeJsonObject((string)$row['payload_json']);
            $payload['id'] = $payload['id'] ?? (string)$row['task_id'];
            $payload['taskId'] = (string)$row['task_id'];
            $payload['title'] = $payload['title'] ?? (string)$row['title'];
            $payload['description'] = $payload['description'] ?? (string)$row['description'];
            $payload['status'] = $payload['status'] ?? (string)$row['status'];
            $payload['priority'] = $payload['priority'] ?? (string)$row['priority'];
            $payload['dueAt'] = $payload['dueAt'] ?? isoDateTime($row['due_at']);
            $payload['createdAt'] = $payload['createdAt'] ?? isoDateTime($row['created_at']);
            $payload['updatedAt'] = $payload['updatedAt'] ?? isoDateTime($row['updated_at']);
            return $payload;
        },
        $stmt->fetchAll()
    );
}

function listExamRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM exams WHERE user_id = :user_id AND deleted_at IS NULL ORDER BY exam_at ASC, created_at DESC');
    $stmt->execute(['user_id' => $userId]);
    return array_map(
        static function (array $row): array {
            $payload = decodeJsonObject((string)$row['payload_json']);
            $payload['id'] = $payload['id'] ?? (string)$row['exam_id'];
            $payload['examId'] = (string)$row['exam_id'];
            $payload['subjectName'] = $payload['subjectName'] ?? (string)$row['subject_name'];
            $payload['examAt'] = $payload['examAt'] ?? isoDateTime($row['exam_at']);
            $payload['location'] = $payload['location'] ?? (string)$row['location'];
            $payload['note'] = $payload['note'] ?? (string)$row['note'];
            $payload['status'] = $payload['status'] ?? (string)$row['status'];
            $payload['createdAt'] = $payload['createdAt'] ?? isoDateTime($row['created_at']);
            $payload['updatedAt'] = $payload['updatedAt'] ?? isoDateTime($row['updated_at']);
            return $payload;
        },
        $stmt->fetchAll()
    );
}

function listStudyLogRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM study_logs WHERE user_id = :user_id ORDER BY date DESC, updated_at DESC');
    $stmt->execute(['user_id' => $userId]);
    return array_map('serializeStudyLog', $stmt->fetchAll());
}

function listMyShareRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM public_shares WHERE owner_id = :owner_id ORDER BY created_at DESC');
    $stmt->execute(['owner_id' => $userId]);
    return array_map('serializeShare', $stmt->fetchAll());
}

function listLocationRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM classroom_locations WHERE user_id = :user_id AND deleted_at IS NULL ORDER BY created_at DESC');
    $stmt->execute(['user_id' => $userId]);
    return array_map('serializeLocation', $stmt->fetchAll());
}

function listProfileCardRows(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare('SELECT * FROM profile_cards WHERE owner_id = :owner_id AND deleted_at IS NULL ORDER BY created_at DESC');
    $stmt->execute(['owner_id' => $userId]);
    return array_map('serializeProfileCard', $stmt->fetchAll());
}

function normalizeSchedulePayload(array $data, string $scheduleId): array
{
    $subjectName = trim((string)($data['subjectName'] ?? $data['subject_name'] ?? ''));
    if ($subjectName === '') {
        fail('invalid_input', 'Tên môn học không được để trống.');
    }
    $dayOfWeek = (int)($data['dayOfWeek'] ?? $data['day_of_week'] ?? 1);
    $startTime = readMinutes($data['startTime'] ?? $data['start_time'] ?? 0);
    $endTime = readMinutes($data['endTime'] ?? $data['end_time'] ?? 0);
    if ($endTime <= $startTime) {
        fail('invalid_input', 'Giờ kết thúc phải sau giờ bắt đầu.');
    }

    return [
        'schedule_id' => $scheduleId,
        'subject_name' => $subjectName,
        'day_of_week' => max(1, min(7, $dayOfWeek)),
        'start_time' => $startTime,
        'end_time' => $endTime,
        'room' => trim((string)($data['room'] ?? '')),
        'teacher' => trim((string)($data['teacher'] ?? '')),
        'note' => trim((string)($data['note'] ?? '')),
        'color' => (int)($data['color'] ?? 0xFF6A8DFF),
        'location_address' => trim((string)($data['locationAddress'] ?? $data['location_address'] ?? '')),
        'latitude' => readNullableFloat($data['latitude'] ?? null),
        'longitude' => readNullableFloat($data['longitude'] ?? null),
        'apple_maps_url' => nullableString($data['appleMapsUrl'] ?? $data['apple_maps_url'] ?? null),
        'google_maps_url' => nullableString($data['googleMapsUrl'] ?? $data['google_maps_url'] ?? null),
        'repeat_weekly' => boolToInt($data['repeatWeekly'] ?? $data['repeat_weekly'] ?? true),
        'reminder_enabled' => boolToInt($data['reminderEnabled'] ?? $data['reminder_enabled'] ?? true),
        'reminder_minutes_before' => (int)($data['reminderMinutesBefore'] ?? $data['reminder_minutes_before'] ?? 10),
        'status' => trim((string)($data['status'] ?? 'active')) ?: 'active',
    ];
}

function handleAuthRegister(PDO $pdo, array $data): void
{
    $name = requireString($data, 'name', 2, 120);
    $email = normalizeEmail(requireString($data, 'email', 5, 191));
    $password = requireString($data, 'password', 6, 255);
    $exists = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
    $exists->execute(['email' => $email]);
    if ($exists->fetch()) {
        fail('email_taken', 'Email đã được sử dụng.');
    }

    $uid = 'u_' . bin2hex(random_bytes(8));
    $requestedIdUser = normalizeUsername((string)($data['idUser'] ?? $data['id_user'] ?? $data['username'] ?? ''));
    if ($requestedIdUser !== '') {
        $idExists = $pdo->prepare('SELECT id FROM users WHERE username = :id_user OR id_user = :id_user LIMIT 1');
        $idExists->execute(['id_user' => $requestedIdUser]);
        if ($idExists->fetch()) {
            fail('already_exists', 'ID người dùng này đã được sử dụng.');
        }
        $username = $requestedIdUser;
    } else {
        $username = uniqueUsername($pdo, $name, $email);
    }
    $stmt = $pdo->prepare(
        'INSERT INTO users (
            uid, email, password_hash, name, id_user, id_profile, username, bio, avatar_url,
            theme_mode, profile_theme, favorite_subject, accent_color, study_streak,
            is_profile_public, allow_friends_to_view_timetable, hide_statistics, hide_streak,
            social_links_json, created_at, updated_at
         ) VALUES (
            :uid, :email, :password_hash, :name, :id_user, NULL, :username, :bio, :avatar_url,
            :theme_mode, :profile_theme, :favorite_subject, :accent_color, :study_streak,
            :is_profile_public, :allow_friends_to_view_timetable, :hide_statistics, :hide_streak,
            :social_links_json, NOW(), NOW()
         )'
    );
    $defaults = defaultAppSettings();
    $stmt->execute([
        'uid' => $uid,
        'email' => $email,
        'password_hash' => password_hash($password, PASSWORD_DEFAULT),
        'name' => $name,
        'id_user' => $username,
        'username' => $username,
        'bio' => '',
        'avatar_url' => null,
        'theme_mode' => $defaults['themeMode'],
        'profile_theme' => 'aurora',
        'favorite_subject' => '',
        'accent_color' => $defaults['accentColor'],
        'study_streak' => 0,
        'is_profile_public' => 1,
        'allow_friends_to_view_timetable' => 1,
        'hide_statistics' => 0,
        'hide_streak' => 0,
        'social_links_json' => jsonEncode(new stdClass()),
    ]);

    $userId = (int)$pdo->lastInsertId();
    $pdo->prepare('UPDATE users SET id_profile = :id_profile WHERE id = :id AND id_profile IS NULL')
        ->execute(['id_profile' => $userId, 'id' => $userId]);
    ensureSettingsRow($pdo, $userId);
    saveSettingsSection($pdo, $userId, 'app_settings_json', defaultAppSettings());
    saveSettingsSection($pdo, $userId, 'notification_settings_json', defaultNotificationSettings());
    $user = findUserById($pdo, $userId);
    $token = issueToken($pdo, $userId);
    ok(['token' => $token, 'user' => serializeUser($user)], 'Đăng ký thành công.');
}

function handleAuthLogin(PDO $pdo, array $data): void
{
    $login = requireString($data, 'email', 1, 191);
    $password = requireString($data, 'password', 1, 255);
    if (str_contains($login, '@')) {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email LIMIT 1');
        $stmt->execute(['email' => normalizeEmail($login)]);
    } elseif (ctype_digit(trim($login))) {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE id_profile = :id_profile LIMIT 1');
        $stmt->execute(['id_profile' => (int)trim($login)]);
    } else {
        $idUser = normalizeUsername($login);
        $stmt = $pdo->prepare('SELECT * FROM users WHERE id_user = :id_user OR username = :id_user LIMIT 1');
        $stmt->execute(['id_user' => $idUser]);
    }
    $user = $stmt->fetch();
    if (!$user || !password_verify($password, (string)$user['password_hash'])) {
        fail('invalid_credentials', 'Email hoặc mật khẩu không đúng.', 401);
    }
    $token = issueToken($pdo, (int)$user['id']);
    ok(['token' => $token, 'user' => serializeUser($user)], 'Đăng nhập thành công.');
}

function handleAuthLogout(PDO $pdo): void
{
    revokeCurrentToken($pdo);
    ok([], 'Đăng xuất thành công.');
}

function handleProfileUpdate(PDO $pdo, array $user, array $data): void
{
    if (array_key_exists('idUser', $data) || array_key_exists('id_user', $data)) {
        $data['username'] = $data['idUser'] ?? $data['id_user'];
    }
    $allowed = [
        'name' => 'name',
        'username' => 'username',
        'bio' => 'bio',
        'avatarUrl' => 'avatar_url',
        'themeMode' => 'theme_mode',
        'profileTheme' => 'profile_theme',
        'favoriteSubject' => 'favorite_subject',
        'accentColor' => 'accent_color',
        'studyStreak' => 'study_streak',
        'isProfilePublic' => 'is_profile_public',
        'allowFriendsToViewTimetable' => 'allow_friends_to_view_timetable',
        'hideStatistics' => 'hide_statistics',
        'hideStreak' => 'hide_streak',
    ];
    $sets = [];
    $params = ['id' => $user['id']];
    foreach ($allowed as $inputKey => $column) {
        if (!array_key_exists($inputKey, $data)) {
            continue;
        }
        $value = $data[$inputKey];
        if ($inputKey === 'username') {
            $value = normalizeUsername((string)$value);
            if ($value === '') {
                fail('invalid_input', 'ID người dùng không hợp lệ.');
            }
            $exists = $pdo->prepare(
                'SELECT id
                 FROM users
                 WHERE (username = :value OR id_user = :value)
                   AND id <> :id
                 LIMIT 1'
            );
            $exists->execute(['value' => $value, 'id' => $user['id']]);
            if ($exists->fetch()) {
                fail('already_exists', 'ID người dùng này đã được sử dụng.');
            }
            $sets[] = 'id_user = :idUserMirror';
            $params['idUserMirror'] = $value;
        } elseif (in_array($inputKey, ['isProfilePublic', 'allowFriendsToViewTimetable', 'hideStatistics', 'hideStreak'], true)) {
            $value = boolToInt($value);
        } elseif (in_array($inputKey, ['accentColor', 'studyStreak'], true)) {
            $value = (int)$value;
        } else {
            $value = trim((string)$value);
        }
        $sets[] = $column . ' = :' . $inputKey;
        $params[$inputKey] = $value;
    }
    if (!$sets) {
        ok(['user' => serializeUser($user)], 'Không có thay đổi.');
    }
    $sql = 'UPDATE users SET ' . implode(', ', $sets) . ', updated_at = NOW() WHERE id = :id';
    $pdo->prepare($sql)->execute($params);
    if (array_key_exists('themeMode', $data) || array_key_exists('accentColor', $data)) {
        $current = getSettingsSection($pdo, (int)$user['id'], 'app_settings_json');
        $merged = array_merge($current, array_intersect_key($data, array_flip([
            'themeMode',
            'accentColor',
            'dynamicIslandEnabled',
            'liveActivitiesEnabled',
            'animationsEnabled',
            'liquidGlassEnabled',
        ])));
        saveSettingsSection($pdo, (int)$user['id'], 'app_settings_json', $merged);
    }
    ok(['user' => serializeUser(findUserById($pdo, (int)$user['id']))], 'Đã cập nhật hồ sơ.');
}

function handleAvatarUpload(PDO $pdo, array $user): void
{
    if (!isset($_FILES['avatar']) || !is_array($_FILES['avatar'])) {
        fail('upload_missing', 'Chưa có ảnh để tải lên.');
    }
    $file = $_FILES['avatar'];
    if ((int)($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        fail('upload_failed', 'Tải ảnh đại diện thất bại.');
    }
    $tmpPath = (string)$file['tmp_name'];
    $imageInfo = @getimagesize($tmpPath);
    if (!$imageInfo) {
        fail('invalid_image', 'Ảnh đại diện không hợp lệ.');
    }
    $mime = strtolower((string)($imageInfo['mime'] ?? ''));
    $allowed = ['image/jpeg' => '.jpg', 'image/png' => '.png', 'image/webp' => '.webp'];
    if (!isset($allowed[$mime])) {
        fail('invalid_image', 'Chỉ hỗ trợ ảnh JPG, PNG hoặc WebP.');
    }
    $uploadDir = __DIR__ . '/uploads/avatars';
    if (!is_dir($uploadDir) && !mkdir($uploadDir, 0775, true) && !is_dir($uploadDir)) {
        fail('upload_unavailable', 'Chưa cấu hình lưu ảnh đại diện.', 503);
    }
    $filename = $user['uid'] . $allowed[$mime];
    if (!move_uploaded_file($tmpPath, $uploadDir . '/' . $filename)) {
        fail('upload_failed', 'Tải ảnh đại diện thất bại.');
    }
    $avatarUrl = rtrim(APP_BASE_URL, '/') . '/uploads/avatars/' . rawurlencode($filename) . '?v=' . time();
    $pdo->prepare('UPDATE users SET avatar_url = :avatar_url, updated_at = NOW() WHERE id = :id')
        ->execute(['avatar_url' => $avatarUrl, 'id' => $user['id']]);
    ok([
        'avatarUrl' => $avatarUrl,
        'user' => serializeUser(findUserById($pdo, (int)$user['id'])),
    ], 'Đã cập nhật ảnh đại diện.');
}

function handleSettingsUpdate(PDO $pdo, array $user, array $data): void
{
    $current = getSettingsSection($pdo, (int)$user['id'], 'app_settings_json');
    $merged = array_merge($current, $data);
    saveSettingsSection($pdo, (int)$user['id'], 'app_settings_json', $merged);
    $fields = [];
    $params = ['id' => $user['id']];
    if (array_key_exists('themeMode', $merged)) {
        $fields[] = 'theme_mode = :theme_mode';
        $params['theme_mode'] = (string)$merged['themeMode'];
    }
    if (array_key_exists('accentColor', $merged)) {
        $fields[] = 'accent_color = :accent_color';
        $params['accent_color'] = (int)$merged['accentColor'];
    }
    if ($fields) {
        $sql = 'UPDATE users SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = :id';
        $pdo->prepare($sql)->execute($params);
    }
    ok(['settings' => getSettingsSection($pdo, (int)$user['id'], 'app_settings_json')], 'Đã lưu cài đặt.');
}

function handleSettingsSection(PDO $pdo, array $user, array $data, string $column, string $responseKey): void
{
    $userId = (int)$user['id'];
    if (!$data) {
        ok([$responseKey => getSettingsSection($pdo, $userId, $column)]);
    }
    $current = getSettingsSection($pdo, $userId, $column);
    $merged = array_merge($current, $data);
    saveSettingsSection($pdo, $userId, $column, $merged);
    ok([$responseKey => getSettingsSection($pdo, $userId, $column)], 'Đã lưu cài đặt.');
}

function handleScheduleCreate(PDO $pdo, array $user, array $data): void
{
    $scheduleId = trim((string)($data['id'] ?? $data['scheduleId'] ?? $data['schedule_id'] ?? '')) ?: 'sch_' . bin2hex(random_bytes(8));
    $payload = normalizeSchedulePayload($data, $scheduleId);
    $stmt = $pdo->prepare(
        'INSERT INTO schedules (
            schedule_id, user_id, subject_name, day_of_week, start_time, end_time, room,
            teacher, note, color, location_address, latitude, longitude, apple_maps_url,
            google_maps_url, repeat_weekly, reminder_enabled, reminder_minutes_before,
            status, created_at, updated_at
         ) VALUES (
            :schedule_id, :user_id, :subject_name, :day_of_week, :start_time, :end_time, :room,
            :teacher, :note, :color, :location_address, :latitude, :longitude, :apple_maps_url,
            :google_maps_url, :repeat_weekly, :reminder_enabled, :reminder_minutes_before,
            :status, NOW(), NOW()
         )'
    );
    $stmt->execute($payload + ['user_id' => $user['id']]);
    ok([
        'id' => $scheduleId,
        'scheduleId' => $scheduleId,
        'schedule' => serializeSchedule(findScheduleRow($pdo, (int)$user['id'], $scheduleId)),
    ], 'Đã thêm môn học.');
}

function handleScheduleUpdate(PDO $pdo, array $user, array $data): void
{
    $scheduleId = trim((string)($data['id'] ?? $data['scheduleId'] ?? $data['schedule_id'] ?? ''));
    if ($scheduleId === '') {
        fail('invalid_input', 'Thiếu mã lịch học.');
    }
    findScheduleRow($pdo, (int)$user['id'], $scheduleId);
    $payload = normalizeSchedulePayload($data, $scheduleId);
    $stmt = $pdo->prepare(
        'UPDATE schedules SET
            subject_name = :subject_name,
            day_of_week = :day_of_week,
            start_time = :start_time,
            end_time = :end_time,
            room = :room,
            teacher = :teacher,
            note = :note,
            color = :color,
            location_address = :location_address,
            latitude = :latitude,
            longitude = :longitude,
            apple_maps_url = :apple_maps_url,
            google_maps_url = :google_maps_url,
            repeat_weekly = :repeat_weekly,
            reminder_enabled = :reminder_enabled,
            reminder_minutes_before = :reminder_minutes_before,
            status = :status,
            updated_at = NOW()
         WHERE user_id = :user_id AND schedule_id = :schedule_id AND deleted_at IS NULL'
    );
    $stmt->execute($payload + ['user_id' => $user['id']]);
    ok(['schedule' => serializeSchedule(findScheduleRow($pdo, (int)$user['id'], $scheduleId))], 'Đã cập nhật lịch học.');
}

function handleScheduleDelete(PDO $pdo, array $user, array $data): void
{
    $scheduleId = trim((string)($data['id'] ?? ''));
    if ($scheduleId === '') {
        fail('invalid_input', 'Thiếu mã lịch học.');
    }
    $stmt = $pdo->prepare(
        'UPDATE schedules SET deleted_at = NOW(), updated_at = NOW()
         WHERE user_id = :user_id AND schedule_id = :schedule_id AND deleted_at IS NULL'
    );
    $stmt->execute(['user_id' => $user['id'], 'schedule_id' => $scheduleId]);
    if ($stmt->rowCount() === 0) {
        fail('not_found', 'Không tìm thấy lịch học để xoá.', 404);
    }
    ok(['scheduleId' => $scheduleId], 'Đã xoá lịch học.');
}

function handleTaskUpsert(PDO $pdo, array $user, array $data, bool $isUpdate): void
{
    $taskId = trim((string)($data['id'] ?? $data['taskId'] ?? '')) ?: 'task_' . bin2hex(random_bytes(8));
    $title = trim((string)($data['title'] ?? $data['name'] ?? ''));
    if ($title === '') {
        fail('invalid_input', 'Tiêu đề công việc không được để trống.');
    }
    $payload = [
        'task_id' => $taskId,
        'user_id' => $user['id'],
        'title' => $title,
        'description' => trim((string)($data['description'] ?? '')),
        'status' => trim((string)($data['status'] ?? 'pending')) ?: 'pending',
        'priority' => trim((string)($data['priority'] ?? 'normal')) ?: 'normal',
        'due_at' => toSqlDateTime($data['dueAt'] ?? $data['due_at'] ?? null),
        'payload_json' => jsonEncode($data),
    ];
    if ($isUpdate) {
        $stmt = $pdo->prepare(
            'UPDATE tasks SET
                title = :title, description = :description, status = :status, priority = :priority,
                due_at = :due_at, payload_json = :payload_json, updated_at = NOW()
             WHERE user_id = :user_id AND task_id = :task_id AND deleted_at IS NULL'
        );
        $stmt->execute($payload);
        if ($stmt->rowCount() === 0) {
            fail('not_found', 'Không tìm thấy công việc để cập nhật.', 404);
        }
        ok(['task' => findTaskRow($pdo, (int)$user['id'], $taskId)], 'Đã cập nhật công việc.');
    }
    $stmt = $pdo->prepare(
        'INSERT INTO tasks (
            task_id, user_id, title, description, status, priority, due_at, payload_json, created_at, updated_at
         ) VALUES (
            :task_id, :user_id, :title, :description, :status, :priority, :due_at, :payload_json, NOW(), NOW()
         )'
    );
    $stmt->execute($payload);
    ok(['task' => findTaskRow($pdo, (int)$user['id'], $taskId)], 'Đã tạo công việc.');
}

function handleTaskDelete(PDO $pdo, array $user, array $data): void
{
    $taskId = trim((string)($data['id'] ?? $data['taskId'] ?? ''));
    if ($taskId === '') {
        fail('invalid_input', 'Thiếu mã công việc.');
    }
    $stmt = $pdo->prepare(
        'UPDATE tasks SET deleted_at = NOW(), updated_at = NOW()
         WHERE user_id = :user_id AND task_id = :task_id AND deleted_at IS NULL'
    );
    $stmt->execute(['user_id' => $user['id'], 'task_id' => $taskId]);
    if ($stmt->rowCount() === 0) {
        fail('not_found', 'Không tìm thấy công việc để xoá.', 404);
    }
    ok(['taskId' => $taskId], 'Đã xoá công việc.');
}

function handleExamUpsert(PDO $pdo, array $user, array $data, bool $isUpdate): void
{
    $examId = trim((string)($data['id'] ?? $data['examId'] ?? '')) ?: 'exam_' . bin2hex(random_bytes(8));
    $subjectName = trim((string)($data['subjectName'] ?? $data['subject_name'] ?? ''));
    if ($subjectName === '') {
        fail('invalid_input', 'Tên môn thi không được để trống.');
    }
    $payload = [
        'exam_id' => $examId,
        'user_id' => $user['id'],
        'subject_name' => $subjectName,
        'exam_at' => toSqlDateTime($data['examAt'] ?? $data['exam_at'] ?? null),
        'location' => trim((string)($data['location'] ?? '')),
        'note' => trim((string)($data['note'] ?? '')),
        'status' => trim((string)($data['status'] ?? 'scheduled')) ?: 'scheduled',
        'payload_json' => jsonEncode($data),
    ];
    if ($isUpdate) {
        $stmt = $pdo->prepare(
            'UPDATE exams SET
                subject_name = :subject_name, exam_at = :exam_at, location = :location,
                note = :note, status = :status, payload_json = :payload_json, updated_at = NOW()
             WHERE user_id = :user_id AND exam_id = :exam_id AND deleted_at IS NULL'
        );
        $stmt->execute($payload);
        if ($stmt->rowCount() === 0) {
            fail('not_found', 'Không tìm thấy lịch thi để cập nhật.', 404);
        }
        ok(['exam' => findExamRow($pdo, (int)$user['id'], $examId)], 'Đã cập nhật lịch thi.');
    }
    $stmt = $pdo->prepare(
        'INSERT INTO exams (
            exam_id, user_id, subject_name, exam_at, location, note, status, payload_json, created_at, updated_at
         ) VALUES (
            :exam_id, :user_id, :subject_name, :exam_at, :location, :note, :status, :payload_json, NOW(), NOW()
         )'
    );
    $stmt->execute($payload);
    ok(['exam' => findExamRow($pdo, (int)$user['id'], $examId)], 'Đã tạo lịch thi.');
}

function handleExamDelete(PDO $pdo, array $user, array $data): void
{
    $examId = trim((string)($data['id'] ?? $data['examId'] ?? ''));
    if ($examId === '') {
        fail('invalid_input', 'Thiếu mã lịch thi.');
    }
    $stmt = $pdo->prepare(
        'UPDATE exams SET deleted_at = NOW(), updated_at = NOW()
         WHERE user_id = :user_id AND exam_id = :exam_id AND deleted_at IS NULL'
    );
    $stmt->execute(['user_id' => $user['id'], 'exam_id' => $examId]);
    if ($stmt->rowCount() === 0) {
        fail('not_found', 'Không tìm thấy lịch thi để xoá.', 404);
    }
    ok(['examId' => $examId], 'Đã xoá lịch thi.');
}

function handleStudyLogList(PDO $pdo, array $user, array $data): void
{
    $sql = 'SELECT * FROM study_logs WHERE user_id = :user_id';
    $params = ['user_id' => $user['id']];
    if (!empty($data['date'])) {
        $sql .= ' AND date = :date';
        $params['date'] = normalizeDate((string)$data['date']);
    } elseif (!empty($data['weekStart'])) {
        $start = normalizeDate((string)$data['weekStart']);
        $sql .= ' AND date BETWEEN :start_date AND :end_date';
        $params['start_date'] = $start;
        $params['end_date'] = date('Y-m-d', strtotime($start . ' +6 days'));
    }
    $sql .= ' ORDER BY date DESC, updated_at DESC';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    ok(['studyLogs' => array_map('serializeStudyLog', $stmt->fetchAll())]);
}

function handleStudyLogUpsert(PDO $pdo, array $user, array $data): void
{
    $logId = trim((string)($data['id'] ?? '')) ?: 'log_' . bin2hex(random_bytes(8));
    $stmt = $pdo->prepare(
        'INSERT INTO study_logs (
            log_id, user_id, schedule_id, subject_name, date, status,
            note_after_class, completed_at, payload_json, created_at, updated_at
         ) VALUES (
            :log_id, :user_id, :schedule_id, :subject_name, :date, :status,
            :note_after_class, :completed_at, :payload_json, NOW(), NOW()
         )
         ON DUPLICATE KEY UPDATE
            schedule_id = VALUES(schedule_id),
            subject_name = VALUES(subject_name),
            date = VALUES(date),
            status = VALUES(status),
            note_after_class = VALUES(note_after_class),
            completed_at = VALUES(completed_at),
            payload_json = VALUES(payload_json),
            updated_at = NOW()'
    );
    $stmt->execute([
        'log_id' => $logId,
        'user_id' => $user['id'],
        'schedule_id' => trim((string)($data['scheduleId'] ?? $data['schedule_id'] ?? '')),
        'subject_name' => trim((string)($data['subjectName'] ?? $data['subject_name'] ?? '')),
        'date' => normalizeDate((string)($data['date'] ?? date('c'))),
        'status' => trim((string)($data['status'] ?? 'planned')) ?: 'planned',
        'note_after_class' => trim((string)($data['noteAfterClass'] ?? $data['note_after_class'] ?? '')),
        'completed_at' => toSqlDateTime($data['completedAt'] ?? $data['completed_at'] ?? null),
        'payload_json' => jsonEncode($data),
    ]);
    ok(['studyLog' => serializeStudyLog(findStudyLogRow($pdo, (int)$user['id'], $logId))], 'Đã cập nhật nhật ký học.');
}

function handleShareCreate(PDO $pdo, array $user, array $data): void
{
    $shareId = trim((string)($data['id'] ?? $data['shareId'] ?? '')) ?: 'share_' . bin2hex(random_bytes(8));
    $stmt = $pdo->prepare(
        'INSERT INTO public_shares (
            share_id, owner_id, owner_uid, owner_name, title, share_type, theme, deep_link, qr_data,
            subjects_json, schedules_json, timetable_data_json, profile_photo, is_active, view_count,
            expires_at, deleted_at, created_at, updated_at
         ) VALUES (
            :share_id, :owner_id, :owner_uid, :owner_name, :title, :share_type, :theme, :deep_link, :qr_data,
            :subjects_json, :schedules_json, :timetable_data_json, :profile_photo, :is_active, :view_count,
            :expires_at, :deleted_at, NOW(), NOW()
         )
         ON DUPLICATE KEY UPDATE
            owner_name = VALUES(owner_name),
            title = VALUES(title),
            share_type = VALUES(share_type),
            theme = VALUES(theme),
            deep_link = VALUES(deep_link),
            qr_data = VALUES(qr_data),
            subjects_json = VALUES(subjects_json),
            schedules_json = VALUES(schedules_json),
            timetable_data_json = VALUES(timetable_data_json),
            profile_photo = VALUES(profile_photo),
            is_active = VALUES(is_active),
            deleted_at = VALUES(deleted_at),
            expires_at = VALUES(expires_at),
            updated_at = NOW()'
    );
    $data['ownerName'] = trim((string)($data['ownerName'] ?? $user['name'])) ?: 'Sinh viên';
    $data['title'] = trim((string)($data['title'] ?? 'Thời khóa biểu')) ?: 'Thời khóa biểu';
    $stmt->execute([
        'share_id' => $shareId,
        'owner_id' => $user['id'],
        'owner_uid' => $user['uid'],
        'owner_name' => trim((string)($data['ownerName'] ?? $user['name'])) ?: 'Sinh viên',
        'title' => trim((string)($data['title'] ?? 'Thời khóa biểu')) ?: 'Thời khóa biểu',
        'share_type' => trim((string)($data['shareType'] ?? 'week')) ?: 'week',
        'theme' => trim((string)($data['theme'] ?? 'liquidGlass')) ?: 'liquidGlass',
        'deep_link' => buildAppShareUrl($shareId),
        'qr_data' => buildPublicShareUrl($shareId),
        'subjects_json' => jsonEncode(is_array($data['subjects'] ?? null) ? $data['subjects'] : []),
        'schedules_json' => jsonEncode(is_array($data['schedules'] ?? null) ? $data['schedules'] : []),
        'timetable_data_json' => jsonEncode(is_array($data['timetableData'] ?? null) ? $data['timetableData'] : []),
        'profile_photo' => nullableString($data['profilePhoto'] ?? null),
        'is_active' => boolToInt($data['isActive'] ?? true),
        'view_count' => (int)($data['viewCount'] ?? 0),
        'expires_at' => toSqlDateTime($data['expiresAt'] ?? null),
        'deleted_at' => toSqlDateTime($data['deletedAt'] ?? null),
    ]);
    ok(['share' => serializeShare(findShareRow($pdo, $shareId))], 'Đã lưu link chia sẻ.');
}

function handleShareGet(PDO $pdo, array $data, ?array $viewer): void
{
    $shareId = trim((string)($data['shareId'] ?? ''));
    if ($shareId === '') {
        fail('invalid_input', 'Thiếu mã chia sẻ.');
    }
    $row = findShareRow($pdo, $shareId);
    $ownerView = $viewer && (int)$row['owner_id'] === (int)$viewer['id'];
    if (!$ownerView && ((int)$row['is_active'] !== 1 || !empty($row['deleted_at']) || isShareExpired($row))) {
        fail('not_found', 'Link chia sẻ đã bị xoá hoặc không còn hoạt động.', 404);
    }
    if (!$ownerView) {
        $pdo->prepare('UPDATE public_shares SET view_count = view_count + 1 WHERE share_id = :share_id')
            ->execute(['share_id' => $shareId]);
        $row = findShareRow($pdo, $shareId);
    }
    ok(['share' => serializeShare($row)]);
}

function handleShareUpdate(PDO $pdo, array $user, array $data): void
{
    $shareId = trim((string)($data['shareId'] ?? ''));
    if ($shareId === '') {
        fail('invalid_input', 'Thiếu mã chia sẻ.');
    }
    $row = findShareRow($pdo, $shareId);
    if ((int)$row['owner_id'] !== (int)$user['id']) {
        fail('permission_denied', 'Bạn chưa có quyền thực hiện thao tác này.', 403);
    }
    $fields = [];
    $params = ['share_id' => $shareId];
    foreach (['title' => 'title', 'theme' => 'theme', 'profilePhoto' => 'profile_photo'] as $key => $column) {
        if (array_key_exists($key, $data)) {
            $fields[] = $column . ' = :' . $key;
            $params[$key] = nullableString($data[$key]);
        }
    }
    if (array_key_exists('isActive', $data)) {
        $fields[] = 'is_active = :isActive';
        $params['isActive'] = boolToInt($data['isActive']);
    }
    if (array_key_exists('subjects', $data) && is_array($data['subjects'])) {
        $fields[] = 'subjects_json = :subjects_json';
        $params['subjects_json'] = jsonEncode($data['subjects']);
    }
    if (array_key_exists('schedules', $data) && is_array($data['schedules'])) {
        $fields[] = 'schedules_json = :schedules_json';
        $params['schedules_json'] = jsonEncode($data['schedules']);
    }
    if (!$fields) {
        ok(['share' => serializeShare($row)], 'Không có thay đổi.');
    }
    $sql = 'UPDATE public_shares SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE share_id = :share_id';
    $pdo->prepare($sql)->execute($params);
    ok(['share' => serializeShare(findShareRow($pdo, $shareId))], 'Đã cập nhật link chia sẻ.');
}

function handleShareDelete(PDO $pdo, array $user, array $data): void
{
    $shareId = trim((string)($data['shareId'] ?? ''));
    if ($shareId === '') {
        fail('invalid_input', 'Thiếu mã chia sẻ.');
    }
    $row = findShareRow($pdo, $shareId);
    if ((int)$row['owner_id'] !== (int)$user['id']) {
        fail('permission_denied', 'Bạn chưa có quyền thực hiện thao tác này.', 403);
    }
    $pdo->prepare(
        'UPDATE public_shares SET is_active = 0, deleted_at = NOW(), updated_at = NOW()
         WHERE share_id = :share_id AND owner_id = :owner_id'
    )->execute(['share_id' => $shareId, 'owner_id' => $user['id']]);
    ok(['shareId' => $shareId], 'Đã xoá link chia sẻ.');
}

function handleShareImport(PDO $pdo, array $user, array $data): void
{
    $shareId = trim((string)($data['shareId'] ?? ''));
    if ($shareId === '') {
        fail('invalid_input', 'Thiếu mã chia sẻ.');
    }
    $share = findShareRow($pdo, $shareId);
    if ((int)($share['is_active'] ?? 0) !== 1 || !empty($share['deleted_at']) || isShareExpired($share)) {
        fail('not_found', 'Link chia sẻ đã bị xóa hoặc không còn hoạt động.', 404);
    }
    $schedules = is_array($data['schedules'] ?? null) ? $data['schedules'] : [];
    $importedCount = 0;
    foreach ($schedules as $item) {
        if (!is_array($item)) {
            continue;
        }
        $scheduleId = 'import_' . bin2hex(random_bytes(8));
        $payload = normalizeSchedulePayload($item, $scheduleId);
        $duplicateCheck = $pdo->prepare(
            'SELECT id
             FROM schedules
             WHERE user_id = :user_id
               AND subject_name = :subject_name
               AND day_of_week = :day_of_week
               AND start_time = :start_time
               AND end_time = :end_time
               AND room = :room
               AND teacher = :teacher
               AND deleted_at IS NULL
             LIMIT 1'
        );
        $duplicateCheck->execute([
            'user_id' => $user['id'],
            'subject_name' => $payload['subject_name'],
            'day_of_week' => $payload['day_of_week'],
            'start_time' => $payload['start_time'],
            'end_time' => $payload['end_time'],
            'room' => $payload['room'],
            'teacher' => $payload['teacher'],
        ]);
        if ($duplicateCheck->fetch()) {
            continue;
        }
        $stmt = $pdo->prepare(
            'INSERT INTO schedules (
                schedule_id, user_id, subject_name, day_of_week, start_time, end_time, room,
                teacher, note, color, location_address, latitude, longitude, apple_maps_url,
                google_maps_url, repeat_weekly, reminder_enabled, reminder_minutes_before,
                status, created_at, updated_at
             ) VALUES (
                :schedule_id, :user_id, :subject_name, :day_of_week, :start_time, :end_time, :room,
                :teacher, :note, :color, :location_address, :latitude, :longitude, :apple_maps_url,
                :google_maps_url, :repeat_weekly, :reminder_enabled, :reminder_minutes_before,
                :status, NOW(), NOW()
             )'
        );
        $stmt->execute($payload + ['user_id' => $user['id']]);
        $importedCount++;
    }
    ok(['importedCount' => $importedCount], 'Đã nhập lịch học.');
}

function handleMyShares(PDO $pdo, array $user): void
{
    ok(['shares' => listMyShareRows($pdo, (int)$user['id'])]);
}

function handleFriendList(PDO $pdo, array $user): void
{
    $stmt = $pdo->prepare(
        'SELECT f.friend_uid, f.shared_subjects_json, f.created_at, f.updated_at,
                u.uid, u.name, u.id_user, u.id_profile, u.username, u.avatar_url, u.study_streak
         FROM friends f
         INNER JOIN users u ON u.uid = f.friend_uid
         WHERE f.user_id = :user_id
         ORDER BY f.created_at DESC'
    );
    $stmt->execute(['user_id' => $user['id']]);
    $rows = $stmt->fetchAll();
    $friends = [];
    foreach ($rows as $row) {
        $friendUser = findUserByUid($pdo, (string)$row['friend_uid']);
        $sumStmt = $pdo->prepare('SELECT COALESCE(SUM(end_time - start_time), 0) AS total_minutes FROM schedules WHERE user_id = :user_id AND deleted_at IS NULL');
        $sumStmt->execute(['user_id' => $friendUser['id']]);
        $minutes = (int)($sumStmt->fetch()['total_minutes'] ?? 0);
        $friendIdUser = trim((string)($row['id_user'] ?? '')) ?: (string)$row['username'];
        $friendIdProfile = (int)($row['id_profile'] ?? $friendUser['id']);
        $currentIdUser = trim((string)($user['id_user'] ?? '')) ?: (string)$user['username'];
        $friends[] = [
            'id' => $currentIdUser . '_' . $friendIdUser,
            'userIds' => [$currentIdUser, $friendIdUser],
            'friendId' => $friendIdUser,
            'friendUid' => (string)$row['friend_uid'],
            'friendIdUser' => $friendIdUser,
            'friendIdProfile' => $friendIdProfile,
            'friendName' => (string)$row['name'],
            'friendAvatarUrl' => nullableString($row['avatar_url']),
            'friendUsername' => $friendIdUser,
            'sharedSubjects' => decodeJsonList((string)($row['shared_subjects_json'] ?? '[]')),
            'weeklyHours' => round($minutes / 60, 1),
            'studyStreak' => (int)($row['study_streak'] ?? 0),
            'online' => false,
            'createdAt' => isoDateTime($row['created_at']),
            'updatedAt' => isoDateTime($row['updated_at']),
        ];
    }
    ok(['friends' => $friends]);
}

function handleFriendRequests(PDO $pdo, array $user): void
{
    $stmt = $pdo->prepare(
        'SELECT fr.*, fu.uid AS from_uid, fu.id_user AS from_id_user, fu.id_profile AS from_id_profile,
                fu.name AS from_name, fu.avatar_url AS from_avatar_url,
                tu.uid AS to_uid, tu.id_user AS to_id_user, tu.id_profile AS to_id_profile,
                tu.name AS to_name, tu.avatar_url AS to_avatar_url
         FROM friend_requests fr
         INNER JOIN users fu ON fu.id = fr.from_user_id
         INNER JOIN users tu ON tu.id = fr.to_user_id
         WHERE fr.to_user_id = :user_id AND fr.status = "pending"
         ORDER BY fr.created_at DESC'
    );
    $stmt->execute(['user_id' => $user['id']]);
    $requests = array_map(
        static fn(array $row): array => [
            'id' => (string)$row['request_id'],
            'fromUserId' => trim((string)($row['from_id_user'] ?? '')) ?: (string)$row['from_uid'],
            'toUserId' => trim((string)($row['to_id_user'] ?? '')) ?: (string)$row['to_uid'],
            'fromUid' => (string)$row['from_uid'],
            'toUid' => (string)$row['to_uid'],
            'fromIdProfile' => (int)($row['from_id_profile'] ?? 0),
            'toIdProfile' => (int)($row['to_id_profile'] ?? 0),
            'fromName' => (string)$row['from_name'],
            'toName' => (string)$row['to_name'],
            'fromAvatarUrl' => nullableString($row['from_avatar_url']),
            'toAvatarUrl' => nullableString($row['to_avatar_url']),
            'message' => (string)$row['message'],
            'status' => (string)$row['status'],
            'createdAt' => isoDateTime($row['created_at']),
            'updatedAt' => isoDateTime($row['updated_at']),
        ],
        $stmt->fetchAll()
    );
    ok(['requests' => $requests]);
}

function handleFriendSearch(PDO $pdo, array $user, array $data): void
{
    $query = trim((string)($data['query'] ?? ''));
    if ($query === '') {
        ok(['users' => []]);
    }
    $normalized = normalizeUsername($query);
    $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $query) . '%';
    $normalizedLike = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $normalized) . '%';
    $params = [
        'id' => $user['id'],
        'query' => $like,
        'normalized_query' => $normalizedLike,
    ];
    $profileClause = '';
    if (ctype_digit($query)) {
        $profileClause = ' OR id_profile = :id_profile';
        $params['id_profile'] = (int)$query;
    }
    $stmt = $pdo->prepare(
        'SELECT *
         FROM users
         WHERE id <> :id
           AND (
                name LIKE :query
             OR email LIKE :query
             OR username LIKE :normalized_query
             OR id_user LIKE :normalized_query
             ' . $profileClause . '
           )
         ORDER BY name ASC
         LIMIT 20'
    );
    $stmt->execute($params);
    ok(['users' => array_map('serializeUser', $stmt->fetchAll())]);
}

function handleFriendRequest(PDO $pdo, array $user, array $data): void
{
    $toUserIdentifier = trim((string)($data['toUserId'] ?? $data['toIdUser'] ?? $data['toIdProfile'] ?? ''));
    if ($toUserIdentifier === '') {
        fail('invalid_input', 'Thiếu người nhận lời mời.');
    }
    $toUser = findUserByPublicIdentifier($pdo, $toUserIdentifier);
    if ((int)$toUser['id'] === (int)$user['id']) {
        fail('invalid_input', 'Không thể tự kết bạn với chính mình.');
    }
    $pending = $pdo->prepare('SELECT id FROM friend_requests WHERE from_user_id = :from_user_id AND to_user_id = :to_user_id AND status = "pending" LIMIT 1');
    $pending->execute(['from_user_id' => $user['id'], 'to_user_id' => $toUser['id']]);
    if ($pending->fetch()) {
        fail('already_exists', 'Lời mời kết bạn đã được gửi trước đó.');
    }
    $requestId = 'fr_' . bin2hex(random_bytes(8));
    $pdo->prepare(
        'INSERT INTO friend_requests (request_id, from_user_id, to_user_id, message, status, shared_subjects_json, created_at, updated_at)
         VALUES (:request_id, :from_user_id, :to_user_id, :message, "pending", :shared_subjects_json, NOW(), NOW())'
    )->execute([
        'request_id' => $requestId,
        'from_user_id' => $user['id'],
        'to_user_id' => $toUser['id'],
        'message' => trim((string)($data['message'] ?? '')),
        'shared_subjects_json' => jsonEncode([]),
    ]);
    ok(['requestId' => $requestId], 'Đã gửi lời mời kết bạn.');
}

function handleFriendAccept(PDO $pdo, array $user, array $data): void
{
    $requestId = trim((string)($data['requestId'] ?? ''));
    if ($requestId === '') {
        fail('invalid_input', 'Thiếu mã lời mời.');
    }
    $stmt = $pdo->prepare('SELECT * FROM friend_requests WHERE request_id = :request_id AND to_user_id = :to_user_id AND status = "pending" LIMIT 1');
    $stmt->execute(['request_id' => $requestId, 'to_user_id' => $user['id']]);
    $request = $stmt->fetch();
    if (!$request) {
        fail('not_found', 'Không tìm thấy lời mời kết bạn.', 404);
    }
    $fromUser = findUserById($pdo, (int)$request['from_user_id']);
    $sharedSubjects = is_array($data['sharedSubjects'] ?? null) ? $data['sharedSubjects'] : [];
    $pdo->beginTransaction();
    try {
        $insert = $pdo->prepare(
            'INSERT INTO friends (user_id, user_uid, friend_id, friend_uid, shared_subjects_json, created_at, updated_at)
             VALUES (:user_id, :user_uid, :friend_id, :friend_uid, :shared_subjects_json, NOW(), NOW())
             ON DUPLICATE KEY UPDATE shared_subjects_json = VALUES(shared_subjects_json), updated_at = NOW()'
        );
        $insert->execute([
            'user_id' => $user['id'],
            'user_uid' => $user['uid'],
            'friend_id' => $fromUser['id'],
            'friend_uid' => $fromUser['uid'],
            'shared_subjects_json' => jsonEncode($sharedSubjects),
        ]);
        $insert->execute([
            'user_id' => $fromUser['id'],
            'user_uid' => $fromUser['uid'],
            'friend_id' => $user['id'],
            'friend_uid' => $user['uid'],
            'shared_subjects_json' => jsonEncode($sharedSubjects),
        ]);
        $pdo->prepare('UPDATE friend_requests SET status = "accepted", responded_at = NOW(), updated_at = NOW(), shared_subjects_json = :shared_subjects_json WHERE id = :id')
            ->execute(['shared_subjects_json' => jsonEncode($sharedSubjects), 'id' => $request['id']]);
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
    ok([], 'Đã chấp nhận lời mời kết bạn.');
}

function handleFriendReject(PDO $pdo, array $user, array $data): void
{
    $requestId = trim((string)($data['requestId'] ?? ''));
    if ($requestId === '') {
        fail('invalid_input', 'Thiếu mã lời mời.');
    }
    $stmt = $pdo->prepare('UPDATE friend_requests SET status = "declined", responded_at = NOW(), updated_at = NOW() WHERE request_id = :request_id AND to_user_id = :to_user_id AND status = "pending"');
    $stmt->execute(['request_id' => $requestId, 'to_user_id' => $user['id']]);
    if ($stmt->rowCount() === 0) {
        fail('not_found', 'Không tìm thấy lời mời kết bạn.', 404);
    }
    ok([], 'Đã từ chối lời mời kết bạn.');
}

function handleFriendRemove(PDO $pdo, array $user, array $data): void
{
    $friendIdentifier = trim((string)($data['friendId'] ?? ''));
    if ($friendIdentifier === '') {
        fail('invalid_input', 'Thiếu mã bạn bè.');
    }
    $friend = findUserByPublicIdentifier($pdo, $friendIdentifier);
    $pdo->prepare('DELETE FROM friends WHERE (user_id = :user_id AND friend_id = :friend_id) OR (user_id = :friend_id AND friend_id = :user_id)')
        ->execute(['user_id' => $user['id'], 'friend_id' => $friend['id']]);
    ok([], 'Đã xoá bạn bè.');
}

function handleLocationList(PDO $pdo, array $user): void
{
    ok(['locations' => listLocationRows($pdo, (int)$user['id'])]);
}

function handleLocationUpsert(PDO $pdo, array $user, array $data): void
{
    $locationId = trim((string)($data['id'] ?? '')) ?: 'loc_' . bin2hex(random_bytes(8));
    $pdo->prepare(
        'INSERT INTO classroom_locations (
            location_id, user_id, schedule_id, room_name, address, latitude, longitude,
            apple_maps_url, google_maps_url, created_at, updated_at
         ) VALUES (
            :location_id, :user_id, :schedule_id, :room_name, :address, :latitude, :longitude,
            :apple_maps_url, :google_maps_url, NOW(), NOW()
         )
         ON DUPLICATE KEY UPDATE
            schedule_id = VALUES(schedule_id), room_name = VALUES(room_name), address = VALUES(address),
            latitude = VALUES(latitude), longitude = VALUES(longitude), apple_maps_url = VALUES(apple_maps_url),
            google_maps_url = VALUES(google_maps_url), deleted_at = NULL, updated_at = NOW()'
    )->execute([
        'location_id' => $locationId,
        'user_id' => $user['id'],
        'schedule_id' => trim((string)($data['scheduleId'] ?? $data['schedule_id'] ?? '')),
        'room_name' => trim((string)($data['roomName'] ?? $data['room_name'] ?? '')),
        'address' => trim((string)($data['address'] ?? '')),
        'latitude' => readNullableFloat($data['latitude'] ?? null),
        'longitude' => readNullableFloat($data['longitude'] ?? null),
        'apple_maps_url' => nullableString($data['appleMapsUrl'] ?? $data['apple_maps_url'] ?? null),
        'google_maps_url' => nullableString($data['googleMapsUrl'] ?? $data['google_maps_url'] ?? null),
    ]);
    ok(['location' => serializeLocation(findLocationRow($pdo, (int)$user['id'], $locationId))], 'Đã lưu vị trí lớp học.');
}

function handleLocationDelete(PDO $pdo, array $user, array $data): void
{
    $locationId = trim((string)($data['id'] ?? ''));
    if ($locationId === '') {
        fail('invalid_input', 'Thiếu mã vị trí.');
    }
    $pdo->prepare('UPDATE classroom_locations SET deleted_at = NOW(), updated_at = NOW() WHERE user_id = :user_id AND location_id = :location_id AND deleted_at IS NULL')
        ->execute(['user_id' => $user['id'], 'location_id' => $locationId]);
    ok([], 'Đã xoá vị trí lớp học.');
}

function handleProfileCardCreate(PDO $pdo, array $user, array $data): void
{
    $cardId = trim((string)($data['id'] ?? '')) ?: 'card_' . bin2hex(random_bytes(8));
    $payload = $data;
    $idUser = trim((string)($user['id_user'] ?? '')) ?: (string)$user['username'];
    $payload['id'] = $cardId;
    $payload['ownerId'] = $user['uid'];
    $payload['idUser'] = $payload['idUser'] ?? $idUser;
    $payload['id_user'] = $payload['id_user'] ?? $idUser;
    $payload['idProfile'] = $payload['idProfile'] ?? (int)($user['id_profile'] ?? $user['id']);
    $payload['id_profile'] = $payload['id_profile'] ?? (int)($user['id_profile'] ?? $user['id']);
    $payload['createdAt'] = $payload['createdAt'] ?? gmdate(DATE_ATOM);
    $payload['updatedAt'] = gmdate(DATE_ATOM);
    $pdo->prepare(
        'INSERT INTO profile_cards (card_id, owner_id, owner_uid, payload_json, is_public, created_at, updated_at)
         VALUES (:card_id, :owner_id, :owner_uid, :payload_json, :is_public, NOW(), NOW())
         ON DUPLICATE KEY UPDATE payload_json = VALUES(payload_json), is_public = VALUES(is_public), updated_at = NOW()'
    )->execute([
        'card_id' => $cardId,
        'owner_id' => $user['id'],
        'owner_uid' => $user['uid'],
        'payload_json' => jsonEncode($payload),
        'is_public' => (int)($user['is_profile_public'] ?? 1),
    ]);
    ok(['card' => serializeProfileCard(findProfileCardRow($pdo, $cardId))], 'Đã tạo profile card.');
}

function handleProfileCardList(PDO $pdo, array $user): void
{
    ok(['cards' => listProfileCardRows($pdo, (int)$user['id'])]);
}

function handleProfileCardGet(PDO $pdo, array $data): void
{
    $cardId = trim((string)($data['cardId'] ?? ''));
    if ($cardId === '') {
        fail('invalid_input', 'Thiếu mã profile card.');
    }
    $row = findProfileCardRow($pdo, $cardId);
    if ((int)$row['is_public'] !== 1) {
        fail('permission_denied', 'Hồ sơ này hiện không công khai.', 403);
    }
    ok(['card' => serializeProfileCard($row)]);
}

function handleBackupExport(PDO $pdo, array $user): void
{
    $backup = [
        'exportedAt' => gmdate(DATE_ATOM),
        'user' => serializeUser($user),
        'settings' => getSettingsSection($pdo, (int)$user['id'], 'app_settings_json'),
        'notificationSettings' => getSettingsSection($pdo, (int)$user['id'], 'notification_settings_json'),
        'widgetSettings' => getSettingsSection($pdo, (int)$user['id'], 'widget_settings_json'),
        'dynamicIslandSettings' => getSettingsSection($pdo, (int)$user['id'], 'dynamic_island_settings_json'),
        'schedules' => listSchedules($pdo, (int)$user['id']),
        'tasks' => listTaskRows($pdo, (int)$user['id']),
        'exams' => listExamRows($pdo, (int)$user['id']),
        'studyLogs' => listStudyLogRows($pdo, (int)$user['id']),
        'shares' => listMyShareRows($pdo, (int)$user['id']),
        'locations' => listLocationRows($pdo, (int)$user['id']),
        'profileCards' => listProfileCardRows($pdo, (int)$user['id']),
    ];
    $backupId = 'backup_' . bin2hex(random_bytes(8));
    $pdo->prepare('INSERT INTO app_backups (backup_id, user_id, payload_json, created_at) VALUES (:backup_id, :user_id, :payload_json, NOW())')
        ->execute(['backup_id' => $backupId, 'user_id' => $user['id'], 'payload_json' => jsonEncode($backup)]);
    ok(['backupId' => $backupId, 'backup' => $backup]);
}

function handleBackupImport(PDO $pdo, array $user, array $data): void
{
    $backup = $data['backup'] ?? null;
    if (!is_array($backup)) {
        fail('invalid_input', 'File backup không hợp lệ.');
    }
    if (isset($backup['settings']) && is_array($backup['settings'])) {
        saveSettingsSection($pdo, (int)$user['id'], 'app_settings_json', $backup['settings']);
    }
    if (isset($backup['notificationSettings']) && is_array($backup['notificationSettings'])) {
        saveSettingsSection($pdo, (int)$user['id'], 'notification_settings_json', $backup['notificationSettings']);
    }
    if (isset($backup['widgetSettings']) && is_array($backup['widgetSettings'])) {
        saveSettingsSection($pdo, (int)$user['id'], 'widget_settings_json', $backup['widgetSettings']);
    }
    if (isset($backup['dynamicIslandSettings']) && is_array($backup['dynamicIslandSettings'])) {
        saveSettingsSection($pdo, (int)$user['id'], 'dynamic_island_settings_json', $backup['dynamicIslandSettings']);
    }
    foreach (($backup['schedules'] ?? []) as $item) {
        if (!is_array($item)) {
            continue;
        }
        $scheduleId = trim((string)($item['id'] ?? '')) ?: 'import_' . bin2hex(random_bytes(8));
        $payload = normalizeSchedulePayload($item, $scheduleId);
        $pdo->prepare(
            'INSERT INTO schedules (
                schedule_id, user_id, subject_name, day_of_week, start_time, end_time, room,
                teacher, note, color, location_address, latitude, longitude, apple_maps_url,
                google_maps_url, repeat_weekly, reminder_enabled, reminder_minutes_before,
                status, created_at, updated_at
             ) VALUES (
                :schedule_id, :user_id, :subject_name, :day_of_week, :start_time, :end_time, :room,
                :teacher, :note, :color, :location_address, :latitude, :longitude, :apple_maps_url,
                :google_maps_url, :repeat_weekly, :reminder_enabled, :reminder_minutes_before,
                :status, NOW(), NOW()
             )
             ON DUPLICATE KEY UPDATE
                subject_name = VALUES(subject_name), day_of_week = VALUES(day_of_week), start_time = VALUES(start_time),
                end_time = VALUES(end_time), room = VALUES(room), teacher = VALUES(teacher), note = VALUES(note),
                color = VALUES(color), location_address = VALUES(location_address), latitude = VALUES(latitude),
                longitude = VALUES(longitude), apple_maps_url = VALUES(apple_maps_url), google_maps_url = VALUES(google_maps_url),
                repeat_weekly = VALUES(repeat_weekly), reminder_enabled = VALUES(reminder_enabled),
                reminder_minutes_before = VALUES(reminder_minutes_before), deleted_at = NULL, updated_at = NOW()'
        )->execute($payload + ['user_id' => $user['id']]);
    }
    ok([], 'Đã nhập backup.');
}
