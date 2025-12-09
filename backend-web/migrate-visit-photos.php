<?php
/**
 * Migration: Add checklist_item_id column to visit_photos table
 * 
 * Run this file ONCE via browser: https://tndsystem.online/backend-web/migrate-visit-photos.php
 * Then DELETE this file after successful execution
 * 
 * IMPORTANT: Backup your database before running this migration!
 */

require_once __DIR__ . '/config/database.php';

// Security: Uncomment and set password for production
// $MIGRATION_PASSWORD = 'your_secure_password_here';
// if (!isset($_GET['password']) || $_GET['password'] !== $MIGRATION_PASSWORD) {
//     die('Access denied. Invalid password.');
// }

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>TND System - Database Migration</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            max-width: 900px; 
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
        h2 { color: #555; margin-top: 25px; }
        .success { color: #28a745; background: #d4edda; padding: 12px; border-radius: 4px; border-left: 4px solid #28a745; }
        .error { color: #dc3545; background: #f8d7da; padding: 12px; border-radius: 4px; border-left: 4px solid #dc3545; }
        .warning { color: #856404; background: #fff3cd; padding: 12px; border-radius: 4px; border-left: 4px solid #ffc107; }
        .info { color: #004085; background: #cce5ff; padding: 12px; border-radius: 4px; border-left: 4px solid #007bff; }
        .sql-box { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 4px; 
            font-family: 'Courier New', monospace; 
            font-size: 13px;
            overflow-x: auto;
            border: 1px solid #dee2e6;
        }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 15px 0;
            background: white;
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
            padding: 15px;
            background: #f8f9fa;
            border-radius: 4px;
        }
        .step-number {
            display: inline-block;
            width: 30px;
            height: 30px;
            background: #007bff;
            color: white;
            border-radius: 50%;
            text-align: center;
            line-height: 30px;
            font-weight: bold;
            margin-right: 10px;
        }
        .btn-delete {
            display: inline-block;
            background: #dc3545;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 4px;
            margin-top: 20px;
        }
        .btn-delete:hover {
            background: #c82333;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🔧 Database Migration: Add checklist_item_id to visit_photos</h1>
    
    <div class="warning">
        <strong>⚠️ WARNING:</strong> This will modify your database structure. 
        Make sure you have a backup before proceeding!
    </div>

<?php
try {
    $db = Database::getInstance()->getConnection();
    
    echo "<div class='step'><span class='step-number'>1</span><strong>Checking current table structure...</strong></div>";
    
    // Check if column exists
    $checkSql = "SELECT COUNT(*) as count 
                 FROM INFORMATION_SCHEMA.COLUMNS 
                 WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'visit_photos' 
                 AND COLUMN_NAME = 'checklist_item_id'";
    
    $stmt = $db->query($checkSql);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $columnExists = $result['count'] > 0;
    
    if ($columnExists) {
        echo "<div class='info'>ℹ️ Column <code>checklist_item_id</code> already exists in visit_photos table.</div>";
    } else {
        echo "<div class='warning'>⚠️ Column <code>checklist_item_id</code> NOT found. Will be created.</div>";
        
        echo "<div class='step'><span class='step-number'>2</span><strong>Adding checklist_item_id column...</strong></div>";
        
        $alterSql = "ALTER TABLE visit_photos 
                     ADD COLUMN checklist_item_id INT NULL 
                     AFTER visit_id";
        
        echo "<div class='sql-box'>" . htmlspecialchars($alterSql) . "</div>";
        
        $db->exec($alterSql);
        echo "<div class='success'>✅ Column added successfully!</div>";
        
        echo "<div class='step'><span class='step-number'>3</span><strong>Adding foreign key constraint...</strong></div>";
        
        // Check if checklist_points table exists
        $checkTableSql = "SELECT COUNT(*) as count 
                          FROM INFORMATION_SCHEMA.TABLES 
                          WHERE TABLE_SCHEMA = DATABASE() 
                          AND TABLE_NAME = 'checklist_points'";
        $stmt = $db->query($checkTableSql);
        $tableResult = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($tableResult['count'] > 0) {
            $fkSql = "ALTER TABLE visit_photos 
                      ADD CONSTRAINT visit_photos_checklist_item_fk 
                      FOREIGN KEY (checklist_item_id) 
                      REFERENCES checklist_points(id) 
                      ON DELETE SET NULL";
            
            echo "<div class='sql-box'>" . htmlspecialchars($fkSql) . "</div>";
            
            try {
                $db->exec($fkSql);
                echo "<div class='success'>✅ Foreign key constraint added successfully!</div>";
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate key') !== false) {
                    echo "<div class='info'>ℹ️ Foreign key constraint already exists.</div>";
                } else {
                    throw $e;
                }
            }
        } else {
            echo "<div class='warning'>⚠️ Table checklist_points not found. Foreign key constraint skipped.</div>";
        }
    }
    
    echo "<div class='step'><span class='step-number'>4</span><strong>Verifying final structure...</strong></div>";
    
    // Show current structure
    $structureSql = "SELECT 
                        COLUMN_NAME,
                        DATA_TYPE,
                        IS_NULLABLE,
                        COLUMN_DEFAULT,
                        COLUMN_KEY,
                        EXTRA
                     FROM INFORMATION_SCHEMA.COLUMNS
                     WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'visit_photos'
                     ORDER BY ORDINAL_POSITION";
    
    $stmt = $db->query($structureSql);
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table>";
    echo "<tr><th>Column Name</th><th>Data Type</th><th>Nullable</th><th>Default</th><th>Key</th><th>Extra</th></tr>";
    
    foreach ($columns as $column) {
        echo "<tr>";
        echo "<td><strong>" . htmlspecialchars($column['COLUMN_NAME']) . "</strong></td>";
        echo "<td>" . htmlspecialchars($column['DATA_TYPE']) . "</td>";
        echo "<td>" . htmlspecialchars($column['IS_NULLABLE']) . "</td>";
        echo "<td>" . htmlspecialchars($column['COLUMN_DEFAULT'] ?? 'NULL') . "</td>";
        echo "<td>" . htmlspecialchars($column['COLUMN_KEY']) . "</td>";
        echo "<td>" . htmlspecialchars($column['EXTRA']) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show foreign keys
    echo "<h2>Foreign Key Constraints:</h2>";
    $fkSql = "SELECT 
                CONSTRAINT_NAME,
                COLUMN_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME
              FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
              WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'visit_photos'
              AND REFERENCED_TABLE_NAME IS NOT NULL";
    
    $stmt = $db->query($fkSql);
    $fks = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($fks) > 0) {
        echo "<table>";
        echo "<tr><th>Constraint Name</th><th>Column</th><th>References</th></tr>";
        foreach ($fks as $fk) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($fk['CONSTRAINT_NAME']) . "</td>";
            echo "<td>" . htmlspecialchars($fk['COLUMN_NAME']) . "</td>";
            echo "<td>" . htmlspecialchars($fk['REFERENCED_TABLE_NAME']) . "." . htmlspecialchars($fk['REFERENCED_COLUMN_NAME']) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<div class='info'>No foreign key constraints found.</div>";
    }
    
    echo "<div class='success' style='margin-top: 30px; font-size: 18px;'>";
    echo "✅ <strong>Migration completed successfully!</strong><br>";
    echo "Photo upload should now work properly.";
    echo "</div>";
    
    echo "<div class='error' style='margin-top: 20px;'>";
    echo "⚠️ <strong>IMPORTANT:</strong> Please DELETE this file (migrate-visit-photos.php) immediately for security!";
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
    echo "Line: " . htmlspecialchars($e->getLine());
    echo "</div>";
} catch (Exception $e) {
    echo "<div class='error'>";
    echo "<strong>❌ Error:</strong><br>";
    echo htmlspecialchars($e->getMessage());
    echo "</div>";
}
?>

    <hr style="margin: 30px 0;">
    <p><strong>Next Steps:</strong></p>
    <ol>
        <li>Test photo upload from mobile app</li>
        <li>Verify photos are being saved with checklist_item_id</li>
        <li><strong style="color: red;">DELETE this migration file!</strong></li>
    </ol>
    
</div>
</body>
</html>
