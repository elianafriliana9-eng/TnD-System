<?php
/**
 * Save Training Checklist Item API
 * Create or update training checklist item
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

// Only accept POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get JSON input
    $rawInput = file_get_contents('php://input');
    error_log('Raw input for item: ' . $rawInput);
    $input = json_decode($rawInput, true);
    error_log('Decoded input for item: ' . json_encode($input));
    
    // Validate input is not null
    if ($input === null) {
        error_log('JSON decode failed for item');
        Response::error('Invalid JSON input: ' . json_last_error_msg(), 400);
    }
    
    // Validate required fields
    if (!isset($input['category_id']) || empty($input['category_id'])) {
        Response::error('Category ID is required', 400);
    }
    
    if (!isset($input['item_text']) || trim((string)$input['item_text']) === '') {
        Response::error('Item text is required', 400);
    }
    
    // Trim the values
    $input['item_text'] = trim((string)$input['item_text']);
    $input['description'] = trim((string)($input['description'] ?? ''));
    $input['order_index'] = (int)($input['sequence_order'] ?? $input['order_index'] ?? 0);
    
    // Start transaction
    $db->beginTransaction();
    
    $itemId = $input['id'] ?? null;
    
    if ($itemId) {
        // Update existing item
        $sql = "UPDATE training_items 
                SET question = :question, 
                    description = :description,
                    order_index = :order_index,
                    category_id = :category_id
                WHERE id = :id";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':question' => $input['item_text'],
            ':description' => $input['description'],
            ':order_index' => $input['order_index'],
            ':category_id' => (int)$input['category_id'],
            ':id' => $itemId
        ]);
    } else {
        // Create new item
        $sql = "INSERT INTO training_items (category_id, question, description, order_index, created_at) 
                VALUES (:category_id, :question, :description, :order_index, NOW())";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':category_id' => (int)$input['category_id'],
            ':question' => $input['item_text'],
            ':description' => $input['description'],
            ':order_index' => $input['order_index']
        ]);
        $itemId = $db->lastInsertId();
    }
    
    // Commit transaction
    $db->commit();
    
    // Get the created/updated item data
    $sql = "SELECT 
                id,
                category_id,
                question as item_text,
                description,
                order_index,
                created_at
            FROM training_items
            WHERE id = :id";
    
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $itemId]);
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Convert types
    if ($item) {
        $item['id'] = (int)$item['id'];
        $item['category_id'] = (int)$item['category_id'];
        $item['order_index'] = (int)$item['order_index'];
    }
    
    Response::success(
        $item, 
        $input['id'] ? 'Item updated successfully' : 'Item created successfully'
    );
    
} catch (Exception $e) {
    // Rollback on error
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    error_log('Error in checklist-item-save: ' . $e->getMessage());
    Response::error('Server error: ' . $e->getMessage(), 500);
}
