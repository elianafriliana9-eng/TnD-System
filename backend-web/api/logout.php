<?php
/**
 * Logout API
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Headers.php';

// Set CORS headers with dynamic origin
Headers::setAPIHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    Auth::logout();
    Response::success(null, 'Logout successful');
} catch (Exception $e) {
    Response::error('Logout failed: ' . $e->getMessage(), 500);
}
?>