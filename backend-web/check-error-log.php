<?php
/**
 * Read last 100 lines of error log
 */

header('Content-Type: text/plain; charset=utf-8');

// Common error log locations
$possibleLogs = [
    __DIR__ . '/error_log',
    __DIR__ . '/../error_log',
    ini_get('error_log'),
];

echo "=== SEARCHING FOR ERROR LOGS ===\n\n";

foreach ($possibleLogs as $logPath) {
    if (empty($logPath)) continue;
    
    echo "Checking: $logPath\n";
    
    if (file_exists($logPath)) {
        echo "✅ FOUND!\n\n";
        echo str_repeat("=", 80) . "\n";
        echo "LAST 100 LINES OF ERROR LOG\n";
        echo str_repeat("=", 80) . "\n\n";
        
        $lines = file($logPath);
        $lastLines = array_slice($lines, -100);
        
        foreach ($lastLines as $line) {
            echo $line;
        }
        
        exit;
    } else {
        echo "❌ Not found\n";
    }
}

echo "\n\nNo error log found in common locations.\n";
echo "Error reporting is: " . (ini_get('display_errors') ? 'ON' : 'OFF') . "\n";
echo "Error log setting: " . ini_get('error_log') . "\n";
?>
