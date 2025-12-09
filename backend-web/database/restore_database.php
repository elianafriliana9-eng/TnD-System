<?php
/**
 * Database Restore Script
 * 
 * This script restores a database from a backup file.
 * 
 * Usage:
 * php restore_database.php backup_file.sql
 * php restore_database.php backup_file.sql.gz (will decompress automatically)
 * 
 * WARNING: This will overwrite existing data!
 */

// Load environment configuration
require_once __DIR__ . '/../config/env.php';

use TND\Config\Env;

// Check if backup file provided
if ($argc < 2) {
    echo "Usage: php restore_database.php <backup_file>\n";
    echo "Example: php restore_database.php backups/tnd_system_backup_2025-10-28_14-30-00.sql\n";
    exit(1);
}

$backupFile = $argv[1];

// Check if file exists
if (!file_exists($backupFile)) {
    echo "✗ Error: Backup file not found: {$backupFile}\n";
    exit(1);
}

// Configuration
$dbHost = Env::get('DB_HOST', '127.0.0.1');
$dbName = Env::get('DB_NAME', 'tnd_system');
$dbUser = Env::get('DB_USERNAME', 'root');
$dbPass = Env::get('DB_PASSWORD', '');

echo "========================================\n";
echo "Database Restore\n";
echo "========================================\n";
echo "Database: {$dbName}\n";
echo "Backup file: {$backupFile}\n";
echo "File size: " . round(filesize($backupFile) / 1024 / 1024, 2) . " MB\n";
echo "\n";

// Confirm restore
echo "⚠ WARNING: This will OVERWRITE all existing data in '{$dbName}' database!\n";
echo "Are you sure you want to continue? (yes/no): ";
$handle = fopen("php://stdin", "r");
$line = trim(fgets($handle));
fclose($handle);

if ($line !== 'yes') {
    echo "Restore cancelled.\n";
    exit(0);
}

// Decompress if .gz file
$sqlFile = $backupFile;
if (substr($backupFile, -3) === '.gz') {
    echo "Decompressing backup file...\n";
    $sqlFile = substr($backupFile, 0, -3);
    
    exec("gunzip -c {$backupFile} > {$sqlFile}", $output, $returnVar);
    
    if ($returnVar !== 0) {
        echo "✗ Decompression failed!\n";
        exit(1);
    }
    
    echo "✓ Decompression successful\n";
    $tempFile = true; // Mark for deletion after restore
}

// Build mysql restore command
$command = sprintf(
    'mysql --host=%s --user=%s --password=%s %s < %s',
    escapeshellarg($dbHost),
    escapeshellarg($dbUser),
    escapeshellarg($dbPass),
    escapeshellarg($dbName),
    escapeshellarg($sqlFile)
);

// Execute restore
echo "Restoring database...\n";

exec($command, $output, $returnVar);

// Clean up temporary decompressed file if needed
if (isset($tempFile) && file_exists($sqlFile)) {
    unlink($sqlFile);
}

if ($returnVar === 0) {
    echo "✓ Database restore successful!\n";
    echo "\nDatabase '{$dbName}' has been restored from backup.\n";
} else {
    echo "✗ Database restore failed!\n";
    echo "Output: " . implode("\n", $output) . "\n";
    exit(1);
}
