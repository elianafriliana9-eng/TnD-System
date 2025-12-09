<?php
/**
 * Complete Visit API
 * Mark visit as completed
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
    if (!Auth::checkAuth()) {
        Response::error('Authentication required', 401);
        exit;
    }

    // Get current user
    $currentUser = Auth::getUserFromHeader();
    if (!$currentUser) {
        $currentUser = Auth::user();
    }
    
    if (!$currentUser) {
        Response::error('User not found', 401);
        exit;
    }
    
    $user = $currentUser;
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (!isset($input['visit_id'])) {
        Response::error('Missing required field: visit_id', 400);
    }

    $visitModel = new Visit();
    
    // Verify visit belongs to user
    $visit = $visitModel->findById($input['visit_id']);
    if (!$visit) {
        Response::error('Visit not found', 404);
    }
    if ($visit['user_id'] != $user['id'] && !Auth::isAdmin()) {
        Response::error('Access denied', 403);
    }

    // Update visit status to completed
    $updateData = [
        'status' => 'completed',
        'check_out_time' => date('H:i:s'),
    ];

    if (isset($input['notes'])) {
        $updateData['notes'] = $input['notes'];
    }

    if ($visitModel->update($input['visit_id'], $updateData)) {
        $visit = $visitModel->getVisitDetails($input['visit_id']);
        Response::success($visit, 'Visit completed successfully');
    } else {
        Response::error('Failed to complete visit', 500);
    }
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
