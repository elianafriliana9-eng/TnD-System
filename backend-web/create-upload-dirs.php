<?php
/**
 * Create Upload Directories for TND System
 * Run this file once via browser: https://tndsystem.online/backend-web/create-upload-dirs.php
 * Then DELETE this file after successful execution
 */

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>TND System - Create Upload Directories</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            max-width: 800px; 
            margin: 50px auto; 
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        .success { color: #28a745; background: #d4edda; padding: 12px; border-radius: 4px; margin: 10px 0; }
        .error { color: #dc3545; background: #f8d7da; padding: 12px; border-radius: 4px; margin: 10px 0; }
        .info { color: #004085; background: #cce5ff; padding: 12px; border-radius: 4px; margin: 10px 0; }
        .warning { color: #856404; background: #fff3cd; padding: 12px; border-radius: 4px; margin: 10px 0; }
        ul { list-style: none; padding: 0; }
        li { padding: 8px; margin: 5px 0; }
    </style>
</head>
<body>
<div class="container">
    <h1>🔧 TND System - Upload Directories Setup</h1>

<?php
$baseDir = __DIR__ . '/uploads';
$directories = [
    'uploads',
    'uploads/photos',
    'uploads/profile_photos',
    'uploads/training_photos',
    'uploads/temp'
];

echo "<h2>Creating Directories...</h2><ul>";

foreach ($directories as $dir) {
    $fullPath = __DIR__ . '/' . $dir;
    
    if (!file_exists($fullPath)) {
        if (mkdir($fullPath, 0755, true)) {
            echo "<li class='success'>✅ Created: <strong>$dir</strong> (permissions: 755)</li>";
        } else {
            echo "<li class='error'>❌ Failed to create: <strong>$dir</strong></li>";
        }
    } else {
        echo "<li class='info'>ℹ️ Already exists: <strong>$dir</strong></li>";
        // Set permissions anyway
        chmod($fullPath, 0755);
        echo "<li class='success'>✅ Permissions updated: <strong>$dir</strong> (755)</li>";
    }
}

echo "</ul>";

// Create .htaccess for security
$htaccessPath = $baseDir . '/.htaccess';
$htaccessContent = <<<'HTACCESS'
# Prevent PHP execution in uploads directory
<FilesMatch "\.(?i:php|php3|php4|php5|phtml|pl|py|jsp|asp|sh|cgi)$">
    Order Deny,Allow
    Deny from all
</FilesMatch>

# Allow image access
<FilesMatch "\.(jpg|jpeg|png|gif|webp)$">
    Order Allow,Deny
    Allow from all
</FilesMatch>

Options -Indexes
HTACCESS;

if (file_put_contents($htaccessPath, $htaccessContent)) {
    echo "<p class='success'>✅ Security .htaccess created in uploads/</p>";
} else {
    echo "<p class='error'>❌ Failed to create .htaccess</p>";
}

// Create index.php to prevent directory listing
$indexContent = "<?php\nheader('HTTP/1.0 403 Forbidden');\ndie('Access denied');\n";
foreach ($directories as $dir) {
    if ($dir === 'uploads') continue;
    $indexPath = __DIR__ . '/' . $dir . '/index.php';
    file_put_contents($indexPath, $indexContent);
}
echo "<p class='success'>✅ Index.php files created in subdirectories</p>";

echo "<h2>Verification:</h2><ul>";
foreach ($directories as $dir) {
    $fullPath = __DIR__ . '/' . $dir;
    $exists = file_exists($fullPath);
    $writable = is_writable($fullPath);
    $perms = substr(sprintf('%o', fileperms($fullPath)), -4);
    
    if ($exists && $writable) {
        echo "<li class='success'>✅ <strong>$dir</strong> - EXISTS, WRITABLE (perms: $perms)</li>";
    } elseif ($exists) {
        echo "<li class='warning'>⚠️ <strong>$dir</strong> - EXISTS but NOT WRITABLE (perms: $perms)</li>";
    } else {
        echo "<li class='error'>❌ <strong>$dir</strong> - DOES NOT EXIST</li>";
    }
}
echo "</ul>";

echo "<hr><div class='warning'><strong>⚠️ IMPORTANT:</strong> DELETE this file (create-upload-dirs.php) after successful setup for security!</div>";
echo "<p><a href='?' style='padding:10px 20px;background:#007bff;color:white;text-decoration:none;border-radius:5px;display:inline-block;margin-top:10px;'>Refresh to Verify</a></p>";
?>

</div>
</body>
</html>
