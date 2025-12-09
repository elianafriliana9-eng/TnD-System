<?php
/**
 * Training Sessions Debug API
 * Check what sessions exist and which checklists they use
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../../config/database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Get all sessions with their checklists and category counts
    $stmt = $db->query("
        SELECT 
            ts.id as session_id,
            ts.session_date,
            ts.status,
            tc.id as checklist_id,
            tc.name as checklist_name,
            (SELECT COUNT(*) FROM training_categories WHERE checklist_id = tc.id) as category_count,
            GROUP_CONCAT(DISTINCT tcat.id ORDER BY tcat.id SEPARATOR ', ') as category_ids,
            GROUP_CONCAT(DISTINCT tcat.name ORDER BY tcat.id SEPARATOR ', ') as category_names
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        LEFT JOIN training_categories tcat ON tc.id = tcat.checklist_id
        GROUP BY ts.id, tc.id
        ORDER BY ts.session_date DESC, ts.id DESC
        LIMIT 20
    ");
    
    $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response = [
        'success' => true,
        'total_sessions' => count($sessions),
        'sessions' => $sessions,
        'message' => 'Recent training sessions'
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
