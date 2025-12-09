<?php
/**
 * Delete Training Checklist Item API
 * Delete a single training item from a checklist category
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
    error_log('DELETE endpoint: Method not allowed - ' . $_SERVER['REQUEST_METHOD']);
    Response::error('Method not allowed', 405);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get item ID from query parameter
    $itemId = isset($_GET['id']) ? (int)$_GET['id'] : null;
    error_log('DELETE endpoint: Received itemId = ' . var_export($itemId, true));
    
    if (!$itemId || $itemId <= 0) {
        error_log('DELETE endpoint: Invalid itemId');
        Response::error('Item ID is required', 400);
    }
    
    // Verify item exists
    $sql = "SELECT id, category_id FROM training_items WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $itemId]);
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    error_log('DELETE endpoint: Item fetch result = ' . var_export($item, true));
    
    if (!$item) {
        error_log('DELETE endpoint: Item not found for id ' . $itemId);
        Response::error('Item not found', 404);
    }
    
    // Delete the item
    $sql = "DELETE FROM training_items WHERE id = :id";
    $stmt = $db->prepare($sql);
    $deleteResult = $stmt->execute([':id' => $itemId]);
    error_log('DELETE endpoint: Delete executed, rowCount = ' . $stmt->rowCount());
    
    Response::success(null, 'Item deleted successfully');
} catch (Exception $e) {
    error_log('Error deleting item: ' . $e->getMessage());
    Response::error('Error deleting item: ' . $e->getMessage(), 500);
}
?>
