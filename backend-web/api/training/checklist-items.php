<?php
/**
 * Get Training Checklist Items API
 * Get all items for a specific category
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../utils/Headers.php';

Headers::setAPIHeaders();

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Temporarily disabled for testing
// if (!Auth::checkAuth()) {
//     Response::unauthorized('Authentication required');
// }

// Only accept GET method
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get category ID from query parameter
    $categoryId = isset($_GET['category_id']) ? (int)$_GET['category_id'] : null;
    
    if (!$categoryId || $categoryId <= 0) {
        Response::error('Category ID is required', 400);
    }
    
    // Verify category exists
    $checkSql = "SELECT id FROM training_categories WHERE id = :id";
    $checkStmt = $db->prepare($checkSql);
    $checkStmt->execute([':id' => $categoryId]);
    $categoryExists = $checkStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$categoryExists) {
        Response::error('Category not found', 404);
    }
    
    // Get all items for this category - try training_points first, then training_items
    $sql_primary = "SELECT 
                id,
                category_id,
                question as item_text,
                description,
                order_index as sequence_order,
                created_at
            FROM training_points
            WHERE category_id = :category_id
            ORDER BY order_index ASC";
    
    $stmt = $db->prepare($sql_primary);
    $stmt->execute([':category_id' => $categoryId]);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // If no items found in training_points, try training_items
    if (empty($items)) {
        error_log("No items found in training_points for category $categoryId, trying training_items");
        $sql_fallback = "SELECT 
                    id,
                    category_id,
                    question as item_text,
                    description,
                    order_index as sequence_order,
                    created_at
                FROM training_items
                WHERE category_id = :category_id
                ORDER BY order_index ASC";
        
        $stmt = $db->prepare($sql_fallback);
        $stmt->execute([':category_id' => $categoryId]);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Convert types
    $itemsResult = [];
    foreach ($items as $item) {
        $itemsResult[] = [
            'id' => (int)$item['id'],
            'category_id' => (int)$item['category_id'],
            'item_text' => $item['item_text'],
            'description' => $item['description'],
            'sequence_order' => (int)$item['sequence_order'],
            'created_at' => $item['created_at'],
        ];
    }
    
    Response::success($itemsResult, 'Items retrieved successfully');
    
} catch (Exception $e) {
    error_log('Error getting items: ' . $e->getMessage());
    Response::error('Error getting items: ' . $e->getMessage(), 500);
}
?>
