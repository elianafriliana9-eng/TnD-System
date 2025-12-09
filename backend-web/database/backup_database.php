<?php
/**
 * Database Backup Script
 * 
 * This script creates a backup of the database and saves it to the backups directory.
 * Can be run manually or via cron job.
 * 
 * Usage:
 * - Manual: php backup_database.php
 * - Cron (daily at 2 AM): 0 2 * * * cd /path/to/backend-web/database && php backup_database.php
 */

// Load environment configuration
require_once __DIR__ . '/../config/env.php';

use TND\Config\Env;

// Configuration
$dbHost = Env::get('DB_HOST', '127.0.0.1');
$dbName = Env::get('DB_NAME', 'tnd_system');
$dbUser = Env::get('DB_USERNAME', 'root');
$dbPass = Env::get('DB_PASSWORD', '');

$backupDir = __DIR__ . '/backups';
$timestamp = date('Y-m-d_H-i-s');
$backupFile = "{$backupDir}/tnd_system_backup_{$timestamp}.sql";

// Create backup directory if it doesn't exist
if (!is_dir($backupDir)) {
    mkdir($backupDir, 0755, true);
}

// Build mysqldump command
$command = sprintf(
    'mysqldump --host=%s --user=%s --password=%s %s > %s',
    escapeshellarg($dbHost),
    escapeshellarg($dbUser),
    escapeshellarg($dbPass),
    escapeshellarg($dbName),
    escapeshellarg($backupFile)
);

// Execute backup
echo "Creating database backup...\n";
echo "Backup file: {$backupFile}\n";

exec($command, $output, $returnVar);

if ($returnVar === 0) {
    echo "✓ Backup successful!\n";
    echo "File size: " . round(filesize($backupFile) / 1024 / 1024, 2) . " MB\n";
    
    // Compress backup (optional)
    echo "Compressing backup...\n";
    exec("gzip {$backupFile}", $output, $returnVar);
    
    if ($returnVar === 0) {
        echo "✓ Compression successful!\n";
        echo "Compressed file: {$backupFile}.gz\n";
    } else {
        echo "⚠ Compression failed, but SQL backup is available\n";
    }
    
    // Clean old backups (keep last 7 days)
    echo "Cleaning old backups...\n";
    $files = glob("{$backupDir}/tnd_system_backup_*.sql.gz");
    $files = array_merge($files, glob("{$backupDir}/tnd_system_backup_*.sql"));
    
    if (count($files) > 7) {
        usort($files, function($a, $b) {
            return filemtime($a) - filemtime($b);
        });
        
        $filesToDelete = array_slice($files, 0, count($files) - 7);
        foreach ($filesToDelete as $file) {
            unlink($file);
            echo "Deleted old backup: " . basename($file) . "\n";
        }
    }
    
    echo "✓ Backup process completed!\n";
} else {
    echo "✗ Backup failed!\n";
    echo "Command: {$command}\n";
    echo "Output: " . implode("\n", $output) . "\n";
    exit(1);
}
