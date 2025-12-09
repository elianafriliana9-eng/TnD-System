<?php
/**
 * Training Materials API
 * Get list of training materials
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

try {
    $db = Database::getInstance()->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Get all materials or specific material
        if (isset($_GET['id'])) {
            $stmt = $db->prepare("
                SELECT * FROM training_materials 
                WHERE id = ? 
                ORDER BY uploaded_at DESC
            ");
            $stmt->execute([$_GET['id']]);
            $material = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($material) {
                Response::success($material, 'Material retrieved successfully');
            } else {
                Response::error('Material not found', 404);
            }
        } else {
            // Get all materials
            $stmt = $db->prepare("
                SELECT * FROM training_materials 
                ORDER BY uploaded_at DESC
            ");
            $stmt->execute();
            $materials = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            Response::success($materials, 'Materials retrieved successfully');
        }
    } 
    
    elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        // Delete material
        if (!isset($_GET['id'])) {
            Response::error('Material ID required', 400);
        }
        
        // Get file paths before delete
        $stmt = $db->prepare("SELECT file_path, thumbnail_path FROM training_materials WHERE id = ?");
        $stmt->execute([$_GET['id']]);
        $material = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$material) {
            Response::error('Material not found', 404);
        }
        
        // Delete from database
        $stmt = $db->prepare("DELETE FROM training_materials WHERE id = ?");
        $stmt->execute([$_GET['id']]);
        
        // Delete files from server
        $baseDir = __DIR__ . '/../../';
        if ($material['file_path'] && file_exists($baseDir . $material['file_path'])) {
            unlink($baseDir . $material['file_path']);
        }
        if ($material['thumbnail_path'] && file_exists($baseDir . $material['thumbnail_path'])) {
            unlink($baseDir . $material['thumbnail_path']);
        }
        
        Response::success(null, 'Material deleted successfully');
    }
    
    else {
        Response::error('Method not allowed', 405);
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
