<?php
/**
 * Simple Users API
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../classes/User.php';
require_once __DIR__ . '/../utils/Auth.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://localhost');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    // Check if user is logged in
    if (!Auth::check()) {
        Response::error('Authentication required. Please login first.', 401);
    }
    
    // Check if user is admin
    if (!Auth::isAdmin()) {
        $currentRole = Auth::user()['role'] ?? 'no role';
        Response::error('Admin access required. Current role: ' . $currentRole, 403);
    }
    
    $db = Database::getInstance()->getConnection();
    $sql = "SELECT u.*, d.name AS division_name FROM users u LEFT JOIN divisions d ON u.division_id = d.id ORDER BY u.full_name ASC";
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Remove passwords from response
    foreach ($users as &$user) {
        unset($user['password']);
    }
    
    Response::success($users);
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>