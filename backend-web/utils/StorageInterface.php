<?php
/**
 * Storage Interface
 * Abstraction layer for file storage (Local/Cloud)
 */

interface StorageInterface {
    /**
     * Upload a file
     * @param array $file - $_FILES array element
     * @param string $folder - Target folder (e.g., 'visit_photos', 'profile_photos')
     * @return array - ['success' => bool, 'url' => string, 'path' => string]
     */
    public function upload($file, $folder = 'uploads');
    
    /**
     * Delete a file
     * @param string $path - File path or URL
     * @return bool - Success status
     */
    public function delete($path);
    
    /**
     * Get public URL for a file
     * @param string $path - File path
     * @return string - Full public URL
     */
    public function getUrl($path);
    
    /**
     * Check if file exists
     * @param string $path - File path
     * @return bool
     */
    public function exists($path);
}
