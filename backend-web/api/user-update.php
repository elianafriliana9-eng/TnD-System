<?php
/**
 * Users API - Update User
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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') { // Using POST instead of PUT for simplicity
    Response::error('Method not allowed', 405);
}

try {
    Auth::require();
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        Response::error('Invalid JSON data', 400);
    }
    
    $userId = $data['id'] ?? null;
    
    if (!$userId) {
        Response::error('User ID is required', 400);
    }
    
    // Users can only update their own profile unless they're admin
    if (Auth::id() != $userId && !Auth::isAdmin()) {
        Response::forbidden();
    }
    
    $userModel = new User();
    $user = $userModel->findById($userId);
    
    if (!$user) {
        Response::notFound('User not found');
    }
    
    // Validation
    if (!isset($data['full_name']) || empty($data['full_name'])) {
        Response::error('Full name is required', 400);
    }
    
    if (!isset($data['email']) || empty($data['email'])) {
        Response::error('Email is required', 400);
    }
    
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        Response::error('Invalid email format', 400);
    }
    
    // Check if email already exists for another user
    $existingUser = $userModel->findByEmail($data['email']);
    if ($existingUser && $existingUser['id'] != $userId) {
        Response::error('Email already exists', 400);
    }
    
    $userData = [
        'full_name' => $data['full_name'],
        'email' => $data['email'],
        'phone' => $data['phone'] ?? null
    ];
    
    // Only admin can update role and is_active
    if (Auth::isAdmin()) {
        if (isset($data['role'])) {
            $userData['role'] = $data['role'];
        }
        if (isset($data['status'])) {
            $userData['is_active'] = $data['status'] === 'active' ? 1 : 0;
        } else if (isset($data['is_active'])) {
            $userData['is_active'] = $data['is_active'];
        }
    }
    
    $success = $userModel->updateUser($userId, $userData);
    
    if ($success) {
        $updatedUser = $userModel->findById($userId);
        unset($updatedUser['password']);
        Response::success($updatedUser, 'User updated successfully');
    } else {
        Response::error('Failed to update user', 500);
    }
} catch (Exception $e) {
    Response::error($e->getMessage(), 500);
}
?>