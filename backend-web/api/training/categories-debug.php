<?php
/**
 * Training Categories Debug API
 * Check what categories exist in the database
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../../config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Get all categories
    $stmt = $db->query("
        SELECT 
            tc.id,
            tc.name,
            tc.checklist_id,
            tcl.name as checklist_name,
            (SELECT COUNT(*) FROM training_items ti WHERE ti.category_id = tc.id) as item_count
        FROM training_categories tc
        LEFT JOIN training_checklists tcl ON tc.checklist_id = tcl.id
        ORDER BY tc.checklist_id, tc.order_index
    ");
    
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response = [
        'success' => true,
        'total_categories' => count($categories),
        'categories' => $categories,
        'message' => 'Available categories on production server'
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
