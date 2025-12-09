<?php
/**
 * Users API - Get User by ID
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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    Auth::require();
    
    // Get user ID from query parameter
    $userId = $_GET['id'] ?? null;
    
    if (!$userId) {
        Response::error('User ID is required', 400);
    }
    
    // Users can only view their own profile unless they're admin
    if (Auth::id() != $userId && !Auth::isAdmin()) {
        Response::forbidden();
    }
    
    $userModel = new User();
    $user = $userModel->findById($userId);
    
    if (!$user) {
        Response::notFound('User not found');
    }
    
    unset($user['password']);
    Response::success($user);
} catch (Exception $e) {
    Response::error($e->getMessage(), 401);
}
?>