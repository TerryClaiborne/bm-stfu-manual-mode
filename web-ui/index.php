<?php
declare(strict_types=1);
session_start();

const FAVORITES_FILE = '/var/www/html/stfu/favorites.txt';
const STATUS_CMD = 'sudo /usr/local/bin/bm-stfu.sh status';

function run_command(string $command): array
{
    $output = [];
    $exitCode = 0;
    exec($command . ' 2>&1', $output, $exitCode);

    return [
        'command' => $command,
        'output' => $output,
        'exit_code' => $exitCode,
        'ok' => $exitCode === 0,
    ];
}

function clean_lines(array $lines): array
{
    $clean = [];
    foreach ($lines as $line) {
        $line = trim((string) $line);
        if ($line !== '') {
            $clean[] = $line;
        }
    }
    return $clean;
}

function safe_target(?string $value): string
{
    $value = trim((string) $value);
    if ($value === '') {
        return '';
    }
    if (preg_match('/^\d{1,20}#?$/', $value)) {
        return $value;
    }
    return '';
}

function safe_text(?string $value, int $max = 120): string
{
    $value = trim((string) $value);
    $value = preg_replace('/[\x00-\x1F\x7F]/u', ' ', $value) ?? '';
    $value = preg_replace('/\s+/', ' ', $value) ?? '';
    return substr($value, 0, $max);
}

function ensure_favorites_file(string $path): bool
{
    if (is_file($path)) {
        return is_writable($path);
    }

    $dir = dirname($path);
    if (!is_dir($dir)) {
        return false;
    }

    $created = @file_put_contents($path, '', LOCK_EX);
    if ($created === false) {
        return false;
    }

    return is_writable($path);
}

function read_favorites(string $path): array
{
    if (!is_file($path)) {
        return [];
    }

    $lines = @file($path, FILE_IGNORE_NEW_LINES);
    if (!is_array($lines)) {
        return [];
    }

    $favorites = [];
    foreach ($lines as $line) {
        $line = trim((string) $line);
        if ($line === '') {
            continue;
        }

        $parts = explode("\t", $line);
        $parts = array_pad($parts, 3, '');
        $target = safe_target($parts[0] ?? '');
        $label = safe_text($parts[1] ?? '', 80);
        $description = safe_text($parts[2] ?? '', 160);

        if ($target === '' || $label === '') {
            continue;
        }

        $favorites[] = [
            'target' => $target,
            'label' => $label,
            'description' => $description,
        ];
    }

    return $favorites;
}

function write_favorites(string $path, array $favorites): bool
{
    $lines = [];
    foreach ($favorites as $favorite) {
        $target = safe_target($favorite['target'] ?? '');
        $label = safe_text($favorite['label'] ?? '', 80);
        $description = safe_text($favorite['description'] ?? '', 160);

        if ($target === '' || $label === '') {
            continue;
        }

        $lines[] = implode("\t", [$target, $label, $description]);
    }

    $content = '';
    if ($lines !== []) {
        $content = implode("\n", $lines) . "\n";
    }

    return @file_put_contents($path, $content, LOCK_EX) !== false;
}

function parse_status(array $statusResult): array
{
    $lines = clean_lines($statusResult['output']);
    $stfuLine = '';
    $bridgeLine = '';

    foreach ($lines as $line) {
        if ($stfuLine === '' && stripos($line, 'STFU is') !== false) {
            $stfuLine = $line;
        }
        if ($bridgeLine === '' && stripos($line, 'mmdvm_bridge:') !== false) {
            $bridgeLine = $line;
        }
    }

    $running = null;
    if ($stfuLine !== '') {
        $lower = strtolower($stfuLine);
        if (strpos($lower, 'not running') !== false) {
            $running = false;
        } elseif (strpos($lower, 'running') !== false) {
            $running = true;
        }
    }

    $bridge = 'Unknown';
    $bridgeClass = '';
    if ($bridgeLine !== '') {
        if (preg_match('/mmdvm_bridge:\s*(\S+)/i', $bridgeLine, $m)) {
            $bridge = ucfirst(strtolower($m[1]));
            if (strcasecmp($m[1], 'active') === 0) {
                $bridgeClass = 'value-good';
            } elseif (strcasecmp($m[1], 'inactive') === 0) {
                $bridgeClass = 'value-bad';
            }
        }
    }

    $mode = 'Unknown';
    $badgeClass = 'badge';
    if ($running === true) {
        $mode = 'Active';
        $badgeClass = 'badge badge-on';
    } elseif ($running === false) {
        $mode = 'Idle';
        $badgeClass = 'badge badge-off';
    }

    $currentTarget = '';
    if ($running === true && !empty($_SESSION['stfu_last_target'])) {
        $currentTarget = safe_target((string) $_SESSION['stfu_last_target']);
    }

    return [
        'mode' => $mode,
        'badge_class' => $badgeClass,
        'bridge' => $bridge,
        'bridge_class' => $bridgeClass,
        'backend' => $statusResult['ok'] ? 'OK' : 'Error',
        'backend_class' => $statusResult['ok'] ? 'value-good' : 'value-bad',
        'headline' => $running === true ? 'STFU Running' : 'STFU Idle',
        'current_target' => $currentTarget,
        'raw_lines' => $lines,
    ];
}

function message_box(string $message, string $type = 'info'): array
{
    return ['text' => $message, 'type' => $type];
}

$controlTarget = '';
$favLabel = '';
$favTarget = '';
$favDescription = '';
$detailsMessage = message_box('Ready.', 'info');
$lastResult = null;
$showLastCommandOutput = false;

$favoritesWritable = ensure_favorites_file(FAVORITES_FILE);
$favorites = read_favorites(FAVORITES_FILE);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $postAction = trim((string) ($_POST['post_action'] ?? ''));
    $controlTarget = safe_target($_POST['control_target'] ?? '');
    $favLabel = safe_text($_POST['fav_label'] ?? '', 80);
    $favTarget = safe_target($_POST['fav_target'] ?? '');
    $favDescription = safe_text($_POST['fav_description'] ?? '', 160);
    $rowIndex = isset($_POST['row_index']) ? (int) $_POST['row_index'] : -1;

    switch ($postAction) {
        case 'start':
            if ($controlTarget === '') {
                $lastResult = ['ok' => false, 'output' => ['Enter a talkgroup or private target before pressing Start.']];
                $showLastCommandOutput = true;
                $detailsMessage = message_box('Start: Enter a talkgroup or private target first.', 'error');
            } else {
                $_SESSION['stfu_last_target'] = $controlTarget;
                $lastResult = run_command('sudo /usr/local/bin/bm-stfu.sh start ' . escapeshellarg($controlTarget));
                $showLastCommandOutput = true;
                $detailsMessage = message_box($lastResult['ok'] ? ('Start: Started ' . $controlTarget . '.') : 'Start returned an error.', $lastResult['ok'] ? 'success' : 'error');
            }
            break;

        case 'tune':
            $currentShown = safe_target((string) ($_SESSION['stfu_last_target'] ?? ''));
            if ($controlTarget === '') {
                $lastResult = ['ok' => false, 'output' => ['Start a talkgroup first, then use Change TG.']];
                $showLastCommandOutput = true;
                $detailsMessage = message_box('Change TG: Start a talkgroup first, then use Change TG.', 'error');
            } elseif ($currentShown === '') {
                $lastResult = ['ok' => false, 'output' => ['Start a talkgroup first, then use Change TG.']];
                $showLastCommandOutput = true;
                $detailsMessage = message_box('Change TG: Start a talkgroup first, then use Change TG.', 'error');
            } elseif ($controlTarget === $currentShown) {
                $lastResult = ['ok' => false, 'output' => ['Change TG needs a different target than the one already shown here.']];
                $showLastCommandOutput = true;
                $detailsMessage = message_box('Change TG: Enter a different target than the one already shown here.', 'error');
            } else {
                $_SESSION['stfu_last_target'] = $controlTarget;
                $lastResult = run_command('sudo /usr/local/bin/bm-stfu.sh tune ' . escapeshellarg($controlTarget));
                $showLastCommandOutput = true;
                $detailsMessage = message_box($lastResult['ok'] ? ('Change TG: Tuned to ' . $controlTarget . '.') : 'Change TG returned an error.', $lastResult['ok'] ? 'success' : 'error');
            }
            break;

        case 'refresh':
            $lastResult = run_command(STATUS_CMD);
            $showLastCommandOutput = false;
            $detailsMessage = message_box('Status refreshed.', 'info');
            break;

        case 'stop':
            $lastResult = run_command('sudo /usr/local/bin/bm-stfu.sh stop');
            $showLastCommandOutput = true;
            unset($_SESSION['stfu_last_target']);
            $detailsMessage = message_box($lastResult['ok'] ? 'Stop: Stopped STFU.' : 'Stop returned an error.', $lastResult['ok'] ? 'success' : 'error');
            break;

        case 'save_favorite':
            if (!$favoritesWritable) {
                $detailsMessage = message_box('Favorites file is not writable: ' . FAVORITES_FILE, 'error');
                break;
            }
            if ($favTarget === '') {
                $detailsMessage = message_box('Save Favorite: Enter a Favorite Target such as 91 or 3220008#.', 'error');
                break;
            }
            if ($favLabel === '') {
                $detailsMessage = message_box('Save Favorite: Enter a Station Name / Label.', 'error');
                break;
            }

            $updated = false;
            foreach ($favorites as $i => $favorite) {
                if (($favorite['target'] ?? '') === $favTarget) {
                    $favorites[$i] = ['target' => $favTarget, 'label' => $favLabel, 'description' => $favDescription];
                    $updated = true;
                    break;
                }
            }
            if (!$updated) {
                $favorites[] = ['target' => $favTarget, 'label' => $favLabel, 'description' => $favDescription];
            }

            if (write_favorites(FAVORITES_FILE, $favorites)) {
                $favorites = read_favorites(FAVORITES_FILE);
                $detailsMessage = message_box(($updated ? 'Updated favorite: ' : 'Saved favorite: ') . $favLabel . ' (' . $favTarget . ').', 'success');
                $favLabel = '';
                $favTarget = '';
                $favDescription = '';
            } else {
                $detailsMessage = message_box('Could not write favorites file: ' . FAVORITES_FILE, 'error');
            }
            break;

        case 'load_favorite':
            if (!isset($favorites[$rowIndex])) {
                $detailsMessage = message_box('Load Favorite: Select a valid saved favorite.', 'error');
                break;
            }
            $favorite = $favorites[$rowIndex];
            $controlTarget = $favorite['target'];
            $favLabel = '';
            $favTarget = '';
            $favDescription = '';
            $detailsMessage = message_box('Loaded favorite into the control field: ' . $favorite['label'] . ' (' . $favorite['target'] . ').', 'success');
            break;

        case 'delete_favorite':
            if (!$favoritesWritable) {
                $detailsMessage = message_box('Favorites file is not writable: ' . FAVORITES_FILE, 'error');
                break;
            }
            if (!isset($favorites[$rowIndex])) {
                $detailsMessage = message_box('Delete Favorite: Select a valid saved favorite.', 'error');
                break;
            }
            $removed = $favorites[$rowIndex];
            array_splice($favorites, $rowIndex, 1);
            if (write_favorites(FAVORITES_FILE, $favorites)) {
                $favorites = read_favorites(FAVORITES_FILE);
                $detailsMessage = message_box('Deleted favorite: ' . $removed['label'] . ' (' . $removed['target'] . ').', 'success');
                $favTarget = '';
                $favLabel = '';
                $favDescription = '';
            } else {
                $detailsMessage = message_box('Could not write favorites file: ' . FAVORITES_FILE, 'error');
            }
            break;
    }
}

$statusResult = run_command(STATUS_CMD);
$parsedStatus = parse_status($statusResult);
if ($controlTarget === '' && $parsedStatus['current_target'] !== '') {
    $controlTarget = $parsedStatus['current_target'];
}

$isActive = $parsedStatus['mode'] === 'Active';

function h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>STFU Control</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        :root {
            --bg-main: #0f0a14;
            --bg-panel: #1b1125;
            --bg-panel-2: #211430;
            --bg-header: #4a2662;
            --bg-input: #090b10;
            --bg-button: #8a0d8c;
            --bg-button-hover: #a014a2;
            --bg-danger: #8d120b;
            --bg-danger-hover: #a71711;
            --border-main: #5c3577;
            --border-soft: #43304f;
            --border-button: #db71ef;
            --text-main: #e0d7eb;
            --text-soft: #b9aaca;
            --pink: #d86cf2;
            --green: #1cff53;
            --gold: #ffd75c;
            --red: #ff9a9a;
            --blue: #72b6ff;
            --shadow: 0 14px 34px rgba(0, 0, 0, 0.26);
            --radius-card: 18px;
            --radius-control: 12px;
            --content-width: 1180px;
        }
        * { box-sizing: border-box; }
        html, body {
            margin: 0; padding: 0; background: var(--bg-main); color: var(--text-main);
            font-family: "Segoe UI", Tahoma, Arial, sans-serif;
        }
        body { padding: 6px 8px 10px; }
        .page { max-width: var(--content-width); margin: 0 auto; }
        .topbar, .card {
            background: var(--bg-panel);
            border: 1px solid var(--border-main);
            border-radius: var(--radius-card);
            box-shadow: var(--shadow);
        }
        .topbar { padding: 10px 14px; margin-bottom: 10px; text-align: center; }
        .title {
            display: inline-block; margin: 0; padding: 4px 16px; font-size: 1rem; font-weight: 700; color: #fff;
            background: linear-gradient(180deg, #6a2f8d 0%, #4a2662 100%); border: 1px solid #7d4aa0;
            border-radius: 999px; box-shadow: 0 4px 14px rgba(0, 0, 0, 0.22);
        }
        .subtitle { margin: 8px 0 0; color: var(--text-soft); font-size: 0.86rem; }
        .grid { display: grid; gap: 8px; }
        .card-header {
            background: var(--bg-header); color: #fff; padding: 8px 12px; font-size: 0.78rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.05em; border-radius: 18px 18px 0 0;
        }
        .card-body { padding: 8px; }
        .status-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px; gap: 8px; }
        .headline { margin: 0; font-size: 0.95rem; font-weight: 700; }
        .badge {
            display: inline-flex; align-items: center; min-height: 28px; padding: 0 11px; border-radius: 999px;
            border: 1px solid rgba(216, 108, 242, 0.28); background: rgba(216, 108, 242, 0.12);
            color: var(--pink); font-weight: 700; font-size: 0.82rem;
        }
        .badge-on { background: rgba(28,255,83,0.1); color: var(--green); border-color: rgba(28,255,83,0.28); }
        .badge-off { background: rgba(255,154,154,0.08); color: var(--red); border-color: rgba(255,154,154,0.24); }
        .status-grid, .add-grid {
            display: grid; gap: 6px;
        }
        .status-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
        .add-grid { grid-template-columns: 1.2fr 1fr 1.2fr auto; align-items: end; }
        .status-item {
            background: var(--bg-panel-2); border: 1px solid var(--border-soft); border-radius: 12px; padding: 8px;
        }
        .status-label, .label {
            display: block; margin: 0 0 4px; color: var(--text-soft); font-size: 0.76rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.04em;
        }
        .status-value { margin: 0; font-size: 0.95rem; font-weight: 700; color: var(--text-main); }
        .status-note { margin: 4px 0 0; font-size: 0.78rem; color: var(--text-soft); }
        .value-good { color: var(--green); }
        .value-bad { color: var(--red); }
        .control, textarea {
            width: 100%; border-radius: var(--radius-control); border: 1px solid var(--border-soft);
            background: var(--bg-input); color: var(--green); font-size: 0.95rem; padding: 8px 10px; outline: none;
        }
        .control { height: 36px; }
        textarea { min-height: 40px; resize: vertical; color: var(--text-main); }
        .control:focus, textarea:focus {
            border-color: var(--pink); box-shadow: 0 0 0 3px rgba(216,108,242,0.12);
        }
        .button-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 6px; }
        .btn {
            display: inline-flex; align-items: center; justify-content: center; min-height: 34px; padding: 0 12px;
            border-radius: 11px; border: 1px solid transparent; font-size: 0.82rem; font-weight: 700;
            letter-spacing: 0.03em; text-transform: uppercase; cursor: pointer;
            transition: background 0.15s ease, border-color 0.15s ease, transform 0.15s ease, opacity 0.15s ease;
        }
        .btn:hover { transform: translateY(-1px); }
        .btn-primary { background: var(--bg-button); border-color: var(--border-button); color: #fff; }
        .btn-primary:hover { background: var(--bg-button-hover); }
        .btn-danger { background: var(--bg-danger); border-color: #c6281e; color: #ffd0d0; }
        .btn-danger:hover { background: var(--bg-danger-hover); }
        .btn-blue { background: #294f90; border-color: #6ea8ff; color: #fff; }
        .btn-blue:hover { background: #3260ac; }
        .btn:disabled {
            opacity: 0.45;
            cursor: not-allowed;
            transform: none;
            filter: grayscale(0.15);
        }
        .help, .meta { margin: 6px 0 0; color: var(--text-soft); font-size: 0.82rem; line-height: 1.35; }
        .message {
            background: var(--bg-panel-2); border: 1px solid var(--border-soft); border-radius: 12px; padding: 8px 10px;
            font-size: 0.9rem; line-height: 1.35;
        }
        .message.success { border-color: rgba(28,255,83,0.28); }
        .message.error { border-color: rgba(255,154,154,0.24); color: #ffd0d0; }
        .table-wrap { border: 1px solid var(--border-soft); border-radius: 12px; overflow: hidden; }
        .favorites-scroll { max-height: 220px; overflow-y: auto; }
        .favorites-scroll thead th { position: sticky; top: 0; z-index: 1; }
        table { width: 100%; border-collapse: collapse; }
        thead th {
            background: linear-gradient(180deg, #6a2f8d 0%, #4a2662 100%); color: #f1d3ff; text-align: left;
            font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.04em; padding: 5px 8px;
        }
        tbody td { padding: 4px 8px; border-top: 1px solid #3a234a; font-size: 0.82rem; line-height: 1.15; vertical-align: middle; }
        tbody tr:nth-child(odd) { background: rgba(255,255,255,0.01); }
        .row-actions { display: flex; gap: 5px; justify-content: flex-end; }
        .row-actions .btn { min-height: 28px; padding: 0 10px; font-size: 0.76rem; border-radius: 9px; }
        details { margin-top: 6px; background: rgba(0,0,0,0.14); border: 1px solid var(--border-soft); border-radius: 12px; padding: 6px 8px; }
        summary { cursor: pointer; font-weight: 700; color: var(--pink); }
        pre {
            margin: 8px 0 0; white-space: pre-wrap; word-break: break-word; color: var(--text-main);
            font-size: 0.86rem; line-height: 1.4; font-family: Consolas, "Courier New", monospace;
        }
        @media (max-width: 980px) {
            .status-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .add-grid { grid-template-columns: 1fr 1fr; }
        }
        @media (max-width: 720px) {
            .button-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .status-grid, .add-grid { grid-template-columns: 1fr; }
            .row-actions { flex-direction: column; }
        }
    </style>
</head>
<body>
<div class="page">
    <div class="topbar">
        <h1 class="title">STFU Control</h1>
        <p class="subtitle">Simple web control for Start, Change TG, Stop, and Status.</p>
    </div>

    <div class="grid">
        <section class="card">
            <div class="card-header">Current Status</div>
            <div class="card-body">
                <div class="status-top">
                    <p class="headline"><?= h($parsedStatus['headline']) ?></p>
                    <div class="<?= h($parsedStatus['badge_class']) ?>"><?= h($parsedStatus['mode']) ?></div>
                </div>
                <div class="status-grid">
                    <div class="status-item">
                        <span class="status-label">Mode</span>
                        <p class="status-value <?= $parsedStatus['mode'] === 'Active' ? 'value-good' : '' ?>"><?= h($parsedStatus['mode']) ?></p>
                    </div>
                    <div class="status-item">
                        <span class="status-label">Current TG</span>
                        <p class="status-value"><?= h($parsedStatus['current_target']) ?></p>
                        <?php if ($parsedStatus['current_target'] !== ''): ?>
                            <p class="status-note">From panel memory.</p>
                        <?php endif; ?>
                    </div>
                    <div class="status-item">
                        <span class="status-label">Bridge</span>
                        <p class="status-value <?= h($parsedStatus['bridge_class']) ?>"><?= h($parsedStatus['bridge']) ?></p>
                    </div>
                    <div class="status-item">
                        <span class="status-label">Backend</span>
                        <p class="status-value <?= h($parsedStatus['backend_class']) ?>"><?= h($parsedStatus['backend']) ?></p>
                    </div>
                </div>
            </div>
        </section>

        <section class="card">
            <div class="card-header">Control</div>
            <div class="card-body">
                <form method="post" class="grid">
                    <input type="hidden" name="fav_label" value="">
                    <input type="hidden" name="fav_target" value="">
                    <input type="hidden" name="fav_description" value="">
                    <div>
                        <label class="label" for="control_target">Talkgroup / Private Target</label>
                        <input class="control" type="text" id="control_target" name="control_target" value="<?= h($controlTarget) ?>" placeholder="91, 3100, 3220008, or 3220008#">
                    </div>
                    <div class="button-grid">
                        <button class="btn btn-primary" type="submit" name="post_action" value="start" <?= $isActive ? 'disabled' : '' ?>>Start</button>
                        <button class="btn btn-primary" type="submit" name="post_action" value="tune" <?= $isActive ? '' : 'disabled' ?>>Change TG</button>
                        <button class="btn btn-blue" type="submit" name="post_action" value="refresh">Refresh Status</button>
                        <button class="btn btn-danger" type="submit" name="post_action" value="stop">Stop</button>
                    </div>
                </form>
                <p class="help">Start and Change TG use the target field. A private call target may end with #.</p>
            </div>
        </section>

        <section class="card">
            <div class="card-header">Add Favorite</div>
            <div class="card-body">
                <form method="post" class="add-grid" autocomplete="off">
                    <input type="hidden" name="control_target" value="<?= h($controlTarget) ?>">
                    <div>
                        <label class="label" for="fav_target">TG / Private TG</label>
                        <input class="control" type="text" id="fav_target" name="fav_target" value="<?= h($favTarget) ?>" autocomplete="off">
                    </div>
                    <div>
                        <label class="label" for="fav_label">Station Name / Label</label>
                        <input class="control" type="text" id="fav_label" name="fav_label" value="<?= h($favLabel) ?>" autocomplete="off">
                    </div>
                    <div>
                        <label class="label" for="fav_description">Description</label>
                        <input class="control" type="text" id="fav_description" name="fav_description" value="<?= h($favDescription) ?>" autocomplete="off">
                    </div>
                    <div>
                        <button class="btn btn-primary" style="width:100%;" type="submit" name="post_action" value="save_favorite">Save Favorite</button>
                    </div>
                </form>
                <p class="meta">Favorites file: <?= h(FAVORITES_FILE) ?></p>
            </div>
        </section>

        <section class="card">
            <div class="card-header">Saved Favorites</div>
            <div class="card-body">
                <?php if ($favorites === []): ?>
                    <div class="message">No saved favorites yet.</div>
                <?php else: ?>
                    <p class="meta">Shows about 5 favorites at a time. Scroll for more.</p>
                    <div class="table-wrap favorites-scroll">
                        <table>
                            <thead>
                                <tr>
                                    <th style="width:16%;">Target</th>
                                    <th style="width:22%;">Station Name</th>
                                    <th>Description</th>
                                    <th style="width:125px; text-align:right;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php foreach ($favorites as $index => $favorite): ?>
                                <tr>
                                    <td><?= h($favorite['target']) ?></td>
                                    <td><?= h($favorite['label']) ?></td>
                                    <td><?= h($favorite['description']) ?></td>
                                    <td>
                                        <div class="row-actions">
                                            <form method="post">
                                                <input type="hidden" name="control_target" value="<?= h($controlTarget) ?>">
                                                <input type="hidden" name="fav_label" value="">
                                                <input type="hidden" name="fav_target" value="">
                                                <input type="hidden" name="fav_description" value="">
                                                <input type="hidden" name="row_index" value="<?= $index ?>">
                                                <button class="btn btn-blue" type="submit" name="post_action" value="load_favorite">Load</button>
                                            </form>
                                            <form method="post" onsubmit="return confirm('Delete this favorite?');">
                                                <input type="hidden" name="control_target" value="<?= h($controlTarget) ?>">
                                                <input type="hidden" name="fav_label" value="">
                                                <input type="hidden" name="fav_target" value="">
                                                <input type="hidden" name="fav_description" value="">
                                                <input type="hidden" name="row_index" value="<?= $index ?>">
                                                <button class="btn btn-danger" type="submit" name="post_action" value="delete_favorite">Delete</button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </section>

        <section class="card">
            <div class="card-header">Details</div>
            <div class="card-body">
                <div class="message <?= h($detailsMessage['type']) ?>"><?= h($detailsMessage['text']) ?></div>
                <details>
                    <summary>Backend status</summary>
                    <pre><?= h(implode("\n", $parsedStatus['raw_lines'])) ?></pre>
                </details>
                <?php if (is_array($lastResult) && $showLastCommandOutput): ?>
                    <details>
                        <summary>Last command output</summary>
                        <pre><?= h(implode("\n", clean_lines($lastResult['output'] ?? []))) ?></pre>
                    </details>
                <?php endif; ?>
            </div>
        </section>
    </div>
</div>
</body>
</html>
