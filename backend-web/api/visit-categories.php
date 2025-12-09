<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/ChecklistCategory.php';
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
$category = new ChecklistCategory();

try {
    switch ($method) {
        case 'GET':
            // Get categories by division
            $user = Auth::getUserFromHeader() ?? Auth::user();
            
            if (!$user || !isset($user['division_id'])) {
                Response::error('User division not found', 400);
                exit;
            }
            
            $divisionId = $user['division_id'];
            
            // Get categories with items count for this division
            $sql = "SELECT c.*, COUNT(cp.id) as items_count
                    FROM checklist_categories c
                    LEFT JOIN checklist_points cp ON c.id = cp.category_id AND cp.is_active = 1
                    WHERE c.division_id = :division_id AND c.is_active = 1
                    GROUP BY c.id
                    ORDER BY c.sort_order, c.name";
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare($sql);
            $stmt->bindParam(':division_id', $divisionId);
            $stmt->execute();
            $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            Response::success($categories);
            break;
            
        default:
            Response::error('Method not allowed', 405);
            break;
    }
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
