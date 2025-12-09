<?php
/**
 * Create Visit API
 * Start a new visit
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

    // Validate input - template_id tidak diperlukan lagi
    if (!isset($input['outlet_id'])) {
        Response::error('Missing required field: outlet_id', 400);
    }

    $visitModel = new Visit();
    
    $visitData = [
        'outlet_id' => $input['outlet_id'],
        'user_id' => $user['id'],
        'visit_date' => date('Y-m-d H:i:s'),
        'status' => 'in_progress',
        'notes' => $input['notes'] ?? null,
        'crew_in_charge' => $input['crew_in_charge'] ?? null, // NEW: Crew input at start
    ];

    error_log('Creating visit with crew: ' . ($input['crew_in_charge'] ?? 'NULL'));

    $visitId = $visitModel->create($visitData);

    if ($visitId) {
        $visit = $visitModel->findById($visitId);
        error_log('Visit created with ID: ' . $visitId . ', crew in DB: ' . ($visit['crew_in_charge'] ?? 'NULL'));
        Response::success($visit, 'Visit started successfully');
    } else {
        Response::error('Failed to create visit', 500);
    }
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
