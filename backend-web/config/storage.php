<?php
/**
 * Storage Configuration
 * Configure storage settings here
 */

// ==========================================
// STORAGE SETTINGS
// ==========================================

// Storage Type: 'local' or 'cloudinary'
// For development: use 'local'
// For production: use 'cloudinary'
define('STORAGE_TYPE', 'local'); // Change to 'cloudinary' when ready

// Use Cloudinary? (will be true when STORAGE_TYPE === 'cloudinary')
define('USE_CLOUDINARY', STORAGE_TYPE === 'cloudinary');

// ==========================================
// LOCAL STORAGE SETTINGS
// ==========================================

// Upload directory (relative to backend-web/)
define('UPLOAD_DIR', __DIR__ . '/../uploads/');

// Base URL for uploads
// Auto-detect or set manually
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
define('UPLOAD_BASE_URL', $protocol . '://' . $host . '/tnd_system/tnd_system/backend-web/uploads/');

// ==========================================
// CLOUDINARY SETTINGS (for production)
// ==========================================

// Uncomment and fill when ready to use Cloudinary:
/*
putenv('CLOUDINARY_CLOUD_NAME=your-cloud-name');
putenv('CLOUDINARY_API_KEY=your-api-key');
putenv('CLOUDINARY_API_SECRET=your-api-secret');

// Or use CLOUDINARY_URL:
// putenv('CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name');
*/

// ==========================================
// FILE UPLOAD SETTINGS
// ==========================================

// Allowed file types
define('ALLOWED_IMAGE_TYPES', ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']);

// Max file size (in bytes)
define('MAX_FILE_SIZE', 5 * 1024 * 1024); // 5MB

// Image quality for compression (1-100)
define('IMAGE_QUALITY', 85);

// ==========================================
// FOLDERS
// ==========================================

define('FOLDER_VISIT_PHOTOS', 'visit_photos');
define('FOLDER_PROFILE_PHOTOS', 'profile_photos');
define('FOLDER_OUTLET_PHOTOS', 'outlet_photos');
