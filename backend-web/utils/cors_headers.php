<?php
/**
 * CORS and Security Headers
 * Include this file at the top of all API endpoints
 */

// Load environment configuration
require_once __DIR__ . '/../config/env.php';
Env::load();

// CORS Configuration from .env
$allowedOrigins = Env::get('CORS_ALLOWED_ORIGINS', '*');
$isDevelopment = Env::isDevelopment();

// Set CORS headers based on environment
if ($isDevelopment || $allowedOrigins === '*') {
    // Development: Allow all origins
    header('Access-Control-Allow-Origin: *');
} else {
    // Production: Check origin against whitelist
    $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';
    $allowedOriginsArray = array_map('trim', explode(',', $allowedOrigins));
    
    if (in_array($origin, $allowedOriginsArray)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Credentials: true');
    } else {
        // Check for wildcard patterns (e.g., *.ngrok-free.app)
        foreach ($allowedOriginsArray as $allowed) {
            if (strpos($allowed, '*') !== false) {
                $pattern = str_replace('*', '.*', $allowed);
                if (preg_match('#^' . $pattern . '$#', $origin)) {
                    header('Access-Control-Allow-Origin: ' . $origin);
                    header('Access-Control-Allow-Credentials: true');
                    break;
                }
            }
        }
    }
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, ngrok-skip-browser-warning');
header('Access-Control-Max-Age: 3600');

// Security Headers
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// Content Security Policy (CSP) - Adjust as needed
if (!$isDevelopment) {
    header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;");
}

// HSTS (HTTP Strict Transport Security) - Only for HTTPS in production
if (!$isDevelopment && isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
    header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
}

// Ngrok specific header to skip browser warning page
if (isset($_SERVER['HTTP_HOST']) && strpos($_SERVER['HTTP_HOST'], 'ngrok') !== false) {
    header('ngrok-skip-browser-warning: true');
}

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}
