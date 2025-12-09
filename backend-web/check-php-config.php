<?php
/**
 * Check PHP Configuration for Upload
 * Upload this to production and access via browser
 */

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>PHP Upload Configuration Check</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .setting { display: flex; justify-content: space-between; padding: 12px; margin: 8px 0; border-radius: 4px; background: #f9f9f9; }
        .setting-name { font-weight: bold; color: #555; }
        .setting-value { color: #2196F3; font-family: monospace; }
        .ok { background: #e8f5e9; border-left: 4px solid #4CAF50; }
        .warning { background: #fff3e0; border-left: 4px solid #FF9800; }
        .error { background: #ffebee; border-left: 4px solid #f44336; }
        .section { margin: 20px 0; }
        .section-title { font-size: 18px; font-weight: bold; color: #666; margin: 15px 0 10px 0; }
        .info { padding: 10px; background: #e3f2fd; border-left: 4px solid #2196F3; border-radius: 4px; margin: 10px 0; }
        .status { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: bold; color: white; }
        .status-ok { background: #4CAF50; }
        .status-warning { background: #FF9800; }
        .status-error { background: #f44336; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 PHP Upload Configuration Check</h1>
        
        <div class="info">
            <strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?><br>
            <strong>PHP Version:</strong> <?php echo phpversion(); ?><br>
            <strong>Current Time:</strong> <?php echo date('Y-m-d H:i:s'); ?>
        </div>

        <div class="section">
            <div class="section-title">📤 Upload Settings</div>
            
            <?php
            $uploadMaxFilesize = ini_get('upload_max_filesize');
            $uploadMaxBytes = return_bytes($uploadMaxFilesize);
            $uploadStatus = $uploadMaxBytes >= 10 * 1024 * 1024 ? 'ok' : 'warning';
            ?>
            <div class="setting <?php echo $uploadStatus; ?>">
                <span class="setting-name">upload_max_filesize</span>
                <span class="setting-value">
                    <?php echo $uploadMaxFilesize; ?> (<?php echo format_bytes($uploadMaxBytes); ?>)
                    <span class="status status-<?php echo $uploadStatus; ?>">
                        <?php echo $uploadStatus === 'ok' ? 'OK' : 'TOO SMALL'; ?>
                    </span>
                </span>
            </div>

            <?php
            $postMaxSize = ini_get('post_max_size');
            $postMaxBytes = return_bytes($postMaxSize);
            $postStatus = $postMaxBytes >= 10 * 1024 * 1024 ? 'ok' : 'warning';
            ?>
            <div class="setting <?php echo $postStatus; ?>">
                <span class="setting-name">post_max_size</span>
                <span class="setting-value">
                    <?php echo $postMaxSize; ?> (<?php echo format_bytes($postMaxBytes); ?>)
                    <span class="status status-<?php echo $postStatus; ?>">
                        <?php echo $postStatus === 'ok' ? 'OK' : 'TOO SMALL'; ?>
                    </span>
                </span>
            </div>

            <?php
            $maxExecutionTime = ini_get('max_execution_time');
            $execStatus = $maxExecutionTime >= 60 ? 'ok' : 'warning';
            ?>
            <div class="setting <?php echo $execStatus; ?>">
                <span class="setting-name">max_execution_time</span>
                <span class="setting-value">
                    <?php echo $maxExecutionTime; ?> seconds
                    <span class="status status-<?php echo $execStatus; ?>">
                        <?php echo $execStatus === 'ok' ? 'OK' : 'LOW'; ?>
                    </span>
                </span>
            </div>

            <?php
            $maxInputTime = ini_get('max_input_time');
            $inputStatus = $maxInputTime >= 60 ? 'ok' : 'warning';
            ?>
            <div class="setting <?php echo $inputStatus; ?>">
                <span class="setting-name">max_input_time</span>
                <span class="setting-value">
                    <?php echo $maxInputTime; ?> seconds
                    <span class="status status-<?php echo $inputStatus; ?>">
                        <?php echo $inputStatus === 'ok' ? 'OK' : 'LOW'; ?>
                    </span>
                </span>
            </div>

            <?php
            $memoryLimit = ini_get('memory_limit');
            $memoryBytes = return_bytes($memoryLimit);
            $memoryStatus = $memoryBytes >= 128 * 1024 * 1024 ? 'ok' : 'warning';
            ?>
            <div class="setting <?php echo $memoryStatus; ?>">
                <span class="setting-name">memory_limit</span>
                <span class="setting-value">
                    <?php echo $memoryLimit; ?> (<?php echo format_bytes($memoryBytes); ?>)
                    <span class="status status-<?php echo $memoryStatus; ?>">
                        <?php echo $memoryStatus === 'ok' ? 'OK' : 'LOW'; ?>
                    </span>
                </span>
            </div>
        </div>

        <div class="section">
            <div class="section-title">📁 File Upload Settings</div>
            
            <div class="setting <?php echo ini_get('file_uploads') ? 'ok' : 'error'; ?>">
                <span class="setting-name">file_uploads</span>
                <span class="setting-value">
                    <?php echo ini_get('file_uploads') ? 'Enabled' : 'DISABLED'; ?>
                    <span class="status status-<?php echo ini_get('file_uploads') ? 'ok' : 'error'; ?>">
                        <?php echo ini_get('file_uploads') ? 'ON' : 'OFF'; ?>
                    </span>
                </span>
            </div>

            <div class="setting ok">
                <span class="setting-name">upload_tmp_dir</span>
                <span class="setting-value">
                    <?php 
                    $tmpDir = ini_get('upload_tmp_dir');
                    echo $tmpDir ?: sys_get_temp_dir() . ' (system default)';
                    ?>
                </span>
            </div>

            <div class="setting ok">
                <span class="setting-name">max_file_uploads</span>
                <span class="setting-value"><?php echo ini_get('max_file_uploads'); ?> files</span>
            </div>
        </div>

        <div class="section">
            <div class="section-title">✅ Recommendations</div>
            
            <?php
            $recommendations = [];
            
            if ($uploadMaxBytes < 10 * 1024 * 1024) {
                $recommendations[] = [
                    'type' => 'warning',
                    'message' => '<strong>upload_max_filesize</strong> should be at least <strong>10M</strong> for photo uploads. Current: ' . $uploadMaxFilesize
                ];
            }
            
            if ($postMaxBytes < 10 * 1024 * 1024) {
                $recommendations[] = [
                    'type' => 'warning',
                    'message' => '<strong>post_max_size</strong> should be at least <strong>10M</strong>. Current: ' . $postMaxSize
                ];
            }
            
            if ($postMaxBytes < $uploadMaxBytes) {
                $recommendations[] = [
                    'type' => 'error',
                    'message' => '<strong>post_max_size</strong> (' . $postMaxSize . ') must be larger than <strong>upload_max_filesize</strong> (' . $uploadMaxFilesize . ')'
                ];
            }
            
            if (!ini_get('file_uploads')) {
                $recommendations[] = [
                    'type' => 'error',
                    'message' => '<strong>file_uploads</strong> is DISABLED! Cannot upload files.'
                ];
            }
            
            if (empty($recommendations)) {
                echo '<div class="setting ok">';
                echo '<span style="color: #4CAF50; font-weight: bold;">✅ All settings look good!</span>';
                echo '</div>';
            } else {
                foreach ($recommendations as $rec) {
                    echo '<div class="setting ' . $rec['type'] . '">';
                    echo '<span>' . $rec['message'] . '</span>';
                    echo '</div>';
                }
            }
            ?>
        </div>

        <div class="section">
            <div class="section-title">🔧 How to Fix (cPanel)</div>
            <div class="info">
                <strong>Step 1:</strong> Login to cPanel<br>
                <strong>Step 2:</strong> Go to <strong>Software → Select PHP Version</strong><br>
                <strong>Step 3:</strong> Click <strong>Options</strong> tab<br>
                <strong>Step 4:</strong> Set these values:<br>
                <ul>
                    <li><code>upload_max_filesize</code> = <strong>10M</strong></li>
                    <li><code>post_max_size</code> = <strong>10M</strong></li>
                    <li><code>max_execution_time</code> = <strong>300</strong></li>
                    <li><code>max_input_time</code> = <strong>300</strong></li>
                    <li><code>memory_limit</code> = <strong>128M</strong></li>
                </ul>
                <strong>Step 5:</strong> Click <strong>Save</strong><br>
                <strong>Step 6:</strong> Refresh this page to verify changes
            </div>
        </div>

        <div class="section">
            <div class="section-title">⚠️ Security Note</div>
            <div class="setting warning">
                <span>
                    <strong>IMPORTANT:</strong> Delete this file (<code>check-php-config.php</code>) after checking! 
                    It exposes server configuration information.
                </span>
            </div>
        </div>
    </div>
</body>
</html>

<?php
/**
 * Convert PHP ini size notation to bytes
 */
function return_bytes($size_str) {
    if (empty($size_str)) {
        return 0;
    }
    
    $size_str = trim($size_str);
    $unit = strtolower($size_str[strlen($size_str) - 1]);
    $value = (int) $size_str;
    
    switch ($unit) {
        case 'g':
            $value *= 1024;
        case 'm':
            $value *= 1024;
        case 'k':
            $value *= 1024;
    }
    
    return $value;
}

/**
 * Format bytes to human readable
 */
function format_bytes($bytes, $precision = 2) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');
    
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    
    $bytes /= pow(1024, $pow);
    
    return round($bytes, $precision) . ' ' . $units[$pow];
}
?>
