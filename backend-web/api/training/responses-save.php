<?php
/**
 * Training Responses - Save Evaluation Scores
 * 
 * Saves evaluation scores for training points during a session
 * 
 * @endpoint POST /api/training/responses-save.php
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

// Check authentication
$auth = Auth::checkAuth();
if (!$auth['authenticated']) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Authentication required'
    ]);
    exit();
}

// Only POST method allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit();
}

// Get request body
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['session_id', 'responses'];
foreach ($required_fields as $field) {
    if (!isset($input[$field])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => "Missing required field: $field"
        ]);
        exit();
    }
}

$session_id = $input['session_id'];
$responses = $input['responses']; // Array of {participant_id, point_id, score, notes}

try {
    $db = new Database();
    $conn = $db->getConnection();
    
    // Verify session exists and user has access
    $stmt = $conn->prepare("
        SELECT ts.*, tc.checklist_name 
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        WHERE ts.id = ?
    ");
    $stmt->execute([$session_id]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Training session not found'
        ]);
        exit();
    }
    
    // Check if session is already completed
    if ($session['status'] === 'completed') {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Cannot modify completed session'
        ]);
        exit();
    }
    
    // Only trainer who created session or admin can save responses
    if ($auth['role'] !== 'super_admin' && 
        $auth['role'] !== 'admin' && 
        $session['trainer_id'] != $auth['user_id']) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'You do not have permission to modify this session'
        ]);
        exit();
    }
    
    // Validate responses array
    if (!is_array($responses) || empty($responses)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Responses must be a non-empty array'
        ]);
        exit();
    }
    
    // Begin transaction
    $conn->beginTransaction();
    
    $saved_responses = [];
    $insert_stmt = $conn->prepare("
        INSERT INTO training_responses 
        (session_id, participant_id, point_id, score, notes, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
            score = VALUES(score),
            notes = VALUES(notes),
            updated_at = NOW()
    ");
    
    foreach ($responses as $response) {
        // Validate each response
        if (!isset($response['participant_id']) || 
            !isset($response['point_id']) || 
            !isset($response['score'])) {
            $conn->rollBack();
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Each response must have participant_id, point_id, and score'
            ]);
            exit();
        }
        
        $participant_id = $response['participant_id'];
        $point_id = $response['point_id'];
        $score = $response['score'];
        $notes = isset($response['notes']) ? $response['notes'] : null;
        
        // Validate score (1-5)
        if (!is_numeric($score) || $score < 1 || $score > 5) {
            $conn->rollBack();
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Score must be between 1 and 5'
            ]);
            exit();
        }
        
        // Verify participant belongs to this session
        $check_stmt = $conn->prepare("
            SELECT id FROM training_participants 
            WHERE id = ? AND session_id = ?
        ");
        $check_stmt->execute([$participant_id, $session_id]);
        if (!$check_stmt->fetch()) {
            $conn->rollBack();
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => "Participant $participant_id not found in this session"
            ]);
            exit();
        }
        
        // Insert or update response
        $insert_stmt->execute([
            $session_id,
            $participant_id,
            $point_id,
            $score,
            $notes
        ]);
        
        $saved_responses[] = [
            'participant_id' => $participant_id,
            'point_id' => $point_id,
            'score' => $score,
            'notes' => $notes
        ];
    }
    
    // Update session status to 'in_progress' if still 'pending'
    if ($session['status'] === 'pending') {
        $update_stmt = $conn->prepare("
            UPDATE training_sessions 
            SET status = 'in_progress', updated_at = NOW()
            WHERE id = ?
        ");
        $update_stmt->execute([$session_id]);
    }
    
    // Commit transaction
    $conn->commit();
    
    // Get updated statistics
    $stats_stmt = $conn->prepare("
        SELECT 
            COUNT(DISTINCT participant_id) as participants_evaluated,
            COUNT(*) as total_responses,
            AVG(score) as average_score,
            MIN(score) as min_score,
            MAX(score) as max_score
        FROM training_responses
        WHERE session_id = ?
    ");
    $stats_stmt->execute([$session_id]);
    $stats = $stats_stmt->fetch(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => count($saved_responses) . ' responses saved successfully',
        'data' => [
            'session_id' => $session_id,
            'responses_saved' => count($saved_responses),
            'statistics' => [
                'participants_evaluated' => (int)$stats['participants_evaluated'],
                'total_responses' => (int)$stats['total_responses'],
                'average_score' => round((float)$stats['average_score'], 2),
                'min_score' => (int)$stats['min_score'],
                'max_score' => (int)$stats['max_score']
            ]
        ]
    ]);
    
} catch (PDOException $e) {
    if (isset($conn) && $conn->inTransaction()) {
        $conn->rollBack();
    }
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>
