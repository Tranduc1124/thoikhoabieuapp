<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Asia/Ho_Chi_Minh');
ini_set('display_errors', '0');
error_reporting(E_ALL);

require_once __DIR__ . '/config.php';

set_exception_handler(
    static function (Throwable $error): void {
        $details = [
            'message' => $error->getMessage(),
            'file' => $error->getFile(),
            'line' => $error->getLine(),
            'method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'uri' => $_SERVER['REQUEST_URI'] ?? '',
        ];
        if ($error instanceof PDOException) {
            $details['pdo_code'] = $error->getCode();
            $details['pdo_error_info'] = $error->errorInfo ?? [];
        }
        error_log('[install.php] ' . json_encode($details, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Cài đặt database thất bại. Vui lòng kiểm tra error_log trên host.',
            'code' => 'install_failed',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
);

$providedKey = trim((string)($_GET['key'] ?? ''));
if ($providedKey === '' && PHP_SAPI === 'cli' && isset($argv[1])) {
    $providedKey = trim((string)$argv[1]);
}
if ($providedKey === '' || !hash_equals(INSTALL_KEY, $providedKey)) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'INSTALL_KEY không hợp lệ.',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
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

$queries = [
    'CREATE TABLE IF NOT EXISTS users (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        uid VARCHAR(64) NOT NULL UNIQUE,
        email VARCHAR(191) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(120) NOT NULL,
        id_user VARCHAR(64) NOT NULL UNIQUE,
        id_profile BIGINT UNSIGNED NULL UNIQUE,
        username VARCHAR(64) NOT NULL UNIQUE,
        bio TEXT NULL,
        avatar_url VARCHAR(500) NULL,
        theme_mode VARCHAR(32) NOT NULL DEFAULT "system",
        profile_theme VARCHAR(64) NOT NULL DEFAULT "aurora",
        favorite_subject VARCHAR(191) NOT NULL DEFAULT "",
        accent_color BIGINT NOT NULL DEFAULT 4285175295,
        study_streak INT NOT NULL DEFAULT 0,
        is_profile_public TINYINT(1) NOT NULL DEFAULT 1,
        allow_friends_to_view_timetable TINYINT(1) NOT NULL DEFAULT 1,
        hide_statistics TINYINT(1) NOT NULL DEFAULT 0,
        hide_streak TINYINT(1) NOT NULL DEFAULT 0,
        social_links_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_users_email (email),
        INDEX idx_users_uid (uid),
        INDEX idx_users_id_user (id_user),
        INDEX idx_users_id_profile (id_profile)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS auth_tokens (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL,
        token_hash CHAR(64) NOT NULL UNIQUE,
        created_at DATETIME NOT NULL,
        expires_at DATETIME NULL,
        revoked_at DATETIME NULL,
        last_used_at DATETIME NULL,
        user_agent VARCHAR(255) NULL,
        ip_address VARCHAR(45) NULL,
        INDEX idx_auth_tokens_user_id (user_id),
        CONSTRAINT fk_auth_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS password_resets (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL,
        token_hash CHAR(64) NOT NULL UNIQUE,
        email VARCHAR(191) NOT NULL,
        created_at DATETIME NOT NULL,
        expires_at DATETIME NOT NULL,
        used_at DATETIME NULL,
        INDEX idx_password_resets_user_id (user_id),
        INDEX idx_password_resets_email (email),
        CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS schedules (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        schedule_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        subject_name VARCHAR(191) NOT NULL,
        day_of_week TINYINT UNSIGNED NOT NULL,
        start_time INT NOT NULL,
        end_time INT NOT NULL,
        room VARCHAR(191) NOT NULL DEFAULT "",
        teacher VARCHAR(191) NOT NULL DEFAULT "",
        note TEXT NULL,
        color BIGINT NOT NULL DEFAULT 4285175295,
        location_address VARCHAR(255) NOT NULL DEFAULT "",
        latitude DECIMAL(10,7) NULL,
        longitude DECIMAL(10,7) NULL,
        apple_maps_url VARCHAR(500) NULL,
        google_maps_url VARCHAR(500) NULL,
        repeat_weekly TINYINT(1) NOT NULL DEFAULT 1,
        reminder_enabled TINYINT(1) NOT NULL DEFAULT 1,
        reminder_minutes_before INT NOT NULL DEFAULT 10,
        status VARCHAR(32) NOT NULL DEFAULT "active",
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_schedules_user_id (user_id),
        INDEX idx_schedules_user_day_start (user_id, day_of_week, start_time),
        CONSTRAINT fk_schedules_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS tasks (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        task_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        title VARCHAR(191) NOT NULL,
        description TEXT NULL,
        status VARCHAR(32) NOT NULL DEFAULT "pending",
        priority VARCHAR(32) NOT NULL DEFAULT "normal",
        due_at DATETIME NULL,
        payload_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_tasks_user_status (user_id, status),
        CONSTRAINT fk_tasks_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS exams (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        exam_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        subject_name VARCHAR(191) NOT NULL,
        exam_at DATETIME NULL,
        location VARCHAR(191) NOT NULL DEFAULT "",
        note TEXT NULL,
        status VARCHAR(32) NOT NULL DEFAULT "scheduled",
        payload_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_exams_user_exam_at (user_id, exam_at),
        CONSTRAINT fk_exams_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS study_logs (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        log_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        schedule_id VARCHAR(64) NOT NULL,
        subject_name VARCHAR(191) NOT NULL,
        date DATE NOT NULL,
        status VARCHAR(32) NOT NULL DEFAULT "planned",
        note_after_class TEXT NULL,
        completed_at DATETIME NULL,
        payload_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_study_logs_user_date (user_id, date),
        CONSTRAINT fk_study_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS settings (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL UNIQUE,
        app_settings_json LONGTEXT NULL,
        notification_settings_json LONGTEXT NULL,
        widget_settings_json LONGTEXT NULL,
        dynamic_island_settings_json LONGTEXT NULL,
        updated_at DATETIME NOT NULL,
        CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS public_shares (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        share_id VARCHAR(64) NOT NULL UNIQUE,
        owner_id BIGINT UNSIGNED NOT NULL,
        owner_uid VARCHAR(64) NOT NULL,
        owner_name VARCHAR(191) NOT NULL,
        title VARCHAR(191) NOT NULL,
        share_type VARCHAR(32) NOT NULL DEFAULT "week",
        theme VARCHAR(64) NOT NULL DEFAULT "liquidGlass",
        deep_link VARCHAR(255) NOT NULL,
        qr_data VARCHAR(255) NOT NULL,
        subjects_json LONGTEXT NULL,
        schedules_json LONGTEXT NULL,
        timetable_data_json LONGTEXT NULL,
        profile_photo VARCHAR(500) NULL,
        view_count INT NOT NULL DEFAULT 0,
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        expires_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_public_shares_share_id (share_id),
        INDEX idx_public_shares_owner_id (owner_id),
        CONSTRAINT fk_public_shares_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS friends (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT UNSIGNED NOT NULL,
        user_uid VARCHAR(64) NOT NULL,
        friend_id BIGINT UNSIGNED NOT NULL,
        friend_uid VARCHAR(64) NOT NULL,
        shared_subjects_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        UNIQUE KEY uniq_friend_pair (user_id, friend_id),
        INDEX idx_friends_user_friend (user_id, friend_id),
        CONSTRAINT fk_friends_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        CONSTRAINT fk_friends_friend FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS friend_requests (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        request_id VARCHAR(64) NOT NULL UNIQUE,
        from_user_id BIGINT UNSIGNED NOT NULL,
        to_user_id BIGINT UNSIGNED NOT NULL,
        message TEXT NULL,
        status VARCHAR(32) NOT NULL DEFAULT "pending",
        shared_subjects_json LONGTEXT NULL,
        responded_at DATETIME NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_friend_requests_from_user_id (from_user_id),
        INDEX idx_friend_requests_to_user_id (to_user_id),
        CONSTRAINT fk_friend_requests_from FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
        CONSTRAINT fk_friend_requests_to FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS profile_cards (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        card_id VARCHAR(64) NOT NULL UNIQUE,
        owner_id BIGINT UNSIGNED NOT NULL,
        owner_uid VARCHAR(64) NOT NULL,
        payload_json LONGTEXT NULL,
        is_public TINYINT(1) NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_profile_cards_owner_id (owner_id),
        CONSTRAINT fk_profile_cards_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS classroom_locations (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        location_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        schedule_id VARCHAR(64) NOT NULL,
        room_name VARCHAR(191) NOT NULL DEFAULT "",
        address VARCHAR(255) NOT NULL DEFAULT "",
        latitude DECIMAL(10,7) NULL,
        longitude DECIMAL(10,7) NULL,
        apple_maps_url VARCHAR(500) NULL,
        google_maps_url VARCHAR(500) NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_classroom_locations_user_id (user_id),
        CONSTRAINT fk_classroom_locations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS app_backups (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        backup_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        payload_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        INDEX idx_app_backups_user_id (user_id),
        CONSTRAINT fk_app_backups_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS schedule_comments (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        comment_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        schedule_id VARCHAR(64) NOT NULL,
        week_start DATE NULL,
        body TEXT NOT NULL,
        visibility VARCHAR(32) NOT NULL DEFAULT "private",
        shared_with_json LONGTEXT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        deleted_at DATETIME NULL,
        INDEX idx_schedule_comments_user_schedule (user_id, schedule_id),
        INDEX idx_schedule_comments_user_week (user_id, week_start),
        CONSTRAINT fk_schedule_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'CREATE TABLE IF NOT EXISTS leaderboard_entries (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        entry_id VARCHAR(64) NOT NULL UNIQUE,
        user_id BIGINT UNSIGNED NOT NULL,
        scope VARCHAR(32) NOT NULL DEFAULT "week",
        subject_name VARCHAR(191) NOT NULL DEFAULT "",
        points INT NOT NULL DEFAULT 0,
        payload_json LONGTEXT NULL,
        updated_at DATETIME NOT NULL,
        UNIQUE KEY uniq_leaderboard_user_scope_subject (user_id, scope, subject_name),
        INDEX idx_leaderboard_scope_points (scope, points),
        CONSTRAINT fk_leaderboard_entries_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
];

foreach ($queries as $query) {
    $pdo->exec($query);
}

ensureColumn($pdo, 'users', 'id_user', 'VARCHAR(64) NULL');
ensureColumn($pdo, 'users', 'id_profile', 'BIGINT UNSIGNED NULL');
backfillUserPublicIds($pdo);
ensureUniqueIndex($pdo, 'users', 'uniq_users_id_user', 'id_user');
ensureUniqueIndex($pdo, 'users', 'uniq_users_id_profile', 'id_profile');
ensureIndex($pdo, 'users', 'idx_users_id_user', 'id_user');
ensureIndex($pdo, 'users', 'idx_users_id_profile', 'id_profile');

$uploadPath = __DIR__ . '/uploads/avatars';
if (!is_dir($uploadPath)) {
    mkdir($uploadPath, 0775, true);
}

echo json_encode([
    'success' => true,
    'message' => 'Đã tạo hoặc cập nhật database thành công.',
    'baseUrl' => APP_BASE_URL,
    'uploadPath' => $uploadPath,
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

function ensureColumn(PDO $pdo, string $table, string $column, string $definition): void
{
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) AS count_value
         FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = :table_name
           AND COLUMN_NAME = :column_name'
    );
    $stmt->execute(['table_name' => $table, 'column_name' => $column]);
    if ((int)($stmt->fetch()['count_value'] ?? 0) > 0) {
        return;
    }
    $pdo->exec('ALTER TABLE `' . $table . '` ADD COLUMN `' . $column . '` ' . $definition);
}

function ensureIndex(PDO $pdo, string $table, string $indexName, string $column): void
{
    if (indexExists($pdo, $table, $indexName)) {
        return;
    }
    $pdo->exec('CREATE INDEX `' . $indexName . '` ON `' . $table . '` (`' . $column . '`)');
}

function ensureUniqueIndex(PDO $pdo, string $table, string $indexName, string $column): void
{
    if (indexExists($pdo, $table, $indexName)) {
        return;
    }
    $pdo->exec('CREATE UNIQUE INDEX `' . $indexName . '` ON `' . $table . '` (`' . $column . '`)');
}

function indexExists(PDO $pdo, string $table, string $indexName): bool
{
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) AS count_value
         FROM INFORMATION_SCHEMA.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = :table_name
           AND INDEX_NAME = :index_name'
    );
    $stmt->execute(['table_name' => $table, 'index_name' => $indexName]);
    return (int)($stmt->fetch()['count_value'] ?? 0) > 0;
}

function backfillUserPublicIds(PDO $pdo): void
{
    $pdo->exec(
        'UPDATE users
         SET id_profile = id
         WHERE id_profile IS NULL'
    );
    $rows = $pdo->query(
        'SELECT id, username, email, name
         FROM users
         WHERE id_user IS NULL OR id_user = ""'
    )->fetchAll();
    foreach ($rows as $row) {
        $base = normalizeInstallIdUser((string)($row['username'] ?? ''));
        if ($base === '') {
            $base = normalizeInstallIdUser((string)strtok((string)$row['email'], '@'));
        }
        if ($base === '') {
            $base = 'user' . (string)$row['id'];
        }
        $idUser = uniqueInstallIdUser($pdo, $base, (int)$row['id']);
        $stmt = $pdo->prepare(
            'UPDATE users
             SET id_user = :id_user, username = :username
             WHERE id = :id'
        );
        $stmt->execute([
            'id_user' => $idUser,
            'username' => $idUser,
            'id' => $row['id'],
        ]);
    }
}

function uniqueInstallIdUser(PDO $pdo, string $base, int $currentId): string
{
    $candidate = $base;
    $suffix = 1;
    while (true) {
        $stmt = $pdo->prepare(
            'SELECT id FROM users
             WHERE id_user = :id_user
               AND id <> :id
             LIMIT 1'
        );
        $stmt->execute(['id_user' => $candidate, 'id' => $currentId]);
        if (!$stmt->fetch()) {
            return $candidate;
        }
        $suffix++;
        $candidate = $base . $suffix;
    }
}

function normalizeInstallIdUser(string $value): string
{
    $normalized = mb_strtolower(trim($value));
    $normalized = preg_replace('/[^a-z0-9_]+/u', '', transliterateInstall($normalized)) ?? '';
    return substr($normalized, 0, 32);
}

function transliterateInstall(string $value): string
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
