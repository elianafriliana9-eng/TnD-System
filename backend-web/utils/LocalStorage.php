<?php
/**
 * Local Storage Implementation
 * Stores files in local directory
 */

require_once __DIR__ . '/StorageInterface.php';

class LocalStorage implements StorageInterface {
    private $uploadDir;
    private $baseUrl;
    
    public function __construct() {
        $this->uploadDir = __DIR__ . '/../uploads/';
        
        // Auto-detect base URL
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $this->baseUrl = $protocol . '://' . $host . '/tnd_system/tnd_system/backend-web/uploads/';
    }
    
    /**
     * Upload file to local directory
     */
    public function upload($file, $folder = 'uploads') {
        try {
            // Validate file
            if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
                return ['success' => false, 'message' => 'Invalid file upload'];
            }
            
            // Check file type
            $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            if (!in_array($file['type'], $allowedTypes)) {
                return ['success' => false, 'message' => 'Invalid file type. Only JPG, PNG, GIF allowed'];
            }
            
            // Check file size (max 5MB)
            $maxSize = 5 * 1024 * 1024; // 5MB
            if ($file['size'] > $maxSize) {
                return ['success' => false, 'message' => 'File too large. Max 5MB'];
            }
            
            // Create folder if not exists
            $targetDir = $this->uploadDir . $folder . '/';
            if (!is_dir($targetDir)) {
                mkdir($targetDir, 0755, true);
            }
            
            // Generate unique filename
            $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
            $filename = uniqid('img_' . time() . '_') . '.' . $extension;
            $targetPath = $targetDir . $filename;
            $relativePath = $folder . '/' . $filename;
            
            // Move uploaded file
            if (move_uploaded_file($file['tmp_name'], $targetPath)) {
                return [
                    'success' => true,
                    'url' => $this->getUrl($relativePath),
                    'path' => $relativePath,
                    'filename' => $filename
                ];
            } else {
                return ['success' => false, 'message' => 'Failed to save file'];
            }
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }
    
    /**
     * Delete file from local directory
     */
    public function delete($path) {
        try {
            // Remove base URL if provided as full URL
            $path = str_replace($this->baseUrl, '', $path);
            
            $filePath = $this->uploadDir . $path;
            
            if (file_exists($filePath)) {
                return unlink($filePath);
            }
            
            return false;
        } catch (Exception $e) {
            error_log("Delete file error: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Get public URL for file
     */
    public function getUrl($path) {
        // If already a full URL, return as is
        if (strpos($path, 'http') === 0) {
            return $path;
        }
        
        return $this->baseUrl . $path;
    }
    
    /**
     * Check if file exists
     */
    public function exists($path) {
        // Remove base URL if provided as full URL
        $path = str_replace($this->baseUrl, '', $path);
        
        $filePath = $this->uploadDir . $path;
        return file_exists($filePath);
    }
    
    /**
     * Get file size
     */
    public function getSize($path) {
        $path = str_replace($this->baseUrl, '', $path);
        $filePath = $this->uploadDir . $path;
        
        if (file_exists($filePath)) {
            return filesize($filePath);
        }
        
        return 0;
    }
}
