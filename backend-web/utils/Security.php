<?php
/**
 * Security Utility Class
 * TND System - PHP Native Version
 */

class Security {
    
    private static $loginAttempts = [];
    private static $maxAttempts = 5;
    private static $lockoutTime = 900; // 15 minutes
    
    /**
     * Check rate limiting for login attempts
     */
    public static function checkLoginRateLimit($ip) {
        if (!isset(self::$loginAttempts[$ip])) {
            self::$loginAttempts[$ip] = [];
        }
        
        // Clean old attempts
        $currentTime = time();
        self::$loginAttempts[$ip] = array_filter(self::$loginAttempts[$ip], function($attempt) use ($currentTime) {
            return ($currentTime - $attempt) < self::$lockoutTime;
        });
        
        return count(self::$loginAttempts[$ip]) < self::$maxAttempts;
    }
    
    /**
     * Record failed login attempt
     */
    public static function recordFailedLogin($ip) {
        if (!isset(self::$loginAttempts[$ip])) {
            self::$loginAttempts[$ip] = [];
        }
        
        self::$loginAttempts[$ip][] = time();
    }
    
    /**
     * Clear login attempts for IP
     */
    public static function clearLoginAttempts($ip) {
        unset(self::$loginAttempts[$ip]);
    }
    
    /**
     * Sanitize input
     */
    public static function sanitizeInput($input) {
        if (is_array($input)) {
            return array_map([self::class, 'sanitizeInput'], $input);
        }
        
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
    
    /**
     * Validate email
     */
    public static function validateEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    /**
     * Validate password strength
     */
    public static function validatePassword($password) {
        $errors = [];
        
        if (strlen($password) < 8) {
            $errors[] = 'Password must be at least 8 characters long';
        }
        
        if (!preg_match('/[A-Z]/', $password)) {
            $errors[] = 'Password must contain at least one uppercase letter';
        }
        
        if (!preg_match('/[a-z]/', $password)) {
            $errors[] = 'Password must contain at least one lowercase letter';
        }
        
        if (!preg_match('/[0-9]/', $password)) {
            $errors[] = 'Password must contain at least one number';
        }
        
        return empty($errors) ? true : $errors;
    }
    
    /**
     * Generate CSRF token
     */
    public static function generateCSRFToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * Verify CSRF token
     */
    public static function verifyCSRFToken($token) {
        return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * Get client IP address
     */
    public static function getClientIP() {
        $ipKeys = ['HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
        
        foreach ($ipKeys as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                foreach (explode(',', $_SERVER[$key]) as $ip) {
                    $ip = trim($ip);
                    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false) {
                        return $ip;
                    }
                }
            }
        }
        
        return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    }
    
    /**
     * Log security event
     */
    public static function logSecurityEvent($event, $details = []) {
        $logData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'ip' => self::getClientIP(),
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown',
            'event' => $event,
            'details' => $details
        ];
        
        $logFile = __DIR__ . '/../logs/security.log';
        file_put_contents($logFile, json_encode($logData) . "\n", FILE_APPEND | LOCK_EX);
    }
}
?>