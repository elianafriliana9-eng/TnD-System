<?php
/**
 * Delete Training Session API
 * Delete or cancel training session
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
    
    // Get session ID from query parameter
    $sessionId = $_GET['id'] ?? null;
    
    if (!$sessionId) {
        Response::error('Session ID is required', 400);
    }
    
    // Check if session exists
    $sql = "SELECT id, status, session_date FROM training_sessions WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $sessionId]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        Response::error('Training session not found', 404);
    }
    
    // Check session status and determine action
    if ($session['status'] === 'completed') {
        // Don't allow deletion of completed sessions
        Response::error('Cannot delete completed sessions. Completed sessions contain important training data.', 400);
    }
    
    // Check if session has participants
    $sql = "SELECT COUNT(*) as participant_count FROM training_participants WHERE session_id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $sessionId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $hasParticipants = $result['participant_count'] > 0;
    
    // Check if session has responses
    $sql = "SELECT COUNT(*) as response_count FROM training_responses WHERE session_id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $sessionId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $hasResponses = $result['response_count'] > 0;
    
    // Check if session has photos
    $sql = "SELECT COUNT(*) as photo_count FROM training_photos WHERE session_id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $sessionId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $hasPhotos = $result['photo_count'] > 0;
    
    $db->beginTransaction();
    
    try {
        if ($hasParticipants || $hasResponses || $hasPhotos) {
            // Soft delete - change status to cancelled
            $sql = "UPDATE training_sessions 
                    SET status = 'cancelled', 
                        updated_at = NOW() 
                    WHERE id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':id' => $sessionId]);
            
            $db->commit();
            
            Response::success(null, 'Training session has been cancelled because it contains training data (participants, responses, or photos)');
        } else {
            // Hard delete - completely remove from database
            // Delete in order to respect foreign key constraints
            
            // Note: No need to delete participants, responses, photos since they don't exist
            
            // Delete session
            $sql = "DELETE FROM training_sessions WHERE id = :id";
            $stmt = $db->prepare($sql);
            $stmt->execute([':id' => $sessionId]);
            
            $db->commit();
            
            Response::success(null, 'Training session deleted successfully');
        }
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
