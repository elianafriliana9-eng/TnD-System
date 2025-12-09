<?php
/**
 * Rate Limiting Utility
 * Prevent brute force attacks and API abuse
 */

class RateLimiter
{
    private static $storageDir = __DIR__ . '/../logs/ratelimit/';
    
    /**
     * Check if request is allowed based on rate limit
     * 
     * @param string $identifier - IP address, user ID, or email
     * @param int $maxAttempts - Maximum attempts allowed
     * @param int $windowSeconds - Time window in seconds
     * @param string $action - Action type (login, api, upload, etc.)
     * @return array ['allowed' => bool, 'remaining' => int, 'reset_at' => int]
     */
    public static function check($identifier, $maxAttempts = 5, $windowSeconds = 60, $action = 'default')
    {
        // Create storage directory if not exists
        if (!file_exists(self::$storageDir)) {
            mkdir(self::$storageDir, 0777, true);
        }
        
        $key = self::generateKey($identifier, $action);
        $filepath = self::$storageDir . $key . '.json';
        
        $now = time();
        $data = self::loadData($filepath);
        
        // Clean up old attempts outside the window
        $data['attempts'] = array_filter($data['attempts'], function($timestamp) use ($now, $windowSeconds) {
            return ($now - $timestamp) < $windowSeconds;
        });
        
        // Reset array keys
        $data['attempts'] = array_values($data['attempts']);
        
        $currentAttempts = count($data['attempts']);
        $allowed = $currentAttempts < $maxAttempts;
        
        // Calculate reset time
        $oldestAttempt = !empty($data['attempts']) ? min($data['attempts']) : $now;
        $resetAt = $oldestAttempt + $windowSeconds;
        
        return [
            'allowed' => $allowed,
            'remaining' => max(0, $maxAttempts - $currentAttempts),
            'reset_at' => $resetAt,
            'retry_after' => $allowed ? 0 : ($resetAt - $now)
        ];
    }
    
    /**
     * Record an attempt
     */
    public static function hit($identifier, $action = 'default')
    {
        if (!file_exists(self::$storageDir)) {
            mkdir(self::$storageDir, 0777, true);
        }
        
        $key = self::generateKey($identifier, $action);
        $filepath = self::$storageDir . $key . '.json';
        
        $data = self::loadData($filepath);
        $data['attempts'][] = time();
        
        self::saveData($filepath, $data);
    }
    
    /**
     * Clear attempts for an identifier
     */
    public static function clear($identifier, $action = 'default')
    {
        $key = self::generateKey($identifier, $action);
        $filepath = self::$storageDir . $key . '.json';
        
        if (file_exists($filepath)) {
            unlink($filepath);
        }
    }
    
    /**
     * Generate storage key
     */
    private static function generateKey($identifier, $action)
    {
        return md5($action . '_' . $identifier);
    }
    
    /**
     * Load data from file
     */
    private static function loadData($filepath)
    {
        if (file_exists($filepath)) {
            $content = file_get_contents($filepath);
            $data = json_decode($content, true);
            if (is_array($data) && isset($data['attempts'])) {
                return $data;
            }
        }
        
        return ['attempts' => []];
    }
    
    /**
     * Save data to file
     */
    private static function saveData($filepath, $data)
    {
        file_put_contents($filepath, json_encode($data));
    }
    
    /**
     * Clean up old rate limit files (call periodically via cron)
     */
    public static function cleanup($olderThanSeconds = 3600)
    {
        if (!file_exists(self::$storageDir)) {
            return;
        }
        
        $files = glob(self::$storageDir . '*.json');
        $now = time();
        $deleted = 0;
        
        foreach ($files as $file) {
            if (($now - filemtime($file)) > $olderThanSeconds) {
                unlink($file);
                $deleted++;
            }
        }
        
        return $deleted;
    }
}
