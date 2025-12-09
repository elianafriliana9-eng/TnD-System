<?php
/**
 * Visit Schedules API
 * Get visit schedules
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/VisitSchedule.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication
    if (!Auth::check()) {
        Response::error('Authentication required', 401);
    }

    $scheduleModel = new VisitSchedule();
    $user = Auth::user();

    // Get schedules by date range if provided
    if (isset($_GET['start_date']) && isset($_GET['end_date'])) {
        $schedules = $scheduleModel->findByDateRange(
            $user['id'], 
            $_GET['start_date'], 
            $_GET['end_date']
        );
        Response::success($schedules);
    }

    // Get schedules by status if provided
    $status = $_GET['status'] ?? null;
    $schedules = $scheduleModel->findByUser($user['id'], $status);
    
    Response::success($schedules);
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
