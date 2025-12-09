<?php
/**
 * Direct Login Test
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../classes/User.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/RateLimiter.php';
require_once __DIR__ . '/../utils/Headers.php';

// Set CORS headers with dynamic origin
Headers::setAPIHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['email']) || !isset($data['password'])) {
    Response::error('Email and password required', 400);
}

try {
    // Rate limiting: Max 5 login attempts per email per minute
    $identifier = $data['email'];
    $rateLimit = RateLimiter::check($identifier, 5, 60, 'login');
    
    if (!$rateLimit['allowed']) {
        http_response_code(429);
        Response::error('Too many login attempts. Please try again in ' . $rateLimit['retry_after'] . ' seconds.', 429);
    }
    
    // Record this login attempt
    RateLimiter::hit($identifier, 'login');
    
    $user = Auth::login($data['email'], $data['password']);
    
    if ($user) {
        // Clear rate limit on successful login
        RateLimiter::clear($identifier, 'login');
        Response::success($user, 'Login successful');
    } else {
        Response::error('Invalid credentials', 401);
    }
} catch (Exception $e) {
    Response::error('Login failed: ' . $e->getMessage(), 500);
}
?>