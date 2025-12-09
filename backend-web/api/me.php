<?php
/**
 * Get Current User API
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Headers.php';

// Set CORS headers with dynamic origin
Headers::setAPIHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    Auth::require();
    $user = Auth::user();
    Response::success($user);
} catch (Exception $e) {
    Response::error($e->getMessage(), 401);
}
?>