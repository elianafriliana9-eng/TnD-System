<?php
error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '1');

require_once 'backend-web/config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Get recent sessions and their checklists/categories
    $query = "
        SELECT 
            ts.id as session_id,
            ts.session_date,
            ts.checklist_id,
            tc.name as checklist_name,
            GROUP_CONCAT(DISTINCT tcat.id ORDER BY tcat.id SEPARATOR ', ') as category_ids
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        LEFT JOIN training_categories tcat ON tc.id = tcat.checklist_id
        GROUP BY ts.id
        ORDER BY ts.id DESC
        LIMIT 5
    ";
    
    echo "=== RECENT SESSIONS & THEIR CHECKLISTS ===\n\n";
    
    $sessions = $db->query($query)->fetchAll(PDO::FETCH_ASSOC);
    foreach($sessions as $s) {
        echo "Session ID: " . $s['session_id'] . "\n";
        echo "  Date: " . $s['session_date'] . "\n";
        echo "  Checklist: " . $s['checklist_name'] . " (ID: " . $s['checklist_id'] . ")\n";
        echo "  Categories: " . ($s['category_ids'] ?: "NONE") . "\n\n";
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage();
}
?>
