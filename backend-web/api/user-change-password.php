<?php
/**
 * Change User Password Endpoint (Super Admin Only)
 * Allows super admin to reset user passwords
 */

require_once __DIR__ . '/../classes/Database.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/RateLimiter.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication and require admin privileges
    Auth::requireAdmin();
    
    // Rate limiting: Max 5 password change attempts per admin per minute
    $adminId = Auth::id();
    $identifier = 'admin_' . $adminId;
    $rateLimit = RateLimiter::check($identifier, 5, 60, 'password_change');
    
    if (!$rateLimit['allowed']) {
        http_response_code(429);
        Response::error('Too many password change attempts. Please try again in ' . $rateLimit['retry_after'] . ' seconds.', 429);
    }
    
    // Record this attempt
    RateLimiter::hit($identifier, 'password_change');
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['user_id']) || !isset($input['new_password'])) {
        Response::error('User ID and new password are required', 400);
    }
    
    $userId = (int) $input['user_id'];
    $newPassword = trim($input['new_password']);
    
    // Validate password length
    if (strlen($newPassword) < 6) {
        Response::error('Password must be at least 6 characters', 400);
    }
    
    // Check if user exists
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare("SELECT id, full_name, email FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        Response::error('User not found', 404);
    }
    
    // Prevent changing super admin password (extra security)
    $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $userRole = $stmt->fetchColumn();
    
    if ($userRole === 'super_admin' && Auth::id() != $userId) {
        Response::error('Cannot change super admin password', 403);
    }
    
    // Hash the new password
    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
    
    // Update password in database
    $updateStmt = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
    $success = $updateStmt->execute([$hashedPassword, $userId]);
    
    if ($success) {
        Response::success([
            'message' => 'Password changed successfully',
            'user' => [
                'id' => $user['id'],
                'full_name' => $user['full_name'],
                'email' => $user['email']
            ]
        ], 'Password changed successfully');
    } else {
        Response::error('Failed to update password', 500);
    }
    
} catch (Exception $e) {
    error_log("Change password error: " . $e->getMessage());
    Response::error('Internal server error: ' . $e->getMessage(), 500);
}
