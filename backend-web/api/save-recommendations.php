<?php
/**
 * Save Improvement Recommendation API
 * Save recommendation text for NOK findings
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

// Get current user
$currentUser = Auth::user();

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
    exit;
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['visit_id']) || !isset($input['recommendations'])) {
        Response::error('Visit ID and recommendations required', 400);
        exit;
    }
    
    $visitId = $input['visit_id'];
    $recommendations = $input['recommendations']; // Array of {response_id, recommendation_text}
    
    // Role-based filtering - DISABLED to allow all users to save recommendations
    // if ($currentUser['role'] !== 'super_admin') {
    //     $stmt = $db->prepare("SELECT user_id FROM visits WHERE id = ?");
    //     $stmt->execute([$visitId]);
    //     $visit = $stmt->fetch(PDO::FETCH_ASSOC);
    //     
    //     if (!$visit || $visit['user_id'] != $currentUser['id']) {
    //         Response::error('Unauthorized or visit not found', 403);
    //         exit;
    //     }
    // }
    
    // Start transaction
    $db->beginTransaction();
    
    try {
        // Update each recommendation
        // Production table has NO 'recommendation' or 'updated_at' columns
        // Save recommendation_text to 'notes' column instead
        foreach ($recommendations as $rec) {
            if (!isset($rec['response_id']) || !isset($rec['recommendation_text'])) {
                continue;
            }
            
            // Append recommendation to notes (or overwrite if empty)
            $sql = "UPDATE visit_checklist_responses 
                    SET notes = ?
                    WHERE id = ? 
                    AND visit_id = ?";
            
            $stmt = $db->prepare($sql);
            $stmt->execute([
                $rec['recommendation_text'],
                $rec['response_id'],
                $visitId
            ]);
        }
        
        // Update visit status if provided
        if (isset($input['status'])) {
            $stmt = $db->prepare("UPDATE visits SET status = ? WHERE id = ?");
            $stmt->execute([$input['status'], $visitId]);
        }
        
        $db->commit();
        
        Response::success([
            'message' => 'Recommendations saved successfully',
            'visit_id' => $visitId,
            'updated_count' => count($recommendations)
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
