<?php
/**
 * Delete Training Category API
 * Delete a training category and cascade delete its items
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

// Only accept DELETE method
if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    Response::error('Method not allowed', 405);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get category ID from query parameter
    $categoryId = isset($_GET['id']) ? (int)$_GET['id'] : null;
    
    if (!$categoryId || $categoryId <= 0) {
        Response::error('Category ID is required', 400);
    }
    
    // Verify category exists
    $sql = "SELECT id, checklist_id FROM training_categories WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $categoryId]);
    $category = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$category) {
        Response::error('Category not found', 404);
    }
    
    // Start transaction
    $db->beginTransaction();
    
    try {
        // Delete all items in this category first
        $sql = "DELETE FROM training_items WHERE category_id = :category_id";
        $stmt = $db->prepare($sql);
        $stmt->execute([':category_id' => $categoryId]);
        
        // Delete the category
        $sql = "DELETE FROM training_categories WHERE id = :id";
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $categoryId]);
        
        // Commit transaction
        $db->commit();
        
        Response::success(null, 'Category deleted successfully');
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
} catch (Exception $e) {
    error_log('Error deleting category: ' . $e->getMessage());
    Response::error('Error deleting category: ' . $e->getMessage(), 500);
}
?>
