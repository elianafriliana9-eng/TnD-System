<?php
/**
 * Users API - Delete User
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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') { // Using POST instead of DELETE for simplicity
    Response::error('Method not allowed', 405);
}

try {
    Auth::requireAdmin();
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    $userId = $data['id'] ?? $_GET['id'] ?? null;
    
    if (!$userId) {
        Response::error('User ID is required', 400);
    }
    
    // Prevent deleting own account
    if (Auth::id() == $userId) {
        Response::error('Cannot delete your own account', 400);
    }
    
    $userModel = new User();
    $user = $userModel->findById($userId);
    
    if (!$user) {
        Response::notFound('User not found');
    }
    
    $success = $userModel->delete($userId);
    
    if ($success) {
        Response::success(null, 'User deleted successfully');
    } else {
        Response::error('Failed to delete user', 500);
    }
} catch (Exception $e) {
    Response::error($e->getMessage(), 500);
}
?>