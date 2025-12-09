<?php
/**
 * Storage Factory
 * Returns appropriate storage implementation based on configuration
 */

require_once __DIR__ . '/../config/storage.php';
require_once __DIR__ . '/StorageInterface.php';
require_once __DIR__ . '/LocalStorage.php';
require_once __DIR__ . '/CloudinaryStorage.php';

class Storage {
    private static $instance = null;
    
    /**
     * Get storage instance based on configuration
     * @return StorageInterface
     */
    public static function getInstance() {
        if (self::$instance === null) {
            // Check configuration to decide which storage to use
            if (USE_CLOUDINARY) {
                try {
                    self::$instance = new CloudinaryStorage();
                    error_log('Using Cloudinary Storage');
                } catch (Exception $e) {
                    // Fallback to local if Cloudinary fails
                    error_log('Cloudinary init failed, falling back to Local Storage: ' . $e->getMessage());
                    self::$instance = new LocalStorage();
                }
            } else {
                self::$instance = new LocalStorage();
                error_log('Using Local Storage');
            }
        }
        
        return self::$instance;
    }
    
    /**
     * Reset instance (useful for testing)
     */
    public static function reset() {
        self::$instance = null;
    }
    
    /**
     * Magic method to forward calls to storage instance
     */
    public static function __callStatic($method, $args) {
        $instance = self::getInstance();
        return call_user_func_array([$instance, $method], $args);
    }
}
