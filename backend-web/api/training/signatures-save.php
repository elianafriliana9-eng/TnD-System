<?php
/**
 * Save Training Signatures API
 * 
 * Save signatures from staff, leader, and trainer
 * 
 * @endpoint POST /api/training/signatures-save.php
 * @auth Required
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

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

// Start session
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

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
if (!isset($input['session_id'])) {
    Response::error('Session ID is required', 400);
}

$sessionId = $input['session_id'];

// Support both array format (from mobile) and individual fields format (from web)
if (isset($input['signatures']) && is_array($input['signatures'])) {
    // Array format from mobile
    $signatures = $input['signatures'];
} else {
    // Individual fields format
    if (!isset($input['staff_name']) || empty(trim($input['staff_name']))) {
        Response::error('Staff name is required', 400);
    }
    if (!isset($input['leader_name']) || empty(trim($input['leader_name']))) {
        Response::error('Leader name is required', 400);
    }
    if (!isset($input['trainer_name']) || empty(trim($input['trainer_name']))) {
        Response::error('Trainer name is required', 400);
    }
    
    $signatures = [
        ['role' => 'staff', 'name' => trim($input['staff_name']), 'position' => trim($input['staff_position'] ?? '')],
        ['role' => 'leader', 'name' => trim($input['leader_name']), 'position' => trim($input['leader_position'] ?? '')],
        ['role' => 'trainer', 'name' => trim($input['trainer_name']), 'position' => trim($input['trainer_position'] ?? '')],
    ];
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Verify session exists
    $stmt = $db->prepare("SELECT id FROM training_sessions WHERE id = ?");
    $stmt->execute([$sessionId]);
    if (!$stmt->fetch()) {
        Response::error('Training session not found', 404);
    }
    
    $db->beginTransaction();
    
    // Update crew_name in training_sessions if provided
    if (isset($input['crew_name']) && !empty($input['crew_name'])) {
        $stmt = $db->prepare("UPDATE training_sessions SET crew_name = ? WHERE id = ?");
        $stmt->execute([trim($input['crew_name']), $sessionId]);
    }
    
    // Delete existing signatures for this session
    $stmt = $db->prepare("DELETE FROM training_signatures WHERE session_id = ?");
    $stmt->execute([$sessionId]);
    
    // Insert signatures
    $stmt = $db->prepare("
        INSERT INTO training_signatures 
        (session_id, signature_type, signer_name, signer_position, signed_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    
    foreach ($signatures as $sig) {
        $role = $sig['role'];
        $name = trim($sig['name']);
        $position = trim($sig['position'] ?? '');
        
        if (empty($name)) {
            continue; // Skip if name is empty
        }
        
        $stmt->execute([$sessionId, $role, $name, $position]);
    }
    
    $db->commit();
    
    Response::success([
        'message' => 'Signatures saved successfully',
        'session_id' => $sessionId,
        'signatures' => [
            'staff' => $staffName,
            'leader' => $leaderName,
            'trainer' => $trainerName
        ]
    ]);
    
} catch (PDOException $e) {
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Error saving signatures: " . $e->getMessage());
    Response::error('Failed to save signatures: ' . $e->getMessage(), 500);
}
