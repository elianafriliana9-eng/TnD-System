<?php
/**
 * Database Configuration File
 * TND System - PHP Native Version
 * Uses environment variables from .env file
 */

// Load environment variables
require_once __DIR__ . '/env.php';
Env::load();

// Database Configuration from .env
define('DB_HOST', Env::get('DB_HOST', '127.0.0.1'));
define('DB_NAME', Env::get('DB_NAME', 'tnd_system'));
define('DB_USERNAME', Env::get('DB_USERNAME', 'root'));
define('DB_PASSWORD', Env::get('DB_PASSWORD', ''));
define('DB_CHARSET', Env::get('DB_CHARSET', 'utf8mb4'));
define('DB_PORT', Env::get('DB_PORT', '3306'));

// Application Configuration from .env
define('APP_NAME', Env::get('APP_NAME', 'TND System'));
define('APP_VERSION', Env::get('APP_VERSION', '1.0.0'));
define('APP_URL', Env::get('APP_URL', 'http://localhost/tnd_system'));
define('APP_ENV', Env::get('APP_ENV', 'development'));

// JWT Secret from .env
define('JWT_SECRET_KEY', Env::get('JWT_SECRET_KEY', 'default_dev_secret_key_change_this'));

// Timezone from .env
date_default_timezone_set(Env::get('APP_TIMEZONE', 'Asia/Jakarta'));

// Error Reporting based on APP_ENV and APP_DEBUG
$isDevelopment = (APP_ENV === 'development' || Env::isDebug());

if ($isDevelopment) {
    // Development: Show all errors
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    ini_set('log_errors', 1);
    ini_set('error_log', __DIR__ . '/../logs/error.log');
} else {
    // Production: Hide errors, log only
    error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED);
    ini_set('display_errors', 0);
    ini_set('display_startup_errors', 0);
    ini_set('log_errors', 1);
    ini_set('error_log', __DIR__ . '/../logs/error.log');
}

// Session Configuration - Enhanced Security
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_secure', 0); // Set to 1 for HTTPS in production
ini_set('session.cookie_samesite', 'Lax');
ini_set('session.gc_maxlifetime', 3600); // 1 hour
ini_set('session.cookie_lifetime', 0); // Session cookie
session_start();