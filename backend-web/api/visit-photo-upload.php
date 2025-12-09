<?php
/**
 * Upload Visit Photo API
 * Upload photo for visit findings
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/Visit.php';

// Start session if not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Ngrok specific headers to skip warning page
if (isset($_SERVER['HTTP_HOST']) && strpos($_SERVER['HTTP_HOST'], 'ngrok') !== false) {
    header('ngrok-skip-browser-warning: true');
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

// Log request for debugging
error_log('=== VISIT PHOTO UPLOAD REQUEST ===');
error_log('Request Method: ' . $_SERVER['REQUEST_METHOD']);
error_log('Content-Type: ' . ($_SERVER['CONTENT_TYPE'] ?? 'Not set'));
error_log('Content-Length: ' . ($_SERVER['CONTENT_LENGTH'] ?? 'Not set'));
error_log('Headers: ' . json_encode(getallheaders()));
error_log('POST data: ' . json_encode($_POST));
error_log('POST data count: ' . count($_POST));
error_log('FILES: ' . json_encode($_FILES));
error_log('FILES count: ' . count($_FILES));

// Log raw input for debugging
$rawInput = file_get_contents('php://input');
error_log('Raw input length: ' . strlen($rawInput));
if (strlen($rawInput) > 0 && strlen($rawInput) < 1000) {
    error_log('Raw input (first 1000 chars): ' . substr($rawInput, 0, 1000));
}

try {
    // Check authentication
    if (!Auth::checkAuth()) {
        error_log('AUTH FAILED: No valid session or token');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit;
    }

    // Get current user
    $currentUser = Auth::getUserFromHeader();
    if (!$currentUser) {
        $currentUser = Auth::user();
    }
    
    if (!$currentUser) {
        error_log('AUTH FAILED: Could not get user');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }
    
    $user = $currentUser;
    error_log('AUTH SUCCESS: User ID ' . $user['id']);

    // Validate input with detailed logging
    error_log('Validating visit_id...');
    if (!isset($_POST['visit_id'])) {
        error_log('VALIDATION FAILED: visit_id not in $_POST');
        error_log('Available POST keys: ' . implode(', ', array_keys($_POST)));
        Response::error('Missing required field: visit_id', 400);
    }
    error_log('visit_id: ' . $_POST['visit_id']);

    error_log('Validating photo file...');
    if (!isset($_FILES['photo'])) {
        error_log('VALIDATION FAILED: photo not in $_FILES');
        error_log('Available FILES keys: ' . implode(', ', array_keys($_FILES)));
        error_log('$_FILES array: ' . print_r($_FILES, true));
        Response::error('No photo uploaded', 400);
    }
    error_log('Photo file found in $_FILES');

    $visitModel = new Visit();
    
    // Verify visit belongs to user
    $visit = $visitModel->findById($_POST['visit_id']);
    if (!$visit) {
        Response::error('Visit not found', 404);
    }
    if ($visit['user_id'] != $user['id'] && !Auth::isAdmin()) {
        Response::error('Access denied', 403);
    }

    // Handle file upload
    $uploadDir = __DIR__ . '/../uploads/photos/';
    
    // Ensure upload directory exists with proper permissions
    if (!file_exists($uploadDir)) {
        error_log('Creating upload directory: ' . $uploadDir);
        if (!mkdir($uploadDir, 0755, true)) {
            error_log('CRITICAL: Failed to create upload directory: ' . $uploadDir);
            error_log('Parent directory writable: ' . (is_writable(dirname($uploadDir)) ? 'YES' : 'NO'));
            Response::error('Upload directory not available. Please contact administrator.', 500);
        }
        error_log('Upload directory created successfully');
    }
    
    // Verify directory is writable
    if (!is_writable($uploadDir)) {
        error_log('CRITICAL: Upload directory not writable: ' . $uploadDir);
        error_log('Directory permissions: ' . substr(sprintf('%o', fileperms($uploadDir)), -4));
        Response::error('Upload directory not writable. Please contact administrator.', 500);
    }

    $file = $_FILES['photo'];
    error_log('File info: ' . json_encode($file));
    
    // Validate file size (max 5MB)
    $maxFileSize = 5 * 1024 * 1024; // 5MB in bytes
    if ($file['size'] > $maxFileSize) {
        error_log('File too large: ' . $file['size'] . ' bytes (max: ' . $maxFileSize . ')');
        Response::error('File too large. Maximum size is 5MB', 400);
    }
    
    // Validate file type by extension
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExtensions = ['jpg', 'jpeg', 'png'];

    if (!in_array($fileExtension, $allowedExtensions)) {
        error_log('Invalid file extension: ' . $fileExtension);
        Response::error('Invalid file type. Only JPG, JPEG, PNG allowed', 400);
    }
    
    // Validate file type by MIME type (with fallback if fileinfo not available)
    $mimeType = null;
    if (function_exists('finfo_open')) {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);
        
        $allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png'];
        if (!in_array($mimeType, $allowedMimeTypes)) {
            error_log('Invalid MIME type: ' . $mimeType);
            Response::error('Invalid file type. Only JPG, JPEG, PNG images allowed', 400);
        }
    } else {
        // Fallback: Use uploaded file type or default based on extension
        error_log('WARNING: fileinfo extension not available, skipping MIME validation');
        $mimeType = $file['type'] ?? 'image/jpeg'; // Use uploaded type or default
    }

    // Check file upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        error_log('Upload error code: ' . $file['error']);
        Response::error('Upload error: ' . $file['error'], 500);
    }

    // Generate safe filename (sanitize original filename and add unique ID)
    $safeBaseName = preg_replace('/[^a-zA-Z0-9_-]/', '_', pathinfo($file['name'], PATHINFO_FILENAME));
    $fileName = 'visit_' . $_POST['visit_id'] . '_' . time() . '_' . uniqid() . '.' . $fileExtension;
    $filePath = $uploadDir . $fileName;
    
    error_log('Attempting to move file to: ' . $filePath);
    error_log('Source file exists: ' . (file_exists($file['tmp_name']) ? 'YES' : 'NO'));
    error_log('Source file size: ' . (file_exists($file['tmp_name']) ? filesize($file['tmp_name']) : 'N/A'));
    error_log('Destination directory writable: ' . (is_writable($uploadDir) ? 'YES' : 'NO'));

    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        $error = error_get_last();
        error_log('CRITICAL: Failed to move uploaded file');
        error_log('Source: ' . $file['tmp_name']);
        error_log('Destination: ' . $filePath);
        error_log('Last PHP error: ' . json_encode($error));
        error_log('Upload directory exists: ' . (file_exists($uploadDir) ? 'YES' : 'NO'));
        error_log('Upload directory writable: ' . (is_writable($uploadDir) ? 'YES' : 'NO'));
        
        Response::error('Failed to save uploaded file. Please contact administrator.', 500);
    }
    
    error_log('File uploaded successfully: ' . $filePath);

    // Get actual file size after upload
    $actualFileSize = filesize($filePath);
    
    // Save photo record to database with complete info
    $photoData = [
        'visit_id' => $_POST['visit_id'],
        'checklist_item_id' => $_POST['checklist_item_id'] ?? null,
        'photo_path' => 'uploads/photos/' . $fileName,
        'description' => $_POST['description'] ?? null,
        'file_size' => $actualFileSize,
        'mime_type' => $mimeType, // Already validated above
    ];
    
    error_log('Saving photo to database: ' . json_encode($photoData));

    $photoId = $visitModel->savePhoto($photoData);

    if ($photoId) {
        error_log('Photo saved to database with ID: ' . $photoId);
        // Get base URL dynamically
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
        
        // Handle ngrok forwarded proto
        if (isset($_SERVER['HTTP_X_FORWARDED_PROTO'])) {
            $protocol = $_SERVER['HTTP_X_FORWARDED_PROTO'];
        }
        
        // Production URL: https://tndsystem.online/backend-web/
        $baseUrl = $protocol . '://' . $host . '/backend-web/';
        $fullPhotoUrl = $baseUrl . $photoData['photo_path'];
        
        Response::success([
            'id' => $photoId,
            'photo_path' => $photoData['photo_path'],
            'full_url' => $fullPhotoUrl,
            'message' => 'Photo uploaded successfully'
        ]);
    } else {
        // Delete uploaded file if DB insert failed
        unlink($filePath);
        Response::error('Failed to save photo record', 500);
    }
} catch (Exception $e) {
    error_log('EXCEPTION: ' . $e->getMessage());
    error_log('TRACE: ' . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>
