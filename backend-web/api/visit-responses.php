<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../utils/Response.php';
require_once '../utils/Auth.php';
require_once '../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::error('Authentication required', 401);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            if (!isset($_GET['visit_id'])) {
                Response::error('Visit ID required', 400);
                exit;
            }
            
            $visitId = intval($_GET['visit_id']);
            
            // Get visit responses with category and item details
            // Production table: photos (not visit_photos)
            // Production columns: item_id (not checklist_item_id), file_path (not photo_path)
            // IMPORTANT: Get ONE photo per response (use subquery to avoid duplicates)
            $sql = "SELECT 
                        vcr.id,
                        vcr.visit_id,
                        vcr.checklist_point_id as checklist_item_id,
                        vcr.response as response_value,
                        vcr.notes,
                        vcr.created_at,
                        cp.question as item_text,
                        cc.name as category_name,
                        cc.id as category_id,
                        (SELECT file_path FROM photos 
                         WHERE visit_id = vcr.visit_id 
                         AND item_id = vcr.checklist_point_id 
                         LIMIT 1) as photo_url
                    FROM visit_checklist_responses vcr
                    INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
                    INNER JOIN checklist_categories cc ON cp.category_id = cc.id
                    WHERE vcr.visit_id = :visit_id
                    ORDER BY cc.sort_order, cp.sort_order";
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare($sql);
            $stmt->bindParam(':visit_id', $visitId);
            $stmt->execute();
            $responses = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert photo_path to full URL
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'];
            // Production URL: https://tndsystem.online/backend-web/
            $baseUrl = $protocol . '://' . $host . '/backend-web/';
            
            foreach ($responses as &$response) {
                if (!empty($response['photo_url'])) {
                    $response['photo_url'] = $baseUrl . $response['photo_url'];
                }
            }
            
            Response::success($responses);
            break;
            
        default:
            Response::error('Method not allowed', 405);
            break;
    }
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
