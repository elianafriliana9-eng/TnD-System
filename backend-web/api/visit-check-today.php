<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../utils/Response.php';
require_once '../utils/Auth.php';
require_once '../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::error('Authentication required', 401);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            if (!isset($_GET['outlet_id'])) {
                Response::error('Outlet ID required', 400);
                exit;
            }
            
            $outletId = intval($_GET['outlet_id']);
            $user = Auth::getUserFromHeader() ?? Auth::user();
            $userId = $user['id'];
            
            // Check if there's a visit for this outlet today by this user
            $today = date('Y-m-d');
            $sql = "SELECT COUNT(*) as count
                    FROM visits
                    WHERE outlet_id = :outlet_id 
                    AND user_id = :user_id
                    AND DATE(visit_date) = :today";
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare($sql);
            $stmt->bindParam(':outlet_id', $outletId);
            $stmt->bindParam(':user_id', $userId);
            $stmt->bindParam(':today', $today);
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $hasVisited = ($result['count'] > 0);
            
            Response::success([
                'has_visited' => $hasVisited,
                'outlet_id' => $outletId,
                'date' => $today
            ]);
            break;
            
        default:
            Response::error('Method not allowed', 405);
            break;
    }
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
