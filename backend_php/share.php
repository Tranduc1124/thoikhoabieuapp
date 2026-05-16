<?php
declare(strict_types=1);

ini_set('display_errors', '0');
ini_set('html_errors', '0');
error_reporting(E_ALL);
date_default_timezone_set('Asia/Ho_Chi_Minh');

require_once __DIR__ . '/config.php';

$status = (int)($_GET['status'] ?? 0);
$shareId = trim((string)($_GET['id'] ?? ''));

if ($shareId === '') {
    $shareId = parseShareIdFromRequestUri();
}

$baseUrl = rtrim((string)(defined('APP_BASE_URL') ? APP_BASE_URL : ''), '/');
$downloadUrl = rtrim((string)(defined('APP_DOWNLOAD_URL') ? APP_DOWNLOAD_URL : $baseUrl), '/');

if ($status > 0 && $shareId === '') {
    renderNotAvailable(
        match ($status) {
            403 => 'Bạn chưa có quyền truy cập liên kết này.',
            500 => 'Trang chia sẻ đang tạm thời bận. Vui lòng thử lại sau.',
            default => 'Liên kết chia sẻ không tồn tại hoặc đã được đổi.',
        },
        $baseUrl,
        $downloadUrl,
        $status === 403 ? 403 : ($status === 500 ? 500 : 404)
    );
}

if ($shareId === '') {
    renderLanding($baseUrl, $downloadUrl);
}

try {
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
} catch (Throwable $error) {
    renderNotAvailable(
        'Không thể tải lịch học vào lúc này. Vui lòng thử lại sau.',
        $baseUrl,
        $downloadUrl,
        500
    );
}

$share = findPublicShare($pdo, $shareId);
if ($share === null || !isShareAvailable($share)) {
    renderNotAvailable(
        'Link chia sẻ đã bị xóa hoặc không còn hoạt động.',
        $baseUrl,
        $downloadUrl,
        404
    );
}

incrementShareViewCount($pdo, $shareId);
$share = normalizeShareRow($share, $baseUrl);
renderSharePreview($share, $baseUrl, $downloadUrl);

function parseShareIdFromRequestUri(): string
{
    $requestUri = (string)($_SERVER['REQUEST_URI'] ?? '');
    if ($requestUri === '') {
        return '';
    }
    $path = parse_url($requestUri, PHP_URL_PATH);
    if (!is_string($path) || $path === '') {
        return '';
    }
    $segments = array_values(array_filter(explode('/', trim($path, '/'))));
    $shareIndex = array_search('share', $segments, true);
    if ($shareIndex !== false && isset($segments[$shareIndex + 1])) {
        return trim((string)$segments[$shareIndex + 1]);
    }
    return '';
}

function findPublicShare(PDO $pdo, string $shareId): ?array
{
    $stmt = $pdo->prepare('SELECT * FROM public_shares WHERE share_id = :share_id LIMIT 1');
    $stmt->execute(['share_id' => $shareId]);
    $row = $stmt->fetch();
    return is_array($row) ? $row : null;
}

function incrementShareViewCount(PDO $pdo, string $shareId): void
{
    $pdo->prepare(
        'UPDATE public_shares
         SET view_count = view_count + 1, updated_at = updated_at
         WHERE share_id = :share_id'
    )->execute(['share_id' => $shareId]);
}

function isShareAvailable(array $share): bool
{
    if ((int)($share['is_active'] ?? 0) !== 1) {
        return false;
    }
    if (!empty($share['deleted_at'])) {
        return false;
    }
    if (!empty($share['expires_at'])) {
        $expiresAt = strtotime((string)$share['expires_at']);
        if ($expiresAt !== false && $expiresAt <= time()) {
            return false;
        }
    }
    return true;
}

function normalizeShareRow(array $row, string $baseUrl): array
{
    $shareId = (string)($row['share_id'] ?? '');
    $schedules = json_decode((string)($row['schedules_json'] ?? '[]'), true);
    $subjects = json_decode((string)($row['subjects_json'] ?? '[]'), true);
    if (!is_array($schedules)) {
        $schedules = [];
    }
    if (!is_array($subjects)) {
        $subjects = [];
    }

    return [
        'id' => $shareId,
        'ownerName' => trim((string)($row['owner_name'] ?? 'Sinh viên')) ?: 'Sinh viên',
        'title' => trim((string)($row['title'] ?? 'Thời khóa biểu')) ?: 'Thời khóa biểu',
        'profilePhoto' => trim((string)($row['profile_photo'] ?? '')),
        'viewCount' => (int)($row['view_count'] ?? 0) + 1,
        'schedules' => $schedules,
        'subjects' => array_values(array_filter(array_map('strval', $subjects))),
        'publicUrl' => buildPublicShareUrl($baseUrl, $shareId),
        'deepLink' => buildAppShareUrl($shareId),
        'createdAt' => (string)($row['created_at'] ?? ''),
    ];
}

function buildPublicShareUrl(string $baseUrl, string $shareId): string
{
    return $baseUrl . '/share/?id=' . rawurlencode($shareId);
}

function buildAppShareUrl(string $shareId): string
{
    return 'thoikhoabieu://share/' . rawurlencode($shareId);
}

function renderLanding(string $baseUrl, string $downloadUrl): void
{
    http_response_code(200);
    echo renderShell(
        'Thời Khóa Biểu',
        'Xem lịch học được chia sẻ',
        <<<HTML
        <section class="hero-card">
          <div class="eyebrow">Thời Khóa Biểu</div>
          <h1>Mở lịch học được chia sẻ chỉ trong vài chạm.</h1>
          <p>Dán liên kết chia sẻ hoặc quay lại ứng dụng để xem thời khóa biểu, quét mã QR và thêm lịch vào máy của bạn.</p>
          <div class="actions">
            <a class="button button-primary" href="{$baseUrl}">Trang chủ</a>
            <a class="button button-secondary" href="{$downloadUrl}">Tải ứng dụng</a>
          </div>
        </section>
        HTML
    );
    exit;
}

function renderNotAvailable(string $message, string $baseUrl, string $downloadUrl, int $status): void
{
    http_response_code($status);
    echo renderShell(
        'Liên kết không khả dụng',
        'Không thể mở lịch học',
        <<<HTML
        <section class="hero-card">
          <div class="eyebrow">Liên kết chia sẻ</div>
          <h1>Không thể mở lịch học này.</h1>
          <p>{$message}</p>
          <div class="actions">
            <a class="button button-primary" href="{$downloadUrl}">Tải ứng dụng</a>
            <a class="button button-secondary" href="{$baseUrl}">Quay lại trang chủ</a>
          </div>
        </section>
        HTML
    );
    exit;
}

function renderSharePreview(array $share, string $baseUrl, string $downloadUrl): void
{
    $title = htmlspecialchars($share['title'], ENT_QUOTES, 'UTF-8');
    $ownerName = htmlspecialchars($share['ownerName'], ENT_QUOTES, 'UTF-8');
    $publicUrl = htmlspecialchars($share['publicUrl'], ENT_QUOTES, 'UTF-8');
    $deepLink = htmlspecialchars($share['deepLink'], ENT_QUOTES, 'UTF-8');
    $deepLinkJson = json_encode($share['deepLink'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $shareId = htmlspecialchars($share['id'], ENT_QUOTES, 'UTF-8');
    $subtitle = count($share['schedules']) . ' buổi học • ' . (int)$share['viewCount'] . ' lượt xem';
    $ownerAvatar = renderOwnerAvatar($share);
    $scheduleCards = renderScheduleCards($share['schedules']);
    $subjectBadges = renderSubjectBadges($share['subjects']);

    http_response_code(200);
    echo renderShell(
        $share['title'],
        'Lịch học được chia sẻ',
        <<<HTML
        <section class="hero-card">
          <div class="hero-top">
            <div class="owner">
              {$ownerAvatar}
              <div>
                <div class="eyebrow">Lịch được chia sẻ</div>
                <h1>{$title}</h1>
                <p class="hero-meta">Từ {$ownerName} • {$subtitle}</p>
              </div>
            </div>
            <div class="hero-chip">Mã chia sẻ: {$shareId}</div>
          </div>
          <p>Quét mã hoặc mở ứng dụng để xem nhanh, thêm lịch học vào máy và tiếp tục học tập thật gọn gàng.</p>
          <div class="actions">
            <a class="button button-primary" href="{$deepLink}" id="open-app-button">Mở ứng dụng</a>
            <a class="button button-secondary" href="{$downloadUrl}">Tải ứng dụng</a>
          </div>
          <div class="link-box">
            <span>Liên kết chia sẻ</span>
            <strong>{$publicUrl}</strong>
          </div>
        </section>
        <section class="panel">
          <div class="panel-head">
            <h2>Môn học trong lịch</h2>
            <span>{$subtitle}</span>
          </div>
          {$subjectBadges}
          <div class="schedule-grid">
            {$scheduleCards}
          </div>
        </section>
        <script>
          (function() {
            const deepLink = {$deepLinkJson};
            const button = document.getElementById('open-app-button');
            let attempted = false;
            let hidden = false;

            document.addEventListener('visibilitychange', function () {
              hidden = document.visibilityState === 'hidden';
            });

            function openApp(fromUser) {
              attempted = true;
              const now = Date.now();
              window.location.href = deepLink;
              if (fromUser) {
                return;
              }
              window.setTimeout(function () {
                if (!hidden && Date.now() - now < 2200) {
                  document.body.classList.add('show-fallback');
                }
              }, 1400);
            }

            if (button) {
              button.addEventListener('click', function (event) {
                event.preventDefault();
                openApp(true);
              });
            }

            window.setTimeout(function () {
              if (!attempted) {
                openApp(false);
              }
            }, 500);
          })();
        </script>
        HTML
    );
    exit;
}

function renderOwnerAvatar(array $share): string
{
    $photo = trim((string)($share['profilePhoto'] ?? ''));
    $initial = mb_strtoupper(mb_substr((string)$share['ownerName'], 0, 1), 'UTF-8');
    if ($photo !== '') {
        $safeUrl = htmlspecialchars($photo, ENT_QUOTES, 'UTF-8');
        return '<div class="owner-avatar"><img src="' . $safeUrl . '" alt="Ảnh đại diện" loading="lazy" /></div>';
    }
    return '<div class="owner-avatar owner-avatar-fallback">' . htmlspecialchars($initial, ENT_QUOTES, 'UTF-8') . '</div>';
}

function renderSubjectBadges(array $subjects): string
{
    if ($subjects === []) {
        return '';
    }

    $items = array_map(
        static fn(string $subject): string => '<span class="subject-pill">' . htmlspecialchars($subject, ENT_QUOTES, 'UTF-8') . '</span>',
        array_slice($subjects, 0, 12)
    );

    return '<div class="subject-list">' . implode('', $items) . '</div>';
}

function renderScheduleCards(array $schedules): string
{
    if ($schedules === []) {
        return '<div class="empty-note">Lịch chia sẻ này chưa có buổi học nào.</div>';
    }

    $cards = [];
    foreach ($schedules as $schedule) {
        if (!is_array($schedule)) {
            continue;
        }
        $subject = htmlspecialchars((string)($schedule['subjectName'] ?? $schedule['subject_name'] ?? 'Môn học'), ENT_QUOTES, 'UTF-8');
        $room = trim((string)($schedule['room'] ?? ''));
        $teacher = trim((string)($schedule['teacher'] ?? ''));
        $note = trim((string)($schedule['note'] ?? ''));
        $day = dayName((int)($schedule['dayOfWeek'] ?? $schedule['day_of_week'] ?? 1));
        $time = formatMinutes((int)readMinutes($schedule['startTime'] ?? $schedule['start_time'] ?? 0))
            . ' - ' .
            formatMinutes((int)readMinutes($schedule['endTime'] ?? $schedule['end_time'] ?? 0));

        $meta = [];
        $meta[] = '<span class="meta-pill">' . htmlspecialchars($day, ENT_QUOTES, 'UTF-8') . '</span>';
        $meta[] = '<span class="meta-pill">' . htmlspecialchars($time, ENT_QUOTES, 'UTF-8') . '</span>';
        if ($room !== '') {
            $meta[] = '<span class="meta-pill">Phòng ' . htmlspecialchars($room, ENT_QUOTES, 'UTF-8') . '</span>';
        }
        if ($teacher !== '') {
            $meta[] = '<span class="meta-pill">' . htmlspecialchars($teacher, ENT_QUOTES, 'UTF-8') . '</span>';
        }
        $metaHtml = implode('', $meta);

        $noteHtml = $note !== ''
            ? '<p class="schedule-note">' . htmlspecialchars($note, ENT_QUOTES, 'UTF-8') . '</p>'
            : '';

        $cards[] = <<<HTML
        <article class="schedule-card">
          <div class="schedule-icon">📚</div>
          <div class="schedule-content">
            <h3>{$subject}</h3>
            <div class="meta-line">{$day}</div>
            <div class="meta-wrap">{$metaHtml}</div>
            {$noteHtml}
          </div>
        </article>
        HTML;
    }

    return implode('', $cards);
}

function renderShell(string $title, string $description, string $content): string
{
    $pageTitle = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
    $pageDescription = htmlspecialchars($description, ENT_QUOTES, 'UTF-8');

    return <<<HTML
    <!doctype html>
    <html lang="vi">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>{$pageTitle}</title>
      <meta name="description" content="{$pageDescription}" />
      <style>
        :root {
          color-scheme: light dark;
          --bg-top: #f8fbff;
          --bg-mid: #eef4ff;
          --bg-bottom: #fff5f0;
          --panel: rgba(255, 255, 255, 0.72);
          --panel-strong: rgba(255, 255, 255, 0.88);
          --text: #0f172a;
          --text-secondary: #475569;
          --stroke: rgba(255, 255, 255, 0.72);
          --shadow: rgba(91, 124, 250, 0.18);
          --primary: #5b7cfa;
          --secondary: #8ed8ff;
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --bg-top: #070b16;
            --bg-mid: #0b1020;
            --bg-bottom: #111827;
            --panel: rgba(21, 31, 50, 0.82);
            --panel-strong: rgba(17, 24, 39, 0.92);
            --text: #f8fafc;
            --text-secondary: #cbd5e1;
            --stroke: rgba(255, 255, 255, 0.12);
            --shadow: rgba(8, 15, 33, 0.42);
            --primary: #7ba7ff;
            --secondary: #9ddcff;
          }
        }
        * { box-sizing: border-box; }
        body {
          margin: 0;
          min-height: 100vh;
          font-family: "Be Vietnam Pro", Inter, "SF Pro Text", Roboto, Arial, sans-serif;
          color: var(--text);
          background:
            radial-gradient(circle at top left, rgba(123, 167, 255, 0.24), transparent 34%),
            radial-gradient(circle at bottom right, rgba(142, 216, 255, 0.18), transparent 26%),
            linear-gradient(160deg, var(--bg-top), var(--bg-mid), var(--bg-bottom));
        }
        body::before {
          content: "";
          position: fixed;
          inset: 0;
          backdrop-filter: blur(0);
          pointer-events: none;
        }
        .page {
          width: min(980px, calc(100% - 32px));
          margin: 0 auto;
          padding: 32px 0 48px;
        }
        .hero-card,
        .panel {
          background: var(--panel);
          border: 1px solid var(--stroke);
          border-radius: 30px;
          box-shadow: 0 24px 60px var(--shadow);
          backdrop-filter: blur(18px);
          -webkit-backdrop-filter: blur(18px);
        }
        .hero-card {
          padding: 24px;
        }
        .panel {
          padding: 22px;
          margin-top: 18px;
        }
        .eyebrow {
          font-size: 13px;
          font-weight: 800;
          letter-spacing: 0.04em;
          text-transform: uppercase;
          color: var(--primary);
        }
        h1 {
          margin: 10px 0 10px;
          font-size: clamp(28px, 4vw, 40px);
          line-height: 1.04;
        }
        h2 {
          margin: 0;
          font-size: 22px;
        }
        h3 {
          margin: 0;
          font-size: 18px;
        }
        p {
          margin: 0;
          color: var(--text-secondary);
          line-height: 1.6;
        }
        .hero-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 16px;
          flex-wrap: wrap;
        }
        .owner {
          display: flex;
          align-items: center;
          gap: 14px;
        }
        .owner-avatar {
          width: 58px;
          height: 58px;
          border-radius: 22px;
          overflow: hidden;
          background: linear-gradient(135deg, var(--primary), var(--secondary));
          display: inline-flex;
          align-items: center;
          justify-content: center;
          font-size: 24px;
          font-weight: 900;
          color: white;
          box-shadow: 0 18px 34px rgba(91, 124, 250, 0.22);
        }
        .owner-avatar img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        .owner-avatar-fallback {
          text-transform: uppercase;
        }
        .hero-meta,
        .panel-head span,
        .meta-line,
        .empty-note {
          color: var(--text-secondary);
        }
        .hero-chip,
        .subject-pill,
        .meta-pill,
        .link-box {
          border: 1px solid var(--stroke);
          background: var(--panel-strong);
          backdrop-filter: blur(14px);
          -webkit-backdrop-filter: blur(14px);
        }
        .hero-chip {
          border-radius: 999px;
          padding: 10px 14px;
          font-weight: 700;
          color: var(--text-secondary);
        }
        .actions {
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
          margin-top: 18px;
        }
        .button {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-height: 48px;
          padding: 0 18px;
          border-radius: 18px;
          text-decoration: none;
          font-weight: 800;
          transition: transform 180ms ease, opacity 180ms ease;
        }
        .button:hover {
          transform: translateY(-1px);
        }
        .button-primary {
          color: white;
          background: linear-gradient(135deg, var(--primary), var(--secondary));
          box-shadow: 0 16px 32px rgba(91, 124, 250, 0.26);
        }
        .button-secondary {
          color: var(--text);
          background: var(--panel-strong);
          border: 1px solid var(--stroke);
        }
        .link-box {
          margin-top: 18px;
          border-radius: 22px;
          padding: 14px 16px;
          display: flex;
          flex-direction: column;
          gap: 4px;
        }
        .link-box span {
          font-size: 13px;
          font-weight: 700;
          color: var(--text-secondary);
        }
        .link-box strong {
          overflow-wrap: anywhere;
          font-size: 14px;
        }
        .panel-head {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 16px;
          flex-wrap: wrap;
        }
        .subject-list {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
          margin-top: 16px;
        }
        .subject-pill,
        .meta-pill {
          border-radius: 999px;
          padding: 9px 12px;
          font-size: 13px;
          font-weight: 700;
          color: var(--text-secondary);
        }
        .schedule-grid {
          display: grid;
          gap: 14px;
          margin-top: 18px;
        }
        .schedule-card {
          display: grid;
          grid-template-columns: 54px minmax(0, 1fr);
          gap: 14px;
          align-items: start;
          padding: 16px;
          border-radius: 26px;
          background: linear-gradient(135deg, rgba(255,255,255,0.42), rgba(255,255,255,0.16));
          border: 1px solid var(--stroke);
        }
        .schedule-icon {
          width: 54px;
          height: 54px;
          border-radius: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 26px;
          background: linear-gradient(135deg, rgba(91, 124, 250, 0.94), rgba(142, 216, 255, 0.88));
          box-shadow: 0 14px 30px rgba(91, 124, 250, 0.18);
        }
        .schedule-content {
          min-width: 0;
        }
        .meta-wrap {
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
          margin-top: 10px;
        }
        .schedule-note {
          margin-top: 10px;
        }
        .empty-note {
          margin-top: 10px;
          padding: 14px 0 4px;
        }
        body.show-fallback .link-box::after {
          content: "Nếu ứng dụng chưa mở, bạn vẫn có thể xem lịch học ngay trên trang này.";
          display: block;
          margin-top: 10px;
          font-size: 13px;
          color: var(--text-secondary);
        }
        @media (max-width: 640px) {
          .page {
            width: min(100%, calc(100% - 24px));
            padding-top: 20px;
          }
          .hero-card,
          .panel {
            border-radius: 26px;
          }
          .schedule-card {
            grid-template-columns: 1fr;
          }
          .schedule-icon {
            width: 48px;
            height: 48px;
            border-radius: 18px;
          }
        }
      </style>
    </head>
    <body>
      <main class="page">
        {$content}
      </main>
    </body>
    </html>
    HTML;
}

function dayName(int $dayOfWeek): string
{
    return match ($dayOfWeek) {
        1 => 'Thứ 2',
        2 => 'Thứ 3',
        3 => 'Thứ 4',
        4 => 'Thứ 5',
        5 => 'Thứ 6',
        6 => 'Thứ 7',
        7 => 'Chủ nhật',
        default => 'Lịch học',
    };
}

function readMinutes(mixed $value): int
{
    if (is_numeric($value)) {
        return (int)$value;
    }
    $text = trim((string)$value);
    if ($text === '') {
        return 0;
    }
    if (preg_match('/^(\d{1,2}):(\d{2})$/', $text, $matches)) {
        return ((int)$matches[1] * 60) + (int)$matches[2];
    }
    return (int)$text;
}

function formatMinutes(int $minutes): string
{
    $hours = str_pad((string)intdiv($minutes, 60), 2, '0', STR_PAD_LEFT);
    $mins = str_pad((string)($minutes % 60), 2, '0', STR_PAD_LEFT);
    return $hours . ':' . $mins;
}
