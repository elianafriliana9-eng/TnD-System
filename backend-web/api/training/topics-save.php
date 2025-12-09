<?php
/**
 * Save Training Topics Delivered API
 * 
 * Save list of training topics/materials delivered to staff
 * 
 * @endpoint POST /api/training/topics-save.php
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

if (!isset($input['topics']) || !is_array($input['topics'])) {
    Response::error('Topics array is required', 400);
}

$sessionId = $input['session_id'];
$topics = array_filter($input['topics'], function($topic) {
    return !empty(trim($topic)); // Remove empty topics
});

if (empty($topics)) {
    Response::error('At least one topic is required', 400);
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
    
    // Delete existing topics for this session
    $stmt = $db->prepare("DELETE FROM training_topics_delivered WHERE session_id = ?");
    $stmt->execute([$sessionId]);
    
    // Insert new topics
    $stmt = $db->prepare("
        INSERT INTO training_topics_delivered (session_id, topic, order_index, created_at)
        VALUES (?, ?, ?, NOW())
    ");
    
    $insertedCount = 0;
    foreach ($topics as $index => $topic) {
        $stmt->execute([$sessionId, trim($topic), $index]);
        $insertedCount++;
    }
    
    $db->commit();
    
    Response::success([
        'message' => 'Training topics saved successfully',
        'session_id' => $sessionId,
        'topics_count' => $insertedCount
    ]);
    
} catch (PDOException $e) {
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Error saving topics: " . $e->getMessage());
    Response::error('Failed to save topics: ' . $e->getMessage(), 500);
}
