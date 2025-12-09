<?php
/**
 * Headers Utility Class
 * TND System - PHP Native Version
 */

class Headers {
    
    /**
     * Get allowed origins (production domains)
     */
    private static function getAllowedOrigins() {
        return [
            'https://tndsystem.online',
            'https://www.tndsystem.online',
            'http://localhost',
            'http://localhost:3000',
            'http://127.0.0.1',
            'http://192.168.106.191', // Local network for mobile testing
        ];
    }
    
    /**
     * Get the origin from request or determine allowed origin
     */
    private static function getOrigin() {
        $allowedOrigins = self::getAllowedOrigins();
        
        // Get origin from request header
        $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? $_SERVER['HTTP_REFERER'] ?? '';
        
        // If request origin is in allowed list, use it
        foreach ($allowedOrigins as $allowed) {
            if (strpos($requestOrigin, $allowed) === 0) {
                return $allowed;
            }
        }
        
        // Default to main domain
        return 'https://tndsystem.online';
    }
    
    /**
     * Set CORS headers for API responses
     */
    public static function setCORS($origin = null, $methods = 'GET, POST, PUT, DELETE, OPTIONS', $headers = 'Content-Type, Authorization, X-Requested-With') {
        // Auto-detect origin if not provided
        if ($origin === null || $origin === '*') {
            $origin = self::getOrigin();
        }
        
        header("Access-Control-Allow-Origin: $origin");
        header("Access-Control-Allow-Methods: $methods");
        header("Access-Control-Allow-Headers: $headers");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 3600'); // Cache preflight for 1 hour
    }
    
    /**
     * Handle OPTIONS preflight request
     */
    public static function handlePreflight($origin = null, $methods = 'GET, POST, PUT, DELETE, OPTIONS', $headers = 'Content-Type, Authorization, X-Requested-With') {
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            self::setCORS($origin, $methods, $headers);
            http_response_code(200);
            exit(0);
        }
    }
    
    /**
     * Set JSON content type
     */
    public static function setJSON() {
        header('Content-Type: application/json; charset=utf-8');
    }
    
    /**
     * Set common API headers
     */
    public static function setAPIHeaders($origin = null) {
        self::setCORS($origin);
        self::setJSON();
        self::handlePreflight($origin);
    }
    
    /**
     * Set no-cache headers
     */
    public static function setNoCache() {
        header('Cache-Control: no-cache, no-store, must-revalidate');
        header('Pragma: no-cache');
        header('Expires: 0');
    }
}
?>