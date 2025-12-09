<?php
/**
 * Delete Visit Schedule API
 * Delete a visit schedule
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/VisitSchedule.php';

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

    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (!isset($input['id'])) {
        Response::error('Missing required field: id', 400);
    }

    $scheduleModel = new VisitSchedule();
    
    if ($scheduleModel->delete($input['id'])) {
        Response::success(['message' => 'Schedule deleted successfully']);
    } else {
        Response::error('Failed to delete schedule', 500);
    }
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
