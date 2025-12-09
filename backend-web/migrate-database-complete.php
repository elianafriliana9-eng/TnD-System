<?php
/**
 * Complete Database Migration for TND System
 * Fixes ALL missing columns that cause photo upload and checklist response errors
 * 
 * Run this file ONCE via browser: https://tndsystem.online/backend-web/migrate-database-complete.php
 * Then DELETE this file after successful execution
 * 
 * IMPORTANT: Backup your database before running this migration!
 */

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Disable output buffering to see errors immediately
if (ob_get_level()) ob_end_clean();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/classes/Database.php';

header('Content-Type: text/html; charset=utf-8');

// Flush output immediately
if (function_exists('apache_setenv')) {
    @apache_setenv('no-gzip', '1');
}
@ini_set('zlib.output_compression', '0');
@ini_set('implicit_flush', '1');
for ($i = 0; $i < ob_get_level(); $i++) { ob_end_flush(); }
ob_implicit_flush(1);
?>
<!DOCTYPE html>
<html>
<head>
    <title>TND System - Complete Database Migration</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            max-width: 1000px; 
            margin: 30px auto; 
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #333; 
            border-bottom: 4px solid #007bff; 
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        h2 { 
            color: #555; 
            margin-top: 30px;
            padding: 10px;
            background: #f8f9fa;
            border-left: 4px solid #007bff;
        }
        .success { 
            color: #28a745; 
            background: #d4edda; 
            padding: 12px; 
            border-radius: 4px; 
            border-left: 4px solid #28a745;
            margin: 10px 0;
        }
        .error { 
            color: #dc3545; 
            background: #f8d7da; 
            padding: 12px; 
            border-radius: 4px; 
            border-left: 4px solid #dc3545;
            margin: 10px 0;
        }
        .warning { 
            color: #856404; 
            background: #fff3cd; 
            padding: 12px; 
            border-radius: 4px; 
            border-left: 4px solid #ffc107;
            margin: 10px 0;
        }
        .info { 
            color: #004085; 
            background: #cce5ff; 
            padding: 12px; 
            border-radius: 4px; 
            border-left: 4px solid #007bff;
            margin: 10px 0;
        }
        .sql-box { 
            background: #2d2d2d; 
            color: #f8f8f2;
            padding: 15px; 
            border-radius: 4px; 
            font-family: 'Consolas', 'Courier New', monospace; 
            font-size: 13px;
            overflow-x: auto;
            margin: 15px 0;
        }
        .sql-box .keyword { color: #66d9ef; }
        .sql-box .string { color: #a6e22e; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 15px 0;
            background: white;
            font-size: 14px;
        }
        th { 
            background: #007bff; 
            color: white; 
            padding: 12px; 
            text-align: left;
            font-weight: 600;
        }
        td { 
            padding: 10px; 
            border-bottom: 1px solid #dee2e6;
        }
        tr:hover { background: #f8f9fa; }
        .step { 
            margin: 20px 0; 
            padding: 20px;
            background: #f8f9fa;
            border-radius: 4px;
            border: 1px solid #dee2e6;
        }
        .step-header {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
        }
        .step-number {
            display: inline-block;
            min-width: 40px;
            height: 40px;
            background: #007bff;
            color: white;
            border-radius: 50%;
            text-align: center;
            line-height: 40px;
            font-weight: bold;
            font-size: 18px;
            margin-right: 15px;
        }
        .step-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }
        .progress {
            background: #e9ecef;
            border-radius: 4px;
            height: 30px;
            margin: 20px 0;
            overflow: hidden;
        }
        .progress-bar {
            background: linear-gradient(90deg, #007bff, #0056b3);
            height: 100%;
            text-align: center;
            line-height: 30px;
            color: white;
            font-weight: 600;
            transition: width 0.3s;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🔧 TND System - Complete Database Migration</h1>
    
    <div class="warning">
        <strong>⚠️ WARNING:</strong> This migration will add missing columns to your database tables. 
        <strong>Make sure you have a backup before proceeding!</strong>
    </div>

<?php
$totalSteps = 0;
$completedSteps = 0;
$errors = [];

echo "<!-- Starting migration... -->\n";
flush();

try {
    echo "<!-- Connecting to database... -->\n";
    flush();
    
    $db = Database::getInstance()->getConnection();
    
    if (!$db) {
        throw new Exception("Failed to connect to database");
    }
    
    echo "<!-- Database connected successfully -->\n";
    flush();
    
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // ========================================
    // STEP 1: Analyze Current Database
    // ========================================
    echo "<div class='step'>";
    echo "<div class='step-header'>";
    echo "<span class='step-number'>1</span>";
    echo "<span class='step-title'>Analyzing Current Database Structure</span>";
    echo "</div>";
    
    $tables = [
        'visit_photos' => ['checklist_item_id'],
        'visit_checklist_responses' => ['checklist_item_id']
    ];
    
    $missingColumns = [];
    
    foreach ($tables as $tableName => $requiredColumns) {
        foreach ($requiredColumns as $columnName) {
            $totalSteps++;
            $checkSql = "SELECT COUNT(*) as count 
                         FROM INFORMATION_SCHEMA.COLUMNS 
                         WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = '$tableName' 
                         AND COLUMN_NAME = '$columnName'";
            
            $stmt = $db->query($checkSql);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result['count'] == 0) {
                $missingColumns[$tableName][] = $columnName;
                echo "<div class='warning'>⚠️ Table <code>$tableName</code>: Column <code>$columnName</code> is MISSING</div>";
            } else {
                echo "<div class='info'>✅ Table <code>$tableName</code>: Column <code>$columnName</code> exists</div>";
                $completedSteps++;
            }
        }
    }
    
    echo "</div>";
    
    if (empty($missingColumns)) {
        echo "<div class='success' style='font-size: 18px; padding: 20px;'>";
        echo "✅ <strong>All columns already exist!</strong> No migration needed.";
        echo "</div>";
    } else {
        // ========================================
        // STEP 2: Add Missing Columns
        // ========================================
        echo "<div class='step'>";
        echo "<div class='step-header'>";
        echo "<span class='step-number'>2</span>";
        echo "<span class='step-title'>Adding Missing Columns</span>";
        echo "</div>";
        
        // Fix visit_photos table
        if (isset($missingColumns['visit_photos'])) {
            echo "<h3>📸 Fixing visit_photos table</h3>";
            
            $sql = "ALTER TABLE visit_photos 
                    ADD COLUMN checklist_item_id INT NULL 
                    AFTER visit_id";
            
            echo "<div class='sql-box'>" . htmlspecialchars($sql) . "</div>";
            
            try {
                $db->exec($sql);
                echo "<div class='success'>✅ Column <code>checklist_item_id</code> added to <code>visit_photos</code></div>";
                $completedSteps++;
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate column') !== false) {
                    echo "<div class='info'>ℹ️ Column already exists (safe to ignore)</div>";
                    $completedSteps++;
                } else {
                    throw $e;
                }
            }
            
            // Add foreign key
            echo "<h4>Adding foreign key constraint...</h4>";
            $fkSql = "ALTER TABLE visit_photos 
                      ADD CONSTRAINT visit_photos_checklist_fk 
                      FOREIGN KEY (checklist_item_id) 
                      REFERENCES checklist_points(id) 
                      ON DELETE SET NULL";
            
            echo "<div class='sql-box'>" . htmlspecialchars($fkSql) . "</div>";
            
            try {
                $db->exec($fkSql);
                echo "<div class='success'>✅ Foreign key constraint added</div>";
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate') !== false || strpos($e->getMessage(), 'already exists') !== false) {
                    echo "<div class='info'>ℹ️ Foreign key already exists</div>";
                } else {
                    echo "<div class='warning'>⚠️ Could not add foreign key: " . htmlspecialchars($e->getMessage()) . "</div>";
                }
            }
        }
        
        // Fix visit_checklist_responses table
        if (isset($missingColumns['visit_checklist_responses'])) {
            echo "<h3>📝 Fixing visit_checklist_responses table</h3>";
            
            $sql = "ALTER TABLE visit_checklist_responses 
                    ADD COLUMN checklist_item_id INT NOT NULL 
                    AFTER visit_id";
            
            echo "<div class='sql-box'>" . htmlspecialchars($sql) . "</div>";
            
            try {
                $db->exec($sql);
                echo "<div class='success'>✅ Column <code>checklist_item_id</code> added to <code>visit_checklist_responses</code></div>";
                $completedSteps++;
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate column') !== false) {
                    echo "<div class='info'>ℹ️ Column already exists (safe to ignore)</div>";
                    $completedSteps++;
                } else {
                    throw $e;
                }
            }
            
            // Add foreign key
            echo "<h4>Adding foreign key constraint...</h4>";
            $fkSql = "ALTER TABLE visit_checklist_responses 
                      ADD CONSTRAINT visit_checklist_responses_item_fk 
                      FOREIGN KEY (checklist_item_id) 
                      REFERENCES checklist_points(id) 
                      ON DELETE CASCADE";
            
            echo "<div class='sql-box'>" . htmlspecialchars($fkSql) . "</div>";
            
            try {
                $db->exec($fkSql);
                echo "<div class='success'>✅ Foreign key constraint added</div>";
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate') !== false || strpos($e->getMessage(), 'already exists') !== false) {
                    echo "<div class='info'>ℹ️ Foreign key already exists</div>";
                } else {
                    echo "<div class='warning'>⚠️ Could not add foreign key: " . htmlspecialchars($e->getMessage()) . "</div>";
                }
            }
        }
        
        echo "</div>";
    }
    
    // ========================================
    // STEP 3: Verify Final Structure
    // ========================================
    echo "<div class='step'>";
    echo "<div class='step-header'>";
    echo "<span class='step-number'>3</span>";
    echo "<span class='step-title'>Verifying Final Database Structure</span>";
    echo "</div>";
    
    foreach ($tables as $tableName => $columns) {
        echo "<h3>📊 Table: $tableName</h3>";
        
        $structureSql = "SELECT 
                            COLUMN_NAME,
                            DATA_TYPE,
                            IS_NULLABLE,
                            COLUMN_DEFAULT,
                            COLUMN_KEY
                         FROM INFORMATION_SCHEMA.COLUMNS
                         WHERE TABLE_SCHEMA = DATABASE()
                         AND TABLE_NAME = '$tableName'
                         ORDER BY ORDINAL_POSITION";
        
        $stmt = $db->query($structureSql);
        $tableColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "<table>";
        echo "<tr><th>Column</th><th>Type</th><th>Nullable</th><th>Default</th><th>Key</th></tr>";
        
        foreach ($tableColumns as $col) {
            $highlight = in_array($col['COLUMN_NAME'], $columns) ? ' style="background: #d4edda;"' : '';
            echo "<tr$highlight>";
            echo "<td><strong>" . htmlspecialchars($col['COLUMN_NAME']) . "</strong></td>";
            echo "<td>" . htmlspecialchars($col['DATA_TYPE']) . "</td>";
            echo "<td>" . htmlspecialchars($col['IS_NULLABLE']) . "</td>";
            echo "<td>" . htmlspecialchars($col['COLUMN_DEFAULT'] ?? 'NULL') . "</td>";
            echo "<td>" . htmlspecialchars($col['COLUMN_KEY']) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    echo "</div>";
    
    // ========================================
    // Progress Summary
    // ========================================
    $percentage = $totalSteps > 0 ? round(($completedSteps / $totalSteps) * 100) : 100;
    
    echo "<div class='progress'>";
    echo "<div class='progress-bar' style='width: {$percentage}%'>{$percentage}% Complete</div>";
    echo "</div>";
    
    echo "<div class='success' style='margin-top: 30px; font-size: 18px; padding: 20px;'>";
    echo "✅ <strong>Migration Completed Successfully!</strong><br>";
    echo "Completed $completedSteps of $totalSteps checks.<br><br>";
    echo "<strong>You can now:</strong><br>";
    echo "✓ Upload photos during visits<br>";
    echo "✓ Save checklist responses<br>";
    echo "✓ All features should work properly";
    echo "</div>";
    
    echo "<div class='error' style='margin-top: 20px; font-size: 16px;'>";
    echo "⚠️ <strong>SECURITY WARNING:</strong> Please DELETE this file (migrate-database-complete.php) immediately!";
    echo "</div>";
    
} catch (PDOException $e) {
    echo "<div class='error'>";
    echo "<strong>❌ Database Error:</strong><br>";
    echo htmlspecialchars($e->getMessage());
    echo "</div>";
    
    echo "<div class='sql-box'>";
    echo "<strong>Error Details:</strong><br>";
    echo "Code: " . htmlspecialchars($e->getCode()) . "<br>";
    echo "File: " . htmlspecialchars($e->getFile()) . "<br>";
    echo "Line: " . htmlspecialchars($e->getLine()) . "<br><br>";
    echo "<strong>Stack Trace:</strong><br>";
    echo htmlspecialchars($e->getTraceAsString());
    echo "</div>";
} catch (Exception $e) {
    echo "<div class='error'>";
    echo "<strong>❌ Error:</strong><br>";
    echo htmlspecialchars($e->getMessage());
    echo "</div>";
}
?>

    <hr style="margin: 30px 0;">
    
    <h2>📝 Next Steps</h2>
    <ol style="font-size: 16px; line-height: 2;">
        <li><strong>Test photo upload</strong> from mobile app</li>
        <li><strong>Test checklist responses</strong> (✓/✗/N/A)</li>
        <li><strong>Verify data</strong> is being saved correctly</li>
        <li><strong style="color: red;">DELETE this migration file!</strong></li>
    </ol>
    
    <div class="info" style="margin-top: 20px;">
        <strong>ℹ️ Troubleshooting:</strong><br>
        If you still see errors:
        <ul>
            <li>Check <code>backend-web/logs/app.log</code> for detailed errors</li>
            <li>Verify your database connection settings</li>
            <li>Make sure database user has ALTER TABLE permissions</li>
            <li>Check cPanel error_log for PHP errors</li>
        </ul>
    </div>
    
</div>
</body>
</html>
