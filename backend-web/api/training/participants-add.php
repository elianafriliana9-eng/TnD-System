<?php
/**
 * Training Participants API
 * Add participants to training session
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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['session_id']) || !isset($data['participants'])) {
        Response::error('Session ID and participants required', 400);
    }
    
    $db = Database::getInstance()->getConnection();
    $sessionId = $data['session_id'];
    $participants = $data['participants'];
    
    // Verify session exists and user owns it
    $stmt = $db->prepare("SELECT trainer_id FROM training_sessions WHERE id = :id");
    $stmt->execute([':id' => $sessionId]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        Response::error('Training session not found', 404);
    }
    
    if ($session['trainer_id'] != $_SESSION['user_id'] && $_SESSION['role'] !== 'super_admin') {
        Response::error('Unauthorized', 403);
    }
    
    $db->beginTransaction();
    
    $addedParticipants = [];
    
    foreach ($participants as $participant) {
        $sql = "INSERT INTO training_participants 
                (session_id, staff_name, position, phone, notes)
                VALUES 
                (:session_id, :staff_name, :position, :phone, :notes)";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([
            ':session_id' => $sessionId,
            ':staff_name' => $participant['staff_name'],
            ':position' => $participant['position'] ?? null,
            ':phone' => $participant['phone'] ?? null,
            ':notes' => $participant['notes'] ?? null
        ]);
        
        $participantId = $db->lastInsertId();
        $addedParticipants[] = [
            'id' => $participantId,
            'staff_name' => $participant['staff_name'],
            'position' => $participant['position'] ?? null
        ];
    }
    
    // Update total_staff count
    $stmt = $db->prepare("
        UPDATE training_sessions 
        SET total_staff = (SELECT COUNT(*) FROM training_participants WHERE session_id = :session_id)
        WHERE id = :session_id
    ");
    $stmt->execute([':session_id' => $sessionId]);
    
    $db->commit();
    
    Response::success([
        'message' => 'Participants added successfully',
        'participants' => $addedParticipants,
        'total' => count($addedParticipants)
    ], 201);
    
} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    Response::error('Server error: ' . $e->getMessage(), 500);
}
