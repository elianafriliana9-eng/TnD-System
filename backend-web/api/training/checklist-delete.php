<?php
/**
 * Delete Training Checklist API
 * Delete training checklist (soft delete by setting is_active = 0)
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
    
    // Get checklist ID from query parameter
    $checklistId = $_GET['id'] ?? null;
    
    if (!$checklistId) {
        Response::error('Checklist ID is required', 400);
    }
    
    // Check if checklist exists
    $sql = "SELECT id, name FROM training_checklists WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $checklistId]);
    $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$checklist) {
        Response::error('Checklist not found', 404);
    }
    
    // Check if checklist is being used in any sessions
    $sql = "SELECT COUNT(*) as session_count FROM training_sessions WHERE checklist_id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $checklistId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result['session_count'] > 0) {
        // Soft delete - set is_active = 0
        $sql = "UPDATE training_checklists SET is_active = 0, updated_at = NOW() WHERE id = :id";
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $checklistId]);
        
        Response::success(null, 'Checklist has been deactivated because it is used in training sessions');
    } else {
        // Hard delete - remove completely
        $db->beginTransaction();
        
        try {
            // Delete points
            $sql = "DELETE ti FROM training_items ti 
                    INNER JOIN training_categories tc ON ti.category_id = tc.id 
                    WHERE tc.checklist_id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':id' => $checklistId]);
            
            // Delete categories
            $sql = "DELETE FROM training_categories WHERE checklist_id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':id' => $checklistId]);
            
            // Delete checklist
            $sql = "DELETE FROM training_checklists WHERE id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':id' => $checklistId]);
            
            $db->commit();
            
            Response::success(null, 'Checklist deleted successfully');
            
        } catch (Exception $e) {
            $db->rollBack();
            throw $e;
        }
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
