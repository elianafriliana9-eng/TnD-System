<?php
/**
 * Save Training Item/Point API
 * Create or update a single training item/point
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../utils/Headers.php';

Headers::setAPIHeaders();

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

// Only accept POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get JSON input
    $rawInput = file_get_contents('php://input');
    error_log('Item Save - Raw input: ' . $rawInput);
    $input = json_decode($rawInput, true);
    
    if ($input === null) {
        error_log('Item Save - JSON decode failed: ' . json_last_error_msg());
        Response::error('Invalid JSON input: ' . json_last_error_msg(), 400);
    }
    
    // Validate required fields
    if (!isset($input['category_id']) || empty($input['category_id'])) {
        Response::error('Category ID is required', 400);
    }
    
    if (!isset($input['item_text']) || trim((string)$input['item_text']) === '') {
        Response::error('Item text is required', 400);
    }
    
    $categoryId = (int)$input['category_id'];
    $itemText = trim((string)$input['item_text']);
    $description = trim((string)($input['description'] ?? ''));
    $sequenceOrder = isset($input['sequence_order']) ? (int)$input['sequence_order'] : null;
    $itemId = isset($input['id']) ? (int)$input['id'] : null;
    
    // Validate that category exists
    $categorySql = "SELECT id, name FROM training_categories WHERE id = :id";
    $categoryStmt = $db->prepare($categorySql);
    $categoryStmt->execute([':id' => $categoryId]);
    $category = $categoryStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$category) {
        error_log("Category ID $categoryId not found");
        Response::error('Category not found', 404);
    }
    
    error_log("Using category: {$category['name']} (ID: {$category['id']})");
    
    // Determine which table to use - prefer training_points
    $tableName = 'training_points';
    
    // Check if training_points table exists and is usable
    try {
        $testQuery = $db->query("SELECT 1 FROM training_points LIMIT 1");
        error_log("Using table: training_points");
    } catch (PDOException $e) {
        // Fallback to training_items if training_points doesn't exist
        $tableName = 'training_items';
        error_log("Table training_points not available, using: training_items");
    }
    
    // Start transaction
    $db->beginTransaction();
    
    try {
        if ($itemId) {
            // Update existing item
            if ($sequenceOrder !== null) {
                $sql = "UPDATE $tableName 
                        SET question = :question, 
                            description = :description,
                            order_index = :order_index
                        WHERE id = :id AND category_id = :category_id";
                $stmt = $db->prepare($sql);
                $stmt->execute([
                    ':question' => $itemText,
                    ':description' => $description,
                    ':order_index' => $sequenceOrder,
                    ':id' => $itemId,
                    ':category_id' => $categoryId
                ]);
            } else {
                $sql = "UPDATE $tableName 
                        SET question = :question, 
                            description = :description
                        WHERE id = :id AND category_id = :category_id";
                $stmt = $db->prepare($sql);
                $stmt->execute([
                    ':question' => $itemText,
                    ':description' => $description,
                    ':id' => $itemId,
                    ':category_id' => $categoryId
                ]);
            }
            
            error_log("Updated item ID: $itemId in table: $tableName");
        } else {
            // Get next sequence_order if not provided
            if ($sequenceOrder === null) {
                $maxOrderSql = "SELECT COALESCE(MAX(order_index), 0) + 1 as next_order 
                               FROM $tableName 
                               WHERE category_id = :category_id";
                $maxOrderStmt = $db->prepare($maxOrderSql);
                $maxOrderStmt->execute([':category_id' => $categoryId]);
                $sequenceOrder = (int)$maxOrderStmt->fetchColumn();
            }
            
            // Create new item
            $sql = "INSERT INTO $tableName 
                    (category_id, question, description, order_index, created_at) 
                    VALUES (:category_id, :question, :description, :order_index, NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                ':category_id' => $categoryId,
                ':question' => $itemText,
                ':description' => $description,
                ':order_index' => $sequenceOrder
            ]);
            $itemId = $db->lastInsertId();
            
            error_log("Created new item ID: $itemId in table: $tableName with order_index: $sequenceOrder");
        }
        
        // Commit transaction
        $db->commit();
        
        // Get the created/updated item data
        $sql = "SELECT 
                    id,
                    category_id,
                    question as item_text,
                    description,
                    order_index as sequence_order,
                    created_at
                FROM $tableName
                WHERE id = :id";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $itemId]);
        $item = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($item) {
            // Convert types
            $item['id'] = (int)$item['id'];
            $item['category_id'] = (int)$item['category_id'];
            $item['sequence_order'] = (int)$item['sequence_order'];
            $item['is_active'] = 1; // Default active
            
            Response::success(
                $item,
                $input['id'] ? 'Item updated successfully' : 'Item created successfully'
            );
        } else {
            Response::error('Failed to retrieve item data', 500);
        }
        
    } catch (PDOException $e) {
        $db->rollBack();
        error_log("PDOException during item save: " . $e->getMessage());
        error_log("Error Code: " . $e->getCode());
        throw $e;
    }
    
} catch (Exception $e) {
    error_log('Item Save Error: ' . $e->getMessage());
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
