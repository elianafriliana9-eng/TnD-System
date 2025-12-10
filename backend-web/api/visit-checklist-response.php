<?php
/**
 * Save Checklist Response API
 * Save user's response to checklist item (✓/✗/N/A)
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/Visit.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication
    if (!Auth::check()) {
        Response::error('Authentication required', 401);
    }

    $user = Auth::user();
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (!isset($input['visit_id']) || !isset($input['checklist_item_id']) || !isset($input['response'])) {
        Response::error('Missing required fields: visit_id, checklist_item_id, response', 400);
    }

    // Validate response value (mobile sends lowercase with underscore)
    $validResponses = ['ok', 'not_ok', 'na'];
    if (!in_array($input['response'], $validResponses)) {
        Response::error('Invalid response value. Must be: ok, not_ok, or na', 400);
    }
    
    // Map mobile format to database enum format
    $responseMapping = [
        'ok' => 'OK',
        'not_ok' => 'NOT OK',
        'na' => 'N/A'
    ];
    $dbResponse = $responseMapping[$input['response']];

    $visitModel = new Visit();
    
    // Verify visit belongs to user
    $visit = $visitModel->findById($input['visit_id']);
    if (!$visit) {
        Response::error('Visit not found', 404);
    }
    if ($visit['user_id'] != $user['id'] && !Auth::isAdmin()) {
        Response::error('Access denied', 403);
    }

    $responseData = [
        'visit_id' => $input['visit_id'],
        'checklist_item_id' => $input['checklist_item_id'], // Will be mapped to checklist_point_id in model
        'response' => $dbResponse, // Use mapped database format (OK/NOT OK/N/A)
        'notes' => $input['notes'] ?? null,
        'nok_remarks' => $input['nok_remarks'] ?? null, // NOK remarks (optional)
    ];

    error_log('Attempting to save checklist response: ' . json_encode($responseData));
    
    $result = $visitModel->saveChecklistResponse($responseData);
    
    if ($result) {
        error_log('Checklist response saved successfully');
        Response::success(['message' => 'Response saved successfully']);
    } else {
        error_log('CRITICAL: Failed to save checklist response - saveChecklistResponse returned false');
        error_log('Response data was: ' . json_encode($responseData));
        Response::error('Failed to save response. Check logs for details.', 500);
    }
} catch (Exception $e) {
    error_log('EXCEPTION in visit-checklist-response.php: ' . $e->getMessage());
    error_log('Stack trace: ' . $e->getTraceAsString());
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
