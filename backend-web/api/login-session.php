<?php
/**
 * Login API with Session Persistence and Security Features
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Headers.php';
require_once __DIR__ . '/../utils/Security.php';
require_once __DIR__ . '/../classes/User.php';

// Handle preflight and set headers
Headers::setAPIHeaders(); // Use dynamic origin handling
Headers::setJSON();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$clientIP = Security::getClientIP();

// Check rate limiting
if (!Security::checkLoginRateLimit($clientIP)) {
    Security::logSecurityEvent('LOGIN_RATE_LIMIT_EXCEEDED', ['ip' => $clientIP]);
    Response::error('Too many login attempts. Please try again in 15 minutes.', 429);
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['email']) || !isset($data['password'])) {
    Response::error('Email and password required', 400);
}

// Sanitize inputs
$email = Security::sanitizeInput($data['email']);
$password = $data['password']; // Don't sanitize password

// Validate email format
if (!Security::validateEmail($email)) {
    Security::recordFailedLogin($clientIP);
    Security::logSecurityEvent('LOGIN_INVALID_EMAIL', ['email' => $email, 'ip' => $clientIP]);
    Response::error('Invalid email format', 400);
}

try {
    $userModel = new User();
    $user = $userModel->authenticate($email, $password);
    
    if ($user) {
        // Clear failed login attempts
        Security::clearLoginAttempts($clientIP);
        
        // Regenerate session ID for security
        session_regenerate_id(true);
        
        // Start/update session
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_email'] = $user['email'];
        $_SESSION['user_name'] = $user['name'];
        $_SESSION['user_role'] = $user['role'];
        $_SESSION['logged_in'] = true;
        $_SESSION['login_time'] = time();
        
        // Generate CSRF token
        Security::generateCSRFToken();
        
        // Log successful login
        Security::logSecurityEvent('LOGIN_SUCCESS', [
            'user_id' => $user['id'],
            'email' => $user['email'],
            'ip' => $clientIP
        ]);
        
        // Set session cookie with proper settings for production
        $isProduction = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on');
        $cookieOptions = [
            'expires' => time() + (24 * 60 * 60), // 24 hours
            'path' => '/',
            'domain' => '',
            'secure' => $isProduction, // Secure only on HTTPS
            'httponly' => true,
            'samesite' => 'Lax' // Allow cookies on same-site navigation
        ];
        
        setcookie('tnd_auth', base64_encode(json_encode([
            'user_id' => $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
            'time' => time()
        ])), $cookieOptions);
        
        Response::success($user, 'Login successful');
    } else {
        // Record failed login attempt
        Security::recordFailedLogin($clientIP);
        Security::logSecurityEvent('LOGIN_FAILED', [
            'email' => $email,
            'ip' => $clientIP
        ]);
        
        Response::error('Invalid credentials', 401);
    }
} catch (Exception $e) {
    Security::logSecurityEvent('LOGIN_ERROR', [
        'error' => $e->getMessage(),
        'ip' => $clientIP
    ]);
    Response::error('Login failed: ' . $e->getMessage(), 500);
}
?>