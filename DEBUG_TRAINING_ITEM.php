<?php
/**
 * Debug Training Item Creation Issues
 * Test script to diagnose FK constraint problems
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

require_once __DIR__ . '/backend-web/config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    echo "=== TRAINING MODULE DATABASE DIAGNOSTIC ===\n\n";
    
    // 1. Check if training_categories table exists
    echo "1. Checking training_categories table...\n";
    try {
        $result = $db->query("SELECT COUNT(*) as cnt FROM training_categories");
        $count = $result->fetchColumn();
        echo "   ✓ Table exists with $count records\n";
        
        // List first 5 categories
        $stmt = $db->query("SELECT id, name FROM training_categories LIMIT 5");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "     - ID: {$row['id']}, Name: {$row['name']}\n";
        }
    } catch (Exception $e) {
        echo "   ✗ Error: " . $e->getMessage() . "\n";
    }
    
    // 2. Check if training_items table exists
    echo "\n2. Checking training_items table...\n";
    try {
        $result = $db->query("SELECT COUNT(*) as cnt FROM training_items");
        $count = $result->fetchColumn();
        echo "   ✓ Table exists with $count records\n";
        
        // Check schema
        $stmt = $db->query("DESCRIBE training_items");
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "   Columns: " . implode(", ", $columns) . "\n";
    } catch (Exception $e) {
        echo "   ✗ Error: " . $e->getMessage() . "\n";
    }
    
    // 3. Check if training_points table exists
    echo "\n3. Checking training_points table...\n";
    try {
        $result = $db->query("SELECT COUNT(*) as cnt FROM training_points");
        $count = $result->fetchColumn();
        echo "   ✓ Table exists with $count records\n";
        
        // Check schema
        $stmt = $db->query("DESCRIBE training_points");
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "   Columns: " . implode(", ", $columns) . "\n";
    } catch (Exception $e) {
        echo "   ✗ Error: " . $e->getMessage() . "\n";
    }
    
    // 4. Check FK constraints
    echo "\n4. Checking Foreign Key Constraints...\n";
    try {
        $stmt = $db->query("SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME 
                           FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                           WHERE TABLE_SCHEMA = 'tnd_system' 
                           AND (TABLE_NAME = 'training_items' OR TABLE_NAME = 'training_points')
                           AND REFERENCED_TABLE_NAME IS NOT NULL");
        $fks = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if ($fks) {
            foreach ($fks as $fk) {
                echo "   Table: {$fk['TABLE_NAME']}, Column: {$fk['COLUMN_NAME']} → {$fk['REFERENCED_TABLE_NAME']}.{$fk['REFERENCED_COLUMN_NAME']}\n";
            }
        } else {
            echo "   No FK constraints found\n";
        }
    } catch (Exception $e) {
        echo "   ✗ Error: " . $e->getMessage() . "\n";
    }
    
    // 5. Test inserting a sample record with each table
    echo "\n5. Testing INSERT with sample data...\n";
    
    // Get first category ID
    $stmt = $db->query("SELECT id FROM training_categories LIMIT 1");
    $firstCat = $stmt->fetchColumn();
    
    if ($firstCat) {
        echo "   Using category ID: $firstCat\n";
        
        // Try training_items
        echo "\n   Testing INSERT into training_items...\n";
        try {
            $sql = "INSERT INTO training_items (category_id, question, description, order_index, created_at) 
                   VALUES (?, ?, ?, ?, NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([$firstCat, 'Test Item', 'Test Description', 1]);
            $insertedId = $db->lastInsertId();
            echo "   ✓ SUCCESS: Inserted record with ID $insertedId\n";
            
            // Clean up test record
            $db->prepare("DELETE FROM training_items WHERE id = ?")->execute([$insertedId]);
            echo "   ✓ Cleaned up test record\n";
        } catch (PDOException $e) {
            echo "   ✗ FAILED: " . $e->getMessage() . "\n";
        }
        
        // Try training_points if it exists
        echo "\n   Testing INSERT into training_points...\n";
        try {
            $sql = "INSERT INTO training_points (category_id, question, description, order_index, created_at) 
                   VALUES (?, ?, ?, ?, NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([$firstCat, 'Test Point', 'Test Description', 1]);
            $insertedId = $db->lastInsertId();
            echo "   ✓ SUCCESS: Inserted record with ID $insertedId\n";
            
            // Clean up test record
            $db->prepare("DELETE FROM training_points WHERE id = ?")->execute([$insertedId]);
            echo "   ✓ Cleaned up test record\n";
        } catch (PDOException $e) {
            echo "   ✗ FAILED: " . $e->getMessage() . "\n";
        }
    } else {
        echo "   ✗ No categories found to test with\n";
    }
    
    echo "\n=== END OF DIAGNOSTIC ===\n";
    
} catch (Exception $e) {
    echo "Fatal Error: " . $e->getMessage() . "\n";
}
?>
