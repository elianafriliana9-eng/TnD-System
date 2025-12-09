<?php
/**
 * Start Training Session API - Actual Start
 * Change status from 'scheduled' to 'ongoing' when trainer actually starts the session
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';
require_once '../../utils/Response.php';
require_once '../../utils/Auth.php';

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    $data = json_decode(file_get_contents('php://input'), true);

    // Validate required fields
    if (!isset($data['session_id'])) {
        Response::error('Session ID required', 400);
    }

    $sessionId = $data['session_id'];

    $db = Database::getInstance()->getConnection();

    // Get the session details
    $stmt = $db->prepare("
        SELECT ts.*, o.name as outlet_name, u.full_name as trainer_name, tc.name as checklist_name, ts.crew_name
        FROM training_sessions ts
        LEFT JOIN outlets o ON ts.outlet_id = o.id
        LEFT JOIN users u ON ts.trainer_id = u.id
        LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id
        WHERE ts.id = :id
    ");
    $stmt->execute([':id' => $sessionId]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$session) {
        Response::error('Training session not found', 404);
    }

    // Check if session is already ongoing or completed
    if ($session['status'] === 'ongoing' || $session['status'] === 'completed') {
        Response::error('Training session is already ' . $session['status'], 400);
    }

    // Get trainer_id from session or request
    $trainerId = $data['trainer_id'] ?? ($_SESSION['user_id'] ?? $session['trainer_id']);
    
    if (!$trainerId) {
        Response::error('Trainer ID required', 400);
    }

    // Verify this is the correct trainer or admin
    if ($trainerId != $session['trainer_id']) {
        Response::error('You are not authorized to start this session', 403);
    }

    // Update the session status to 'ongoing'
    $update_stmt = $db->prepare("UPDATE training_sessions SET status = 'ongoing', updated_at = NOW() WHERE id = :id");
    $update_stmt->execute([':id' => $sessionId]);

    // Get updated session details
    $stmt = $db->prepare("
        SELECT ts.*, o.name as outlet_name, u.full_name as trainer_name, tc.name as checklist_name, ts.crew_name
        FROM training_sessions ts
        LEFT JOIN outlets o ON ts.outlet_id = o.id
        LEFT JOIN users u ON ts.trainer_id = u.id
        LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id
        WHERE ts.id = :id
    ");
    $stmt->execute([':id' => $sessionId]);
    $updatedSession = $stmt->fetch(PDO::FETCH_ASSOC);

    Response::success([
        'message' => 'Training session started successfully',
        'session' => $updatedSession
    ], 'Training session started', 200);

} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}