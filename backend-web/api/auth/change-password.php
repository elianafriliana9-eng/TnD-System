<?php
/**
 * Change Password API
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../utils/Headers.php';
require_once __DIR__ . '/../../classes/User.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication
    Auth::require();
    $currentUser = Auth::user();
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data || !isset($data['current_password']) || !isset($data['new_password']) || !isset($data['confirm_password'])) {
        Response::error('Current password, new password, and confirm password are required', 400);
    }
    
    // Validate new password and confirmation match
    if ($data['new_password'] !== $data['confirm_password']) {
        Response::error('New password and confirmation do not match', 400);
    }
    
    // Validate new password length
    if (strlen($data['new_password']) < 6) {
        Response::error('New password must be at least 6 characters long', 400);
    }
    
    $userModel = new User();
    
    // Verify current password
    if (!$userModel->verifyPassword($currentUser['id'], $data['current_password'])) {
        Response::error('Current password is incorrect', 401);
    }
    
    // Update password
    $result = $userModel->updatePassword($currentUser['id'], $data['new_password']);
    
    if ($result) {
        Response::success(null, 'Password changed successfully');
    } else {
        Response::error('Failed to change password', 500);
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>