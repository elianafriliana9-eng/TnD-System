<?php
/**
 * Check Database Tables
 * Shows all tables in current database
 */

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/classes/Database.php';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>TND System - Database Tables Check</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
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
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0;
        }
        th { 
            background: #007bff; 
            color: white; 
            padding: 12px; 
            text-align: left;
        }
        td { 
            padding: 10px; 
            border-bottom: 1px solid #dee2e6;
        }
        tr:hover { background: #f8f9fa; }
        .info { 
            color: #004085; 
            background: #cce5ff; 
            padding: 12px; 
            border-radius: 4px; 
            margin: 10px 0;
        }
        .error { 
            color: #dc3545; 
            background: #f8d7da; 
            padding: 12px; 
            border-radius: 4px; 
            margin: 10px 0;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🔍 Database Tables Check</h1>

<?php
try {
    $db = Database::getInstance()->getConnection();
    
    // Get database name
    $stmt = $db->query("SELECT DATABASE() as dbname");
    $dbInfo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<div class='info'><strong>Database:</strong> " . htmlspecialchars($dbInfo['dbname']) . "</div>";
    
    // Get all tables
    $stmt = $db->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_NUM);
    
    echo "<h2>📊 Tables in Database (" . count($tables) . " total)</h2>";
    echo "<table>";
    echo "<tr><th>#</th><th>Table Name</th><th>Row Count</th><th>Columns</th></tr>";
    
    $i = 1;
    foreach ($tables as $table) {
        $tableName = $table[0];
        
        // Get row count
        $countStmt = $db->query("SELECT COUNT(*) as count FROM `$tableName`");
        $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Get column count
        $colStmt = $db->query("SHOW COLUMNS FROM `$tableName`");
        $colCount = $colStmt->rowCount();
        
        echo "<tr>";
        echo "<td>$i</td>";
        echo "<td><strong>$tableName</strong></td>";
        echo "<td>$count rows</td>";
        echo "<td>$colCount columns</td>";
        echo "</tr>";
        $i++;
    }
    echo "</table>";
    
    // Check for specific tables we need
    echo "<h2>🔍 Checking Required Tables</h2>";
    $requiredTables = [
        'users',
        'divisions',
        'outlets',
        'visits',
        'visit_photos',
        'visit_checklist_responses',
        'checklist_points',
        'checklist_categories'
    ];
    
    $existingTables = array_column($tables, 0);
    
    echo "<table>";
    echo "<tr><th>Required Table</th><th>Status</th></tr>";
    
    foreach ($requiredTables as $reqTable) {
        $exists = in_array($reqTable, $existingTables);
        $status = $exists ? "<span style='color:green'>✅ EXISTS</span>" : "<span style='color:red'>❌ MISSING</span>";
        
        echo "<tr>";
        echo "<td><strong>$reqTable</strong></td>";
        echo "<td>$status</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show columns for existing tables that we need to modify
    $tablesToCheck = ['photos', 'visit_checklist_responses', 'visits'];
    
    foreach ($tablesToCheck as $tableToCheck) {
        if (in_array($tableToCheck, $existingTables)) {
            echo "<h3>📋 Columns in: $tableToCheck</h3>";
            $colStmt = $db->query("SHOW COLUMNS FROM `$tableToCheck`");
            $columns = $colStmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "<table>";
            echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
            foreach ($columns as $col) {
                echo "<tr>";
                echo "<td><strong>" . htmlspecialchars($col['Field']) . "</strong></td>";
                echo "<td>" . htmlspecialchars($col['Type']) . "</td>";
                echo "<td>" . htmlspecialchars($col['Null']) . "</td>";
                echo "<td>" . htmlspecialchars($col['Key']) . "</td>";
                echo "<td>" . htmlspecialchars($col['Default'] ?? 'NULL') . "</td>";
                echo "</tr>";
            }
            echo "</table>";
        }
    }
    
} catch (Exception $e) {
    echo "<div class='error'>";
    echo "<strong>❌ Error:</strong><br>";
    echo htmlspecialchars($e->getMessage());
    echo "</div>";
}
?>

    <hr style="margin: 30px 0;">
    <p><strong>⚠️ DELETE this file after checking!</strong></p>
    
</div>
</body>
</html>
