<?php
/**
 * Create Visit Schedule API
 * Create a new visit schedule
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

    $user = Auth::user();
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (!isset($input['outlet_id']) || !isset($input['template_id']) || !isset($input['scheduled_date'])) {
        Response::error('Missing required fields: outlet_id, template_id, scheduled_date', 400);
    }

    // Validate recurrence value
    $validRecurrence = ['once', 'daily', 'weekly', 'monthly'];
    $recurrence = $input['recurrence'] ?? 'once';
    if (!in_array($recurrence, $validRecurrence)) {
        Response::error('Invalid recurrence value. Must be: once, daily, weekly, or monthly', 400);
    }

    $scheduleModel = new VisitSchedule();
    
    $scheduleData = [
        'outlet_id' => $input['outlet_id'],
        'user_id' => $user['id'],
        'template_id' => $input['template_id'],
        'scheduled_date' => $input['scheduled_date'],
        'scheduled_time' => $input['scheduled_time'] ?? null,
        'recurrence' => $recurrence,
        'notes' => $input['notes'] ?? null,
    ];

    $scheduleId = $scheduleModel->create($scheduleData);

    if ($scheduleId) {
        Response::success(['id' => $scheduleId], 'Schedule created successfully');
    } else {
        Response::error('Failed to create schedule', 500);
    }
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
