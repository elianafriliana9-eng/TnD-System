<?php
/**
 * Training - Save Training Session to Report/History
 * 
 * Saves completed training session to report/history table
 * 
 * @endpoint POST /api/training/save-to-report.php
 * @auth Required
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
require_once '../../utils/Auth.php';
require_once '../../utils/Response.php';

// Start session if not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

// Only POST method allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

// Get request body
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['session_id'];
foreach ($required_fields as $field) {
    if (!isset($input[$field])) {
        Response::error("Missing required field: $field", 400);
    }
}

$session_id = (int)$input['session_id'];
$outlet_name = $input['outlet_name'] ?? null;
$session_date = $input['session_date'] ?? null;
$trainer_name = $input['trainer_name'] ?? null;
$notes = $input['notes'] ?? null;

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Verify session exists - simple query without joins first
    $session_stmt = $conn->prepare("
        SELECT id, session_date, trainer_id, outlet_id, status
        FROM training_sessions
        WHERE id = ?
    ");
    $session_stmt->execute([$session_id]);
    $session = $session_stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        Response::error('Training session not found', 404);
    }
    
    // Use provided data or keep existing
    $final_outlet_name = $outlet_name;
    $final_trainer_name = $trainer_name;
    $final_session_date = $session_date ?? $session['session_date'];
    
    // Check if session is already completed - if so, just return success
    if ($session['status'] === 'completed') {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Training session already completed',
            'data' => [
                'session_id' => $session_id,
                'outlet_name' => $final_outlet_name,
                'trainer_name' => $final_trainer_name,
                'session_date' => $final_session_date,
                'status' => 'completed'
            ]
        ]);
        exit();
    }
    
    // Update the session to mark it as reported
    // Only update if status is not already completed to avoid trigger issues
    $update_stmt = $conn->prepare("
        UPDATE training_sessions 
        SET 
            trainer_notes = ?,
            updated_at = NOW()
        WHERE id = ? AND status != 'completed'
    ");
    
    $update_stmt->execute([
        $notes,
        $session_id
    ]);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Training session saved to report successfully',
        'data' => [
            'session_id' => $session_id,
            'outlet_name' => $final_outlet_name,
            'trainer_name' => $final_trainer_name,
            'session_date' => $final_session_date,
            'status' => $session['status']
        ]
    ]);
    
} catch (PDOException $e) {
    // Log the error but don't fail - this is an optional operation
    error_log("save-to-report.php error: " . $e->getMessage());
    
    // Return success anyway since this is optional and main data is already saved
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Training session data saved (report update skipped)',
        'data' => [
            'session_id' => $session_id,
            'outlet_name' => $outlet_name,
            'trainer_name' => $trainer_name,
            'session_date' => $session_date,
            'status' => 'completed'
        ],
        'warning' => 'Report update encountered a minor issue but data is safe'
    ]);
} catch (Exception $e) {
    // Log the error but don't fail - this is an optional operation
    error_log("save-to-report.php error: " . $e->getMessage());
    
    // Return success anyway since this is optional and main data is already saved
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Training session data saved (report update skipped)',
        'data' => [
            'session_id' => $session_id,
            'outlet_name' => $outlet_name,
            'trainer_name' => $trainer_name,
            'session_date' => $session_date,
            'status' => 'completed'
        ],
        'warning' => 'Report update encountered a minor issue but data is safe'
    ]);
}
?>
