<?php
/**
 * Database Migration Runner for Training Module
 * Run this file via browser: http://localhost/tnd_system/backend-web/database/run_migration.php
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../classes/Database.php';

header('Content-Type: text/html; charset=utf-8');
echo "<h1>Training Module - Database Migration</h1>";
echo "<hr>";

try {
    $db = Database::getInstance()->getConnection();
    
    // Read migration file
    $migrationFile = __DIR__ . '/migrations/create_training_tables.sql';
    
    if (!file_exists($migrationFile)) {
        throw new Exception("Migration file not found: $migrationFile");
    }
    
    $sql = file_get_contents($migrationFile);
    
    // Split by semicolon and execute each statement
    $statements = explode(';', $sql);
    
    echo "<h2>Executing Migration...</h2>";
    echo "<pre>";
    
    $successCount = 0;
    $errorCount = 0;
    
    foreach ($statements as $statement) {
        $statement = trim($statement);
        
        // Skip empty statements and comments
        if (empty($statement) || substr($statement, 0, 2) === '--') {
            continue;
        }
        
        try {
            $db->exec($statement);
            $successCount++;
            
            // Show statement summary
            if (stripos($statement, 'CREATE TABLE') !== false) {
                preg_match('/CREATE TABLE.*?`?(\w+)`?/i', $statement, $matches);
                echo "✓ Created table: " . ($matches[1] ?? 'unknown') . "\n";
            } elseif (stripos($statement, 'ALTER TABLE') !== false) {
                preg_match('/ALTER TABLE.*?`?(\w+)`?/i', $statement, $matches);
                echo "✓ Altered table: " . ($matches[1] ?? 'unknown') . "\n";
            } elseif (stripos($statement, 'CREATE INDEX') !== false) {
                echo "✓ Created index\n";
            }
            
        } catch (PDOException $e) {
            $errorCount++;
            echo "✗ Error: " . $e->getMessage() . "\n";
            // Continue with other statements
        }
    }
    
    echo "</pre>";
    echo "<hr>";
    echo "<h2>Migration Summary:</h2>";
    echo "<p>✓ Successful statements: <strong>$successCount</strong></p>";
    echo "<p>✗ Failed statements: <strong>$errorCount</strong></p>";
    
    if ($errorCount === 0) {
        echo "<h3 style='color: green;'>✓ Migration completed successfully!</h3>";
        
        // Verify tables
        echo "<hr>";
        echo "<h2>Verifying Tables:</h2>";
        echo "<ul>";
        
        $tables = [
            'training_checklists',
            'training_categories',
            'training_points',
            'training_sessions',
            'training_participants',
            'training_responses',
            'training_photos'
        ];
        
        foreach ($tables as $table) {
            $stmt = $db->query("SHOW TABLES LIKE '$table'");
            if ($stmt->rowCount() > 0) {
                echo "<li style='color: green;'>✓ Table <strong>$table</strong> exists</li>";
            } else {
                echo "<li style='color: red;'>✗ Table <strong>$table</strong> not found</li>";
            }
        }
        
        echo "</ul>";
        
        // Show next step
        echo "<hr>";
        echo "<h2>Next Step:</h2>";
        echo "<p>Run seed data: <a href='run_seed.php'>Click here to seed sample data</a></p>";
        
    } else {
        echo "<h3 style='color: orange;'>⚠ Migration completed with some errors</h3>";
    }
    
} catch (Exception $e) {
    echo "<h3 style='color: red;'>✗ Migration Failed!</h3>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<p><a href='../../'>Back to Home</a></p>";
?>
