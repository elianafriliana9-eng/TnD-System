<?php
/**
 * Users API - Create User
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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    Auth::requireAdmin();
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        Response::error('Invalid JSON data', 400);
    }
    
    // Validation
    $required = ['full_name', 'email', 'password', 'role'];
    foreach ($required as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            Response::error("Field '$field' is required", 400);
        }
    }
    
    if (strlen($data['password']) < 6) {
        Response::error('Password must be at least 6 characters', 400);
    }
    
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        Response::error('Invalid email format', 400);
    }
    
    $userModel = new User();
    
    // Check if email already exists
    $existingUser = $userModel->findByEmail($data['email']);
    if ($existingUser) {
        Response::error('Email already exists', 400);
    }
    
    // Generate username from email if not provided
    $username = $data['username'] ?? strtolower(explode('@', $data['email'])[0]);
    
    // Check if username already exists, if yes add number suffix
    $baseUsername = $username;
    $counter = 1;
    while (true) {
        $sql = "SELECT id FROM users WHERE username = :username";
        $stmt = Database::getInstance()->getConnection()->prepare($sql);
        $stmt->execute([':username' => $username]);
        if (!$stmt->fetch()) {
            break; // Username is available
        }
        $username = $baseUsername . $counter;
        $counter++;
    }
    
    $userData = [
    'username' => $username,
    'full_name' => $data['full_name'],
    'email' => $data['email'],
    'password' => $data['password'],
    'role' => $data['role'],
    'phone' => $data['phone'] ?? null,
    'division_id' => isset($data['division_id']) ? (int)$data['division_id'] : null,
    'is_active' => isset($data['status']) && $data['status'] === 'inactive' ? 0 : 1
    ];
    
    $userId = $userModel->createUser($userData);
    
    if ($userId) {
        $user = $userModel->findById($userId);
        unset($user['password']);
        Response::success($user, 'User created successfully', 201);
    } else {
        Response::error('Failed to create user', 500);
    }
} catch (Exception $e) {
    Response::error($e->getMessage(), 500);
}
?>