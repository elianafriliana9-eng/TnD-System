<?php
/**
 * Run Database Schema Changes
 * Add financial form fields to visits table
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../classes/Database.php';

echo "========================================\n";
echo "PHASE 1: Database Schema Update\n";
echo "========================================\n\n";

try {
    $db = Database::getInstance()->getConnection();
    echo "✓ Database connected: " . DB_NAME . "\n\n";
    
    // Read SQL file
    $sqlFile = __DIR__ . '/schema_add_visit_financial_form.sql';
    
    if (!file_exists($sqlFile)) {
        throw new Exception("SQL file not found: $sqlFile");
    }
    
    $sql = file_get_contents($sqlFile);
    
    // Split into statements and execute only ALTER and CREATE
    $statements = explode(';', $sql);
    $executed = 0;
    
    echo "Executing schema changes...\n\n";
    
    foreach ($statements as $statement) {
        $statement = trim($statement);
        
        // Skip empty, comments, DESCRIBE, and UPDATE statements
        if (empty($statement) || 
            strpos($statement, '--') === 0 || 
            strpos($statement, '/*') === 0 ||
            stripos($statement, 'DESCRIBE') !== false ||
            stripos($statement, 'UPDATE') !== false) {
            continue;
        }
        
        // Only execute ALTER and CREATE statements
        if (stripos($statement, 'ALTER TABLE') === 0 || 
            stripos($statement, 'CREATE INDEX') === 0) {
            try {
                $db->exec($statement);
                $executed++;
                echo "✓ Executed: " . substr($statement, 0, 50) . "...\n";
            } catch (PDOException $e) {
                // Check if column already exists
                if (strpos($e->getMessage(), 'Duplicate column') !== false) {
                    echo "⚠ Column already exists (skipped)\n";
                } elseif (strpos($e->getMessage(), 'Duplicate key') !== false) {
                    echo "⚠ Index already exists (skipped)\n";
                } else {
                    throw $e;
                }
            }
        }
    }
    
    echo "\n✓ Schema changes applied: $executed statements\n\n";
    
    // Verify columns
    echo "Verifying new columns...\n\n";
    $stmt = $db->query("DESCRIBE visits");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $newColumns = [
        'uang_omset_modal',
        'uang_ditukar',
        'cash',
        'qris',
        'debit_kredit',
        'total_pembayaran',
        'kategoric',
        'leadtime',
        'status_keuangan'
    ];
    
    $found = [];
    foreach ($columns as $col) {
        if (in_array($col['Field'], $newColumns)) {
            $found[] = $col['Field'];
            echo "✓ " . str_pad($col['Field'], 20) . " | " . $col['Type'] . "\n";
        }
    }
    
    echo "\n";
    echo "========================================\n";
    echo "VERIFICATION RESULT:\n";
    echo "========================================\n";
    echo "Expected columns: " . count($newColumns) . "\n";
    echo "Found columns: " . count($found) . "\n";
    
    if (count($found) === count($newColumns)) {
        echo "\n✓✓✓ SUCCESS! All financial fields added!\n";
    } else {
        echo "\n⚠ WARNING: Some columns missing!\n";
        $missing = array_diff($newColumns, $found);
        foreach ($missing as $col) {
            echo "  - Missing: $col\n";
        }
    }
    
    echo "\n";
    echo "========================================\n";
    echo "NEXT STEPS:\n";
    echo "========================================\n";
    echo "1. Update backend API to accept financial data\n";
    echo "2. Build mobile app financial form UI\n";
    echo "3. Update PDF generation to show financial data\n";
    echo "\n";
    
} catch (Exception $e) {
    echo "\n✗ ERROR: " . $e->getMessage() . "\n";
    echo "\nStack trace:\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}
?>
