<?php
declare(strict_types=1);

date_default_timezone_set('Asia/Ho_Chi_Minh');
ini_set('display_errors', '0');
error_reporting(E_ALL);

require_once __DIR__ . '/config.php';

$message = '';
$success = false;
$token = trim((string)($_GET['token'] ?? $_POST['token'] ?? ''));

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $password = (string)($_POST['password'] ?? '');
    $confirm = (string)($_POST['confirm_password'] ?? '');
    if ($token === '' || strlen($password) < 6 || $password !== $confirm) {
        $message = 'Link hoac mat khau khong hop le. Mat khau can toi thieu 6 ky tu.';
    } else {
        try {
            $pdo = resetDb();
            $pdo->beginTransaction();
            $stmt = $pdo->prepare(
                'SELECT pr.id, pr.user_id
                 FROM password_resets pr
                 WHERE pr.token_hash = :token_hash
                   AND pr.used_at IS NULL
                   AND pr.expires_at > NOW()
                 LIMIT 1'
            );
            $stmt->execute(['token_hash' => hash('sha256', $token)]);
            $row = $stmt->fetch();
            if (!$row) {
                $pdo->rollBack();
                $message = 'Link khoi phuc da het han hoac da duoc su dung.';
            } else {
                $pdo->prepare(
                    'UPDATE users
                     SET password_hash = :password_hash, updated_at = NOW()
                     WHERE id = :user_id'
                )->execute([
                    'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                    'user_id' => $row['user_id'],
                ]);
                $pdo->prepare(
                    'UPDATE password_resets
                     SET used_at = NOW()
                     WHERE id = :id'
                )->execute(['id' => $row['id']]);
                $pdo->prepare(
                    'UPDATE auth_tokens
                     SET revoked_at = NOW()
                     WHERE user_id = :user_id AND revoked_at IS NULL'
                )->execute(['user_id' => $row['user_id']]);
                $pdo->commit();
                $success = true;
                $message = 'Da cap nhat mat khau. Ban co the quay lai app de dang nhap.';
            }
        } catch (Throwable $error) {
            if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[reset-password.php] ' . $error->getMessage() . ' @ ' . $error->getFile() . ':' . $error->getLine());
            $message = 'May chu dang gap su co. Vui long thu lai sau.';
        }
    }
}

function resetDb(): PDO
{
    return new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
}

function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
?>
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Khoi phuc mat khau</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: linear-gradient(135deg, #eef5ff, #f8fbff 52%, #f2fff8);
      color: #102033;
    }
    main {
      width: min(420px, calc(100vw - 32px));
      padding: 28px;
      border-radius: 24px;
      background: rgba(255,255,255,.86);
      box-shadow: 0 24px 70px rgba(50,70,110,.18);
      border: 1px solid rgba(80,120,170,.16);
    }
    h1 { margin: 0 0 8px; font-size: 26px; }
    p { margin: 0 0 20px; color: #526477; line-height: 1.5; }
    label { display: block; margin: 14px 0 8px; font-weight: 700; }
    input {
      width: 100%;
      box-sizing: border-box;
      border: 1px solid #d7e0ec;
      border-radius: 14px;
      padding: 13px 14px;
      font-size: 16px;
    }
    button {
      width: 100%;
      margin-top: 18px;
      border: 0;
      border-radius: 14px;
      padding: 14px;
      font-size: 16px;
      font-weight: 800;
      color: white;
      background: #346dff;
    }
    .message {
      padding: 12px 14px;
      border-radius: 14px;
      margin-bottom: 18px;
      background: <?= $success ? '#e9f9ef' : '#fff2e8' ?>;
      color: <?= $success ? '#17633a' : '#8a3b00' ?>;
    }
  </style>
</head>
<body>
  <main>
    <h1>Khoi phuc mat khau</h1>
    <p>Nhap mat khau moi cho tai khoan Thoi Khoa Bieu cua ban.</p>
    <?php if ($message !== ''): ?>
      <div class="message"><?= e($message) ?></div>
    <?php endif; ?>
    <?php if (!$success): ?>
      <form method="post">
        <input type="hidden" name="token" value="<?= e($token) ?>">
        <label for="password">Mat khau moi</label>
        <input id="password" name="password" type="password" minlength="6" required>
        <label for="confirm_password">Nhap lai mat khau</label>
        <input id="confirm_password" name="confirm_password" type="password" minlength="6" required>
        <button type="submit">Cap nhat mat khau</button>
      </form>
    <?php endif; ?>
  </main>
</body>
</html>
