<?php
/**
 * Check photos table schema and foreign keys - DETAILED
 */

require_once __DIR__ . '/config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $db = Database::getInstance()->getConnection();
    
    echo "=== PHOTOS TABLE SCHEMA ===\n\n";
    
    // Get table structure
    $stmt = $db->query("DESCRIBE photos");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Columns:\n";
    echo str_repeat("-", 80) . "\n";
    printf("%-20s %-20s %-10s %-10s %-20s\n", "Field", "Type", "Null", "Key", "Extra");
    echo str_repeat("-", 80) . "\n";
    
    foreach ($columns as $col) {
        printf("%-20s %-20s %-10s %-10s %-20s\n", 
            $col['Field'], 
            $col['Type'], 
            $col['Null'], 
            $col['Key'],
            $col['Extra'] ?? ''
        );
    }
    
    echo "\n\n=== FOREIGN KEY CONSTRAINTS ===\n\n";
    
    // Get foreign keys
    $stmt = $db->query("
        SELECT 
            CONSTRAINT_NAME,
            COLUMN_NAME,
            REFERENCED_TABLE_NAME,
            REFERENCED_COLUMN_NAME,
            UPDATE_RULE,
            DELETE_RULE
        FROM 
            information_schema.KEY_COLUMN_USAGE
        WHERE 
            TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'photos'
            AND REFERENCED_TABLE_NAME IS NOT NULL
    ");
    
    $foreignKeys = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($foreignKeys)) {
        echo "No foreign keys found.\n";
    } else {
        foreach ($foreignKeys as $fk) {
            echo "Constraint: {$fk['CONSTRAINT_NAME']}\n";
            echo "  Column: {$fk['COLUMN_NAME']}\n";
            echo "  References: {$fk['REFERENCED_TABLE_NAME']}.{$fk['REFERENCED_COLUMN_NAME']}\n";
            echo "  On Update: {$fk['UPDATE_RULE']}\n";
            echo "  On Delete: {$fk['DELETE_RULE']}\n\n";
        }
    }
    
    echo "\n=== CHECKING RELATED TABLES ===\n\n";
    
    // Check if items table exists
    echo "Items table:\n";
    $stmt = $db->query("SHOW TABLES LIKE 'items'");
    if ($stmt->rowCount() > 0) {
        echo "  ✅ EXISTS\n";
        $stmt = $db->query("SELECT COUNT(*) as count FROM items");
        $count = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "  Rows: {$count['count']}\n";
    } else {
        echo "  ❌ DOES NOT EXIST\n";
    }
    
    echo "\nChecklist Points table:\n";
    $stmt = $db->query("SHOW TABLES LIKE 'checklist_points'");
    if ($stmt->rowCount() > 0) {
        echo "  ✅ EXISTS\n";
        $stmt = $db->query("SELECT COUNT(*) as count FROM checklist_points");
        $count = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "  Rows: {$count['count']}\n";
        
        // Sample IDs
        $stmt = $db->query("SELECT id, point_text FROM checklist_points LIMIT 5");
        $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "  Sample IDs:\n";
        foreach ($samples as $s) {
            echo "    - ID {$s['id']}: {$s['point_text']}\n";
        }
    } else {
        echo "  ❌ DOES NOT EXIST\n";
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
