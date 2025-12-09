<?php
/**
 * Training Checklist Detail API
 * Get checklist with categories and points
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

try {
    if (!isset($_GET['id'])) {
        Response::error('Checklist ID required', 400);
    }
    
    $checklistId = $_GET['id'];
    $db = Database::getInstance()->getConnection();
    
    // Get checklist info
    $sql = "SELECT * FROM training_checklists WHERE id = :id AND is_active = 1";
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':id', $checklistId);
    $stmt->execute();
    $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$checklist) {
        // Check if checklist exists but inactive
        $checkSql = "SELECT id, is_active FROM training_checklists WHERE id = :id";
        $checkStmt = $db->prepare($checkSql);
        $checkStmt->bindParam(':id', $checklistId);
        $checkStmt->execute();
        $checkResult = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($checkResult && $checkResult['is_active'] == 0) {
            Response::error('Checklist is inactive', 404);
        }
        
        Response::error('Checklist not found', 404);
    }
    
    // Get categories with points
    $sql = "SELECT 
                tc.id,
                tc.name as category_name,
                tc.description,
                tc.order_index as display_order
            FROM training_categories tc
            WHERE tc.checklist_id = :checklist_id
            ORDER BY tc.order_index ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':checklist_id', $checklistId);
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get points for each category
    foreach ($categories as &$category) {
        $sql = "SELECT 
                    id,
                    question as point_text,
                    order_index as display_order
                FROM training_items
                WHERE category_id = :category_id
                ORDER BY order_index ASC";
        
        $stmt = $db->prepare($sql);
        $stmt->bindParam(':category_id', $category['id']);
        $stmt->execute();
        $points = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert id to int for points
        foreach ($points as &$point) {
            $point['id'] = (int)$point['id'];
            $point['display_order'] = (int)$point['display_order'];
        }
        
        $category['points'] = $points;
        $category['id'] = (int)$category['id'];
        $category['display_order'] = (int)$category['display_order'];
    }
    
    $checklist['id'] = (int)$checklist['id'];
    $checklist['is_active'] = (int)$checklist['is_active'];
    $checklist['categories'] = $categories;
    
    Response::success($checklist);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
