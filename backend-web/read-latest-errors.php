<?php
/**
 * Read latest error log entries related to photo upload
 */

header('Content-Type: text/plain; charset=utf-8');

$logPath = '/home/tnd/logs/tndsystem_online.php.error.log';

if (!file_exists($logPath)) {
    die("Error log not found at: $logPath\n");
}

echo "=== LATEST 50 LINES FROM ERROR LOG ===\n";
echo "File: $logPath\n";
echo "Size: " . number_format(filesize($logPath)) . " bytes\n";
echo "Modified: " . date('Y-m-d H:i:s', filemtime($logPath)) . "\n\n";
echo str_repeat("=", 80) . "\n\n";

$lines = file($logPath);
$lastLines = array_slice($lines, -50);

foreach ($lastLines as $line) {
    echo $line;
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "END OF LOG\n";
?>
