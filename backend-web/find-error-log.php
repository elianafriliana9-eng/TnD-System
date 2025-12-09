<?php
/**
 * Comprehensive error log checker - reads from multiple possible locations
 */

header('Content-Type: text/plain; charset=utf-8');

echo "=== COMPREHENSIVE ERROR LOG CHECK ===\n\n";

// All possible error log locations
$possibleLogs = [
    'Current dir' => __DIR__ . '/error_log',
    'Parent dir' => dirname(__DIR__) . '/error_log',
    'Home dir' => $_SERVER['HOME'] . '/public_html/error_log',
    'PHP ini setting' => ini_get('error_log'),
    'Apache error log' => '/var/log/apache2/error.log',
    'Logs directory' => __DIR__ . '/logs/error.log',
];

echo "Searching in common locations:\n";
echo str_repeat("-", 80) . "\n";

foreach ($possibleLogs as $name => $path) {
    if (empty($path)) {
        echo "[$name]: Path not set\n";
        continue;
    }
    
    echo "[$name]: $path\n";
    
    if (file_exists($path) && is_readable($path)) {
        echo "  ✅ FOUND and READABLE!\n";
        echo "  Size: " . number_format(filesize($path)) . " bytes\n";
        echo "  Modified: " . date('Y-m-d H:i:s', filemtime($path)) . "\n\n";
        
        // Read last 150 lines
        echo str_repeat("=", 80) . "\n";
        echo "LAST 150 LINES FROM: $name\n";
        echo str_repeat("=", 80) . "\n\n";
        
        $lines = file($path);
        $total = count($lines);
        $start = max(0, $total - 150);
        $lastLines = array_slice($lines, $start);
        
        foreach ($lastLines as $lineNum => $line) {
            $actualLineNum = $start + $lineNum + 1;
            echo "[$actualLineNum] $line";
        }
        
        echo "\n" . str_repeat("=", 80) . "\n";
        echo "END OF LOG ($name)\n";
        echo str_repeat("=", 80) . "\n\n";
        
        // Found one, that's enough
        exit;
    } else {
        if (file_exists($path)) {
            echo "  ❌ EXISTS but NOT READABLE\n";
        } else {
            echo "  ❌ NOT FOUND\n";
        }
    }
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "NO ERROR LOG FOUND IN ANY LOCATION\n";
echo str_repeat("=", 80) . "\n\n";

echo "PHP Error Settings:\n";
echo "  display_errors: " . ini_get('display_errors') . "\n";
echo "  error_reporting: " . ini_get('error_reporting') . "\n";
echo "  log_errors: " . ini_get('log_errors') . "\n";
echo "  error_log: " . ini_get('error_log') . "\n";

echo "\nServer Info:\n";
echo "  PHP Version: " . PHP_VERSION . "\n";
echo "  Server Software: " . ($_SERVER['SERVER_SOFTWARE'] ?? 'Unknown') . "\n";
echo "  Document Root: " . ($_SERVER['DOCUMENT_ROOT'] ?? 'Unknown') . "\n";
echo "  Script Filename: " . __FILE__ . "\n";
echo "  Current User: " . get_current_user() . "\n";
echo "  Home Dir: " . ($_SERVER['HOME'] ?? 'Not set') . "\n";

// Try to list directory
echo "\nFiles in current directory:\n";
$files = scandir(__DIR__);
foreach ($files as $file) {
    if ($file === 'error_log' || $file === 'php_error.log' || $file === 'errors.log') {
        echo "  ⚠️  $file (ERROR LOG CANDIDATE)\n";
    }
}
?>
