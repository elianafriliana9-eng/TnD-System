<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
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
            if (!isset($_GET['category_id'])) {
                Response::error('Category ID required', 400);
                exit;
            }
            
            $categoryId = intval($_GET['category_id']);
            
            // Get checklist items for this category
            $sql = "SELECT id, category_id, question as item_text, sort_order as item_order, is_active
                    FROM checklist_points
                    WHERE category_id = :category_id AND is_active = 1
                    ORDER BY sort_order ASC, id ASC";
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare($sql);
            $stmt->bindParam(':category_id', $categoryId);
            $stmt->execute();
            $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            Response::success($items);
            break;
            
        default:
            Response::error('Method not allowed', 405);
            break;
    }
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
