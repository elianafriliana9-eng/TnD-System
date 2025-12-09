<?php
/**
 * Main API Entry Point
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/Router.php';
require_once __DIR__ . '/AuthController.php';
require_once __DIR__ . '/UserController.php';

// Initialize router
$router = new Router();

// Authentication routes (remove /api prefix since we're already in api folder)
$router->post('/auth/login', ['AuthController', 'login']);
$router->post('/auth/logout', ['AuthController', 'logout']);
$router->get('/auth/me', ['AuthController', 'me']);
$router->post('/auth/register', ['AuthController', 'register']);
$router->post('/auth/change-password', ['AuthController', 'changePassword']);

// User routes
$router->get('/users', ['UserController', 'index']);
$router->get('/users/{id}', ['UserController', 'show']);
$router->post('/users', ['UserController', 'store']);
$router->put('/users/{id}', ['UserController', 'update']);
$router->delete('/users/{id}', ['UserController', 'delete']);
$router->get('/users/role/{role}', ['UserController', 'getByRole']);

// Health check
$router->get('/health', function($request) {
    Response::success([
        'status' => 'OK',
        'timestamp' => date('Y-m-d H:i:s'),
        'version' => APP_VERSION ?? '1.0.0'
    ]);
});

// Dispatch the request
$router->dispatch();