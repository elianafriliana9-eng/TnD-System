<?php
/**
 * Training Checklists API
 * Get all training checklists
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
    
    // Get all active training checklists
    $sql = "SELECT 
                tc.id,
                tc.name,
                tc.description,
                tc.is_active,
                tc.created_at,
                COUNT(DISTINCT tcat.id) as total_categories,
                COUNT(ti.id) as total_points
            FROM training_checklists tc
            LEFT JOIN training_categories tcat ON tc.id = tcat.checklist_id
            LEFT JOIN training_items ti ON tcat.id = ti.category_id
            WHERE tc.is_active = 1
            GROUP BY tc.id
            ORDER BY tc.name ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $checklists = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format response for mobile compatibility
    $formatted = array_map(function($checklist) {
        return [
            'id' => (int)$checklist['id'],
            'name' => $checklist['name'],
            'checklist_name' => $checklist['name'], // Alias for compatibility
            'description' => $checklist['description'],
            'is_active' => (int)$checklist['is_active'],
            'total_categories' => (int)$checklist['total_categories'],
            'total_points' => (int)$checklist['total_points'],
            'created_at' => $checklist['created_at']
        ];
    }, $checklists);
    
    Response::success($formatted, 'Training checklists retrieved successfully');
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
