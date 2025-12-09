<?php
/**
 * Save Training Evaluations API
 * 
 * Save point-by-point evaluations (baik/cukup/kurang) for a training session
 * 
 * @endpoint POST /api/training/evaluations-save.php
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

if (!isset($input['evaluations']) || !is_array($input['evaluations'])) {
    Response::error('Evaluations array is required', 400);
}

$sessionId = $input['session_id'];
$evaluations = $input['evaluations']; // Array of {point_id, rating, notes}

try {
    $db = Database::getInstance()->getConnection();
    
    // Verify session exists
    $stmt = $db->prepare("SELECT id FROM training_sessions WHERE id = ?");
    $stmt->execute([$sessionId]);
    if (!$stmt->fetch()) {
        Response::error('Training session not found', 404);
    }
    
    $db->beginTransaction();
    
    // Delete existing evaluations for this session (in case of re-submission)
    $stmt = $db->prepare("DELETE FROM training_evaluations WHERE session_id = ?");
    $stmt->execute([$sessionId]);
    
    // Insert new evaluations
    $stmt = $db->prepare("
        INSERT INTO training_evaluations (session_id, point_id, rating, notes, evaluated_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    
    $insertedCount = 0;
    foreach ($evaluations as $eval) {
        if (!isset($eval['point_id']) || !isset($eval['rating'])) {
            continue; // Skip invalid entries
        }
        
        $pointId = $eval['point_id'];
        $rating = strtolower($eval['rating']); // Normalize to lowercase
        $notes = $eval['notes'] ?? '';
        
        // Validate rating value
        if (!in_array($rating, ['baik', 'cukup', 'kurang'])) {
            continue; // Skip invalid rating
        }
        
        $stmt->execute([$sessionId, $pointId, $rating, $notes]);
        $insertedCount++;
    }
    
    $db->commit();
    
    Response::success([
        'message' => 'Evaluations saved successfully',
        'session_id' => $sessionId,
        'evaluations_count' => $insertedCount
    ]);
    
} catch (PDOException $e) {
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Error saving evaluations: " . $e->getMessage());
    Response::error('Failed to save evaluations: ' . $e->getMessage(), 500);
}
