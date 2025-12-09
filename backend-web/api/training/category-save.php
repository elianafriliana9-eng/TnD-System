<?php
/**
 * Training Category Save API
 * Create or update a training category
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

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        Response::error('Method not allowed', 405);
    }

    $db = Database::getInstance()->getConnection();
    
    // Get JSON input
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    
    if ($input === null) {
        Response::error('Invalid JSON input', 400);
    }

    // Validate input
    if (!isset($input['name']) || empty(trim($input['name']))) {
        Response::error('Category name is required', 400);
    }

    $name = trim($input['name']);
    $description = trim($input['description'] ?? '');
    $categoryId = $input['id'] ?? null;

    // Get active checklist if not specified
    $checklistId = $input['checklist_id'] ?? null;
    if (!$checklistId) {
        $stmt = $db->prepare("SELECT id FROM training_checklists WHERE is_active = 1 LIMIT 1");
        $stmt->execute();
        $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$checklist) {
            Response::error('No active checklist found. Please create a checklist first.', 400);
        }
        $checklistId = $checklist['id'];
    }

    $db->beginTransaction();

    if ($categoryId) {
        // Update existing category
        $sql = "UPDATE training_categories 
                SET name = :name, description = :description
                WHERE id = :id AND checklist_id = :checklist_id";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':name' => $name,
            ':description' => $description,
            ':id' => $categoryId,
            ':checklist_id' => $checklistId
        ]);
    } else {
        // Create new category - get next order_index
        $maxOrderSql = "SELECT COALESCE(MAX(order_index), 0) + 1 as next_order 
                       FROM training_categories 
                       WHERE checklist_id = :checklist_id";
        $maxOrderStmt = $db->prepare($maxOrderSql);
        $maxOrderStmt->execute([':checklist_id' => $checklistId]);
        $orderIndex = (int)$maxOrderStmt->fetchColumn();
        
        $sql = "INSERT INTO training_categories (checklist_id, name, description, order_index, created_at)
                VALUES (:checklist_id, :name, :description, :order_index, NOW())";
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':checklist_id' => $checklistId,
            ':name' => $name,
            ':description' => $description,
            ':order_index' => $orderIndex
        ]);
        $categoryId = $db->lastInsertId();
    }

    $db->commit();

    // Fetch and return the category
    $sql = "SELECT id, name, description, order_index, created_at
            FROM training_categories
            WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $categoryId]);
    $category = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($category) {
        $category['id'] = (int)$category['id'];
        $category['order_index'] = (int)$category['order_index'];
        $category['is_active'] = 1; // Default active
    }

    Response::success(
        $category,
        $input['id'] ? 'Category updated successfully' : 'Category created successfully'
    );

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
