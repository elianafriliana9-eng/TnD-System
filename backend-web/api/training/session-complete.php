<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
require_once '../../config/database.php';
require_once '../../utils/Auth.php';
require_once '../../utils/Response.php';
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
    $input = json_decode(file_get_contents('php://input'), true);
    if (!isset($input['session_id'])) {
        Response::error('Missing required field: session_id', 400);
    }
    $session_id = (int)$input['session_id'];
    $end_time = $input['end_time'] ?? date('H:i:s');
    $notes = $input['notes'] ?? null;
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare("SELECT ts.*, u.full_name as trainer_name FROM training_sessions ts JOIN users u ON ts.trainer_id = u.id WHERE ts.id = ?");
    $stmt->execute([$session_id]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$session) {
        Response::error('Training session not found', 404);
    }
    if ($session['status'] === 'completed') {
        Response::error('Session is already completed', 400);
    }
    $auth_id = Auth::id();
    if ($session['trainer_id'] != $auth_id) {
        Response::error('You do not have permission to complete this session', 403);
    }
    $update_stmt = $db->prepare("UPDATE training_sessions SET status = 'completed', end_time = ?, notes = ?, updated_at = NOW() WHERE id = ?");
    $update_stmt->execute([$end_time, $notes, $session_id]);
    Response::success([
        'session_id' => (int)$session['id'],
        'session_date' => $session['session_date'],
        'start_time' => $session['start_time'],
        'end_time' => $end_time,
        'status' => 'completed',
        'trainer_name' => $session['trainer_name'],
        'notes' => $notes,
        'completed_at' => date('Y-m-d H:i:s')
    ], 'Training session completed successfully');
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
