<?php
/**
 * Visits API
 * Get visit history
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/Visit.php';

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

    $visitModel = new Visit();
    $user = Auth::user();

    // Get visit details if ID provided
    if (isset($_GET['id'])) {
        $visit = $visitModel->getVisitDetails($_GET['id']);
        if (!$visit) {
            Response::error('Visit not found', 404);
        }
        
        // Check if user has access to this visit
        if ($visit['user_id'] != $user['id'] && !Auth::isAdmin()) {
            Response::error('Access denied', 403);
        }
        
        Response::success($visit);
    }

    // Get visits by outlet if outlet_id provided
    if (isset($_GET['outlet_id'])) {
        // Get outlet to check division
        require_once __DIR__ . '/../classes/Outlet.php';
        $outletModel = new Outlet();
        $outlet = $outletModel->findById($_GET['outlet_id']);
        
        if (!$outlet) {
            Response::error('Outlet not found', 404);
        }
        
        // Check if outlet belongs to user's division
        if (isset($user['division_id']) && $outlet['division_id'] != $user['division_id']) {
            Response::error('Access denied - outlet not in your division', 403);
        }
        
        $visits = $visitModel->findByOutlet($_GET['outlet_id']);
        Response::success($visits);
    }

    // Get all visits for current user
    $visits = $visitModel->findByUser($user['id']);
    Response::success($visits);
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
