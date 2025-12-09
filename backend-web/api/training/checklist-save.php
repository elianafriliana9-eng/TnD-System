<?php
/**
 * Save Training Checklist API
 * Create or update training checklist with categories and points
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
    error_log('Raw input: ' . $rawInput);
    $input = json_decode($rawInput, true);
    error_log('Decoded input: ' . json_encode($input));
    error_log('JSON error: ' . json_last_error_msg());
    
    // Validate input is not null
    if ($input === null) {
        error_log('JSON decode failed');
        Response::error('Invalid JSON input: ' . json_last_error_msg(), 400);
    }
    
    // Determine if this is a checklist creation or item creation
    $isItemCreation = isset($input['category_id']) && !empty($input['category_id']);
    
    if ($isItemCreation) {
        // ===== ITEM CREATION/UPDATE LOGIC =====
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
        
        // Determine which table to use (training_points or training_items)
        $tableName = 'training_items'; // default
        
        // Check which table to use based on what exists and has data
        $tableCheckLog = "Table selection logic: ";
        
        try {
            // First, check if training_points table exists and has data for this category
            $checkStmt = $db->prepare("SELECT COUNT(*) as cnt FROM training_points WHERE category_id = ?");
            $checkStmt->execute([(int)$input['category_id']]);
            $pointsCount = $checkStmt->fetchColumn();
            $tableCheckLog .= "training_points has $pointsCount records for category. ";
            
            if ($pointsCount > 0) {
                $tableName = 'training_points';
                $tableCheckLog .= "Selected training_points (has data).";
            } else {
                // Try to check if training_points table structure is valid
                try {
                    $structCheck = $db->query("SELECT 1 FROM training_points LIMIT 1");
                    $tableName = 'training_points';
                    $tableCheckLog .= "Selected training_points (table exists, empty).";
                } catch (PDOException $e) {
                    $tableName = 'training_items';
                    $tableCheckLog .= "Selected training_items (training_points doesn't exist).";
                }
            }
        } catch (PDOException $e) {
            // If even querying training_points fails, use training_items
            $tableName = 'training_items';
            $tableCheckLog .= "ERROR querying training_points: " . $e->getMessage() . ". Defaulting to training_items.";
        }
        
        error_log($tableCheckLog);
        error_log("Using table: $tableName for category_id: " . $input['category_id']);
        
        // Validate that category_id exists in training_categories
        $validateStmt = $db->prepare("SELECT id, name FROM training_categories WHERE id = ?");
        $validateStmt->execute([(int)$input['category_id']]);
        $categoryExists = $validateStmt->fetch(PDO::FETCH_ASSOC);
        
        $categoryId = (int)$input['category_id'];
        error_log("Category validation for ID: $categoryId");
        
        if ($categoryExists) {
            error_log("✓ Category found: {$categoryExists['name']} (ID: {$categoryExists['id']})");
        } else {
            error_log("✗ Category ID $categoryId NOT FOUND in training_categories table");
            
            // Get all available categories for debugging
            $allCats = $db->query("SELECT id, name FROM training_categories ORDER BY id")->fetchAll(PDO::FETCH_ASSOC);
            error_log("Available categories: " . json_encode($allCats));
            
            Response::error('Category ID ' . $categoryId . ' does not exist in training_categories. Available IDs: ' . implode(', ', array_map(function($c) { return $c['id']; }, $allCats)), 400);
        }
        
        // Start transaction
        $db->beginTransaction();
        
        $itemId = $input['id'] ?? null;
        
        try {
            if ($itemId) {
                // Update existing item
                $sql = "UPDATE $tableName 
                        SET question = :question, 
                            description = :description,
                            order_index = :order_index,
                            category_id = :category_id
                        WHERE id = :id";
                error_log("Executing UPDATE: $sql with category_id: " . $input['category_id']);
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
                $sql = "INSERT INTO $tableName (category_id, question, description, order_index, created_at) 
                        VALUES (:category_id, :question, :description, :order_index, NOW())";
                error_log("Executing INSERT: $sql with category_id: " . $input['category_id']);
                error_log("Full payload: " . json_encode($input));
                $stmt = $db->prepare($sql);
                $stmt->execute([
                    ':category_id' => (int)$input['category_id'],
                    ':question' => $input['item_text'],
                    ':description' => $input['description'],
                    ':order_index' => $input['order_index']
                ]);
                $itemId = $db->lastInsertId();
                error_log("Item inserted successfully with ID: $itemId");
            }
            
            // Commit transaction
            $db->commit();
            error_log("Transaction committed successfully for table: $tableName");
        } catch (PDOException $e) {
            $db->rollBack();
            error_log("PDOException during INSERT/UPDATE: " . $e->getMessage());
            error_log("Error Code: " . $e->getCode());
            error_log("Using table: $tableName, category_id: " . $input['category_id']);
            throw $e;
        }
        
        // Get the created/updated item data
        $sql = "SELECT 
                    id,
                    category_id,
                    question as item_text,
                    description,
                    order_index,
                    created_at
                FROM $tableName
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
        
    } else {
        // ===== CHECKLIST CREATION/UPDATE LOGIC =====
        // Validate required fields - check if key exists AND is not empty (trim for spaces)
        if (!isset($input['name']) || trim((string)$input['name']) === '') {
            error_log('Name field is empty or not set. Input: ' . json_encode($input));
            Response::error('Checklist name is required', 400);
        }
        
        if (empty($input['categories']) || !is_array($input['categories'])) {
            Response::error('At least one category is required', 400);
        }
        
        // Trim the name value
        $input['name'] = trim((string)$input['name']);
        
        // Start transaction
        $db->beginTransaction();
        
        $checklistId = $input['id'] ?? null;
        
        if ($checklistId) {
            // Update existing checklist
            $sql = "UPDATE training_checklists 
                    SET name = :name, 
                        description = :description, 
                        updated_at = NOW() 
                    WHERE id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                ':name' => $input['name'],
                ':description' => $input['description'] ?? '',
                ':id' => $checklistId
            ]);
            
            // Delete existing categories and points (will cascade)
            $sql = "DELETE FROM training_items WHERE category_id IN 
                    (SELECT id FROM training_categories WHERE checklist_id = :checklist_id)";
            $stmt = $db->prepare($sql);
            $stmt->execute([':checklist_id' => $checklistId]);
            
            $sql = "DELETE FROM training_categories WHERE checklist_id = :checklist_id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':checklist_id' => $checklistId]);
            
        } else {
            // Create new checklist
            $sql = "INSERT INTO training_checklists (name, description, is_active, created_at) 
                    VALUES (:name, :description, 1, NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                ':name' => (string)$input['name'],
                ':description' => (string)($input['description'] ?? '')
            ]);
            $checklistId = $db->lastInsertId();
        }
        
        // Insert categories and points
        $categoryOrder = 0;
        foreach ($input['categories'] as $category) {
            $categoryOrder++;
            
            // Insert category
            $sql = "INSERT INTO training_categories (checklist_id, name, order_index, created_at) 
                    VALUES (:checklist_id, :name, :order_index, NOW())";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                ':checklist_id' => $checklistId,
                ':name' => $category['name'],
                ':order_index' => $categoryOrder
            ]);
            $categoryId = $db->lastInsertId();
            
            // Insert points for this category
            if (!empty($category['points']) && is_array($category['points'])) {
                $pointOrder = 0;
                foreach ($category['points'] as $point) {
                    $pointOrder++;
                    
                    $sql = "INSERT INTO training_items (category_id, question, order_index, created_at) 
                            VALUES (:category_id, :question, :order_index, NOW())";
                    $stmt = $db->prepare($sql);
                    $stmt->execute([
                        ':category_id' => $categoryId,
                        ':question' => $point,
                        ':order_index' => $pointOrder
                    ]);
                }
            }
        }
        
        // Commit transaction
        $db->commit();
        
        // Get the complete checklist data
        $sql = "SELECT 
                    tc.id,
                    tc.name,
                    tc.description,
                    tc.is_active,
                    tc.created_at,
                    COUNT(DISTINCT tcat.id) as categories_count,
                    COUNT(ti.id) as points_count
                FROM training_checklists tc
                LEFT JOIN training_categories tcat ON tc.id = tcat.checklist_id
                LEFT JOIN training_items ti ON tcat.id = ti.category_id
                WHERE tc.id = :id
                GROUP BY tc.id";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $checklistId]);
        $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
        
        Response::success(
            $checklist, 
            $input['id'] ? 'Checklist updated successfully' : 'Checklist created successfully'
        );
    }
    
} catch (Exception $e) {
    // Rollback on error
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    
    // Enhanced error logging for FK constraint violations
    $errorMsg = $e->getMessage();
    error_log("=== EXCEPTION IN CHECKLIST-SAVE ===");
    error_log("Error: $errorMsg");
    error_log("Raw input: " . json_encode($input ?? []));
    error_log("Is Item Creation: " . json_encode($isItemCreation ?? false));
    if (isset($tableName)) {
        error_log("Table being used: $tableName");
    }
    if (isset($input['category_id'])) {
        error_log("Category ID: " . $input['category_id']);
    }
    error_log("=== END EXCEPTION ===");
    
    Response::error('Server error: ' . $e->getMessage(), 500);
}
