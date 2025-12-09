<?php
/**
 * Training Sessions List API
 * Get list of training sessions with filters
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Build query with filters
    $sql = "SELECT 
                ts.id,
                ts.session_date,
                ts.start_time,
                ts.end_time,
                ts.status,
                ts.average_score,
                tc.id as checklist_id,
                tc.name as checklist_name,
                o.id as outlet_id,
                o.name as outlet_name,
                o.address as outlet_address,
                u.id as trainer_id,
                u.full_name as trainer_name
            FROM training_sessions ts
            JOIN training_checklists tc ON ts.checklist_id = tc.id
            JOIN outlets o ON ts.outlet_id = o.id
            JOIN users u ON ts.trainer_id = u.id
            WHERE 1=1";
    
    $params = [];
    
    // Filter by date range
    if (isset($_GET['start_date']) && !empty($_GET['start_date'])) {
        $sql .= " AND ts.session_date >= ?";
        $params[] = $_GET['start_date'];
    }
    
    if (isset($_GET['end_date']) && !empty($_GET['end_date'])) {
        $sql .= " AND ts.session_date <= ?";
        $params[] = $_GET['end_date'];
    }
    
    // Filter by outlet
    if (isset($_GET['outlet_id']) && !empty($_GET['outlet_id'])) {
        $sql .= " AND ts.outlet_id = ?";
        $params[] = $_GET['outlet_id'];
    }
    
    // Filter by status
    if (isset($_GET['status']) && !empty($_GET['status'])) {
        $sql .= " AND ts.status = ?";
        $params[] = $_GET['status'];
    }
    
    $sql .= " ORDER BY ts.session_date DESC, ts.start_time DESC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format response
    $formatted = array_map(function($session) {
        return [
            'id' => (int)$session['id'],
            'session_date' => $session['session_date'],
            'start_time' => $session['start_time'],
            'end_time' => $session['end_time'],
            'status' => $session['status'],
            'average_score' => $session['average_score'] ? (float)$session['average_score'] : null,
            'checklist' => [
                'id' => (int)$session['checklist_id'],
                'name' => $session['checklist_name']
            ],
            'outlet' => [
                'id' => (int)$session['outlet_id'],
                'name' => $session['outlet_name'],
                'address' => $session['outlet_address']
            ],
            'trainer' => [
                'id' => (int)$session['trainer_id'],
                'name' => $session['trainer_name']
            ]
        ];
    }, $sessions);
    
    Response::success($formatted, 'Training sessions retrieved successfully');
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
