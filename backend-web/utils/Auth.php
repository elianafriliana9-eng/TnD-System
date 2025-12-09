<?php
/**
 * Authentication Utility Class
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../classes/User.php';

class Auth {
    
    /**
     * Generate JWT-like token for mobile app
     */
    public static function generateToken($userId, $email) {
        $secret = defined('JWT_SECRET_KEY') ? JWT_SECRET_KEY : 'TND_SYSTEM_SECRET_KEY_2025';
        $timestamp = time();
        $payload = base64_encode(json_encode([
            'user_id' => $userId,
            'email' => $email,
            'timestamp' => $timestamp,
            'expires' => $timestamp + (86400 * 30) // 30 days
        ]));
        
        $signature = hash_hmac('sha256', $payload, $secret);
        $token = $payload . '.' . $signature;
        
        return $token;
    }
    
    /**
     * Validate token
     */
    public static function validateToken($token) {
        if (empty($token)) {
            error_log('validateToken: Empty token');
            return false;
        }
        
        $secret = defined('JWT_SECRET_KEY') ? JWT_SECRET_KEY : 'TND_SYSTEM_SECRET_KEY_2025';
        $parts = explode('.', $token);
        
        if (count($parts) !== 2) {
            error_log('validateToken: Invalid token format - expected 2 parts, got ' . count($parts));
            return false;
        }
        
        list($payload, $signature) = $parts;
        
        // Verify signature
        $expectedSignature = hash_hmac('sha256', $payload, $secret);
        if ($signature !== $expectedSignature) {
            error_log('validateToken: Invalid signature');
            return false;
        }
        
        // Decode payload
        $data = json_decode(base64_decode($payload), true);
        
        if (!$data) {
            error_log('validateToken: Failed to decode payload');
            return false;
        }
        
        // Check expiration
        if (!isset($data['expires']) || $data['expires'] < time()) {
            error_log('validateToken: Token expired');
            return false;
        }
        
        error_log('validateToken: Token is valid');
        return $data;
    }
    
    /**
     * Get user from Authorization header
     */
    public static function getUserFromHeader() {
        // Support both Apache and Nginx
        $headers = [];
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
        } else {
            // Fallback for Nginx
            foreach ($_SERVER as $name => $value) {
                if (substr($name, 0, 5) == 'HTTP_') {
                    $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
                }
            }
        }
        
        $authHeader = '';
        
        // Try different header variations
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
        } elseif (isset($headers['authorization'])) {
            $authHeader = $headers['authorization'];
        } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        
        if (empty($authHeader)) {
            error_log('Auth: No authorization header found');
            return null;
        }
        
        // Extract token from "Bearer <token>"
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
            error_log('Auth: Token found, validating...');
            $tokenData = self::validateToken($token);
            
            if ($tokenData) {
                error_log('Auth: Token valid for user ID: ' . $tokenData['user_id']);
                // Get full user data including division_id
                require_once __DIR__ . '/../classes/User.php';
                $userModel = new User();
                $user = $userModel->findById($tokenData['user_id']);
                
                if ($user) {
                    error_log('Auth: User data loaded: ' . json_encode($user));
                    return $user;
                }
                
                // Fallback to token data only
                error_log('Auth: User not found in DB, using fallback token data for user ID: ' . $tokenData['user_id']);
                return [
                    'id' => $tokenData['user_id'],
                    'email' => $tokenData['email']
                ];
            } else {
                error_log('Auth: Token validation failed');
            }
        } else {
            error_log('Auth: Invalid authorization header format');
        }
        
        return null;
    }
    
    /**
     * Login user
     */
    public static function login($email, $password) {
        $userModel = new User();
        $user = $userModel->authenticate($email, $password);
        
        if ($user) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['user_email'] = $user['email'];
            $_SESSION['user_name'] = $user['name'];
            $_SESSION['user_role'] = $user['role'];
            $_SESSION['user_division_id'] = $user['division_id'] ?? null;
            $_SESSION['user_division_name'] = $user['division_name'] ?? null;
            $_SESSION['logged_in'] = true;
            
            // Generate token for mobile app
            $token = self::generateToken($user['id'], $user['email']);
            $user['token'] = $token;
            
            return $user;
        }
        
        return false;
    }
    
    /**
     * Logout user
     */
    public static function logout() {
        session_destroy();
        return true;
    }
    
    /**
     * Check if user is logged in
     */
    public static function check() {
        // Check session first (for web)
        if (isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true) {
            error_log('Auth: Session authentication successful');
            return true;
        }
        
        // Check token (for mobile)
        error_log('Auth: Checking bearer token...');
        $user = self::getUserFromHeader();
        if ($user) {
            // Set session for compatibility
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['user_email'] = $user['email'] ?? '';
            $_SESSION['user_name'] = $user['name'] ?? '';
            $_SESSION['user_role'] = $user['role'] ?? '';
            $_SESSION['user_division_id'] = $user['division_id'] ?? null;
            $_SESSION['logged_in'] = true;
            error_log('Auth: Bearer token authentication successful');
            return true;
        }
        
        error_log('Auth: Authentication failed - no session and no valid token');
        return false;
    }
    
    /**
     * Check authentication (alias for check)
     */
    public static function checkAuth() {
        return self::check();
    }
    
    /**
     * Get current user
     */
    public static function user() {
        if (!self::check()) {
            return null;
        }
        
        return [
            'id' => $_SESSION['user_id'],
            'email' => $_SESSION['user_email'],
            'name' => $_SESSION['user_name'],
            'role' => $_SESSION['user_role'],
            'division_id' => $_SESSION['user_division_id'] ?? null,
            'division_name' => $_SESSION['user_division_name'] ?? null
        ];
    }
    
    /**
     * Get current user ID
     */
    public static function id() {
        return $_SESSION['user_id'] ?? null;
    }
    
    /**
     * Check if user has role
     */
    public static function hasRole($role) {
        $user = self::user();
        return $user && $user['role'] === $role;
    }
    
    /**
     * Check if user is admin
     */
    public static function isAdmin() {
        return self::hasRole('admin') || self::hasRole('super_admin');
    }
    
    /**
     * Check if user is trainer
     */
    public static function isTrainer() {
        return self::hasRole('trainer');
    }
    
    /**
     * Check if user can access visit features (NOT trainer)
     */
    public static function canAccessVisit() {
        $user = self::user();
        return $user && $user['role'] !== 'trainer';
    }
    
    /**
     * Check if user can access training features (IS trainer or admin)
     */
    public static function canAccessTraining() {
        $user = self::user();
        return $user && ($user['role'] === 'trainer' || self::isAdmin());
    }
    
    /**
     * Require authentication
     */
    public static function require() {
        if (!self::check()) {
            Response::unauthorized('Authentication required');
        }
    }
    
    /**
     * Require admin role
     */
    public static function requireAdmin() {
        self::require();
        if (!self::isAdmin()) {
            Response::forbidden('Admin access required');
        }
    }
    
    /**
     * Require specific role
     */
    public static function requireRole($role) {
        self::require();
        if (!self::hasRole($role)) {
            Response::forbidden("Role '{$role}' required");
        }
    }
}