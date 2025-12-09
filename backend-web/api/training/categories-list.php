<?php
/**
 * Training Categories API
 * Get all categories for a specific or active checklist
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
    $db = Database::getInstance()->getConnection();
    
    // Get checklist_id from parameter or use active checklist
    $checklistId = isset($_GET['checklist_id']) ? (int)$_GET['checklist_id'] : null;
    
    if (!$checklistId) {
        // Get first active checklist
        $sql = "SELECT id FROM training_checklists WHERE is_active = 1 LIMIT 1";
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$checklist) {
            // Auto-create default checklist if none exists
            error_log("No active checklist found, creating default checklist");
            $createSql = "INSERT INTO training_checklists (name, description, is_active, created_at) 
                         VALUES ('Default Training Checklist', 'Auto-generated checklist', 1, NOW())";
            $db->exec($createSql);
            $checklistId = $db->lastInsertId();
            error_log("Created default checklist with ID: $checklistId");
        } else {
            $checklistId = $checklist['id'];
        }
    }
    
    // Get categories for this checklist
    $sql = "SELECT 
                id,
                name,
                description,
                order_index,
                created_at
            FROM training_categories
            WHERE checklist_id = :checklist_id
            ORDER BY order_index ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute([':checklist_id' => $checklistId]);
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Convert types
    foreach ($categories as &$category) {
        $category['id'] = (int)$category['id'];
        $category['order_index'] = (int)$category['order_index'];
        $category['is_active'] = 1; // Default active
    }
    
    Response::success($categories, 'Categories retrieved successfully');
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
