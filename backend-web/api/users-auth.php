<?php
/**
 * Users API with Cookie-based Authentication
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../classes/User.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://localhost');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Simple authentication check using cookie
function isAuthenticated() {
    if (isset($_SESSION['logged_in']) && $_SESSION['logged_in']) {
        return $_SESSION;
    }
    
    if (isset($_COOKIE['tnd_auth'])) {
        $authData = json_decode(base64_decode($_COOKIE['tnd_auth']), true);
        if ($authData && isset($authData['user_id'])) {
            // Validate cookie is not too old (24 hours)
            if ((time() - $authData['time']) < (24 * 60 * 60)) {
                return $authData;
            }
        }
    }
    
    return false;
}

function isAdmin($authData) {
    return isset($authData['role']) && ($authData['role'] === 'admin' || $authData['role'] === 'super_admin');
}

try {
    $authData = isAuthenticated();
    
    if (!$authData) {
        Response::error('Authentication required', 401);
    }
    
    if (!isAdmin($authData)) {
        Response::error('Admin access required', 403);
    }
    
    $userModel = new User();
    $users = $userModel->findAll('name ASC');
    
    // Remove passwords from response
    foreach ($users as &$user) {
        unset($user['password']);
    }
    
    Response::success($users);
} catch (Exception $e) {
    Response::error($e->getMessage(), 500);
}
?>