<?php
/**
 * Users API - Get All Users
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/User.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    Auth::requireAdmin();
    
    $db = Database::getInstance()->getConnection();
    
    // Get single user by ID
    if (isset($_GET['id'])) {
        $sql = "SELECT u.*, d.name AS division_name 
                FROM users u 
                LEFT JOIN divisions d ON u.division_id = d.id 
                WHERE u.id = :id";
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $_GET['id']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            unset($user['password']);
            Response::success($user);
        } else {
            Response::error('User not found', 404);
        }
        exit;
    }
    
    // Get users with optional role filter
    $sql = "SELECT u.*, d.name AS division_name 
            FROM users u 
            LEFT JOIN divisions d ON u.division_id = d.id";
    
    $params = [];
    if (isset($_GET['role'])) {
        $sql .= " WHERE u.role = :role";
        $params[':role'] = $_GET['role'];
    }
    
    $sql .= " ORDER BY u.full_name ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($users as &$user) {
        unset($user['password']);
    }
    
    Response::success($users);
} catch (Exception $e) {
    Response::error($e->getMessage(), 401);
}
?>