<?php
/**
 * Upload Profile Photo API
 * Upload user profile photo
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/Database.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication
    if (!Auth::check()) {
        Response::error('Authentication required', 401);
    }

    $user = Auth::user();

    if (!isset($_FILES['photo'])) {
        Response::error('No photo uploaded', 400);
    }

    // Handle file upload
    $uploadDir = __DIR__ . '/../uploads/profile_photos/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $file = $_FILES['photo'];
    
    // Validate file size (max 5MB)
    $maxFileSize = 5 * 1024 * 1024; // 5MB in bytes
    if ($file['size'] > $maxFileSize) {
        Response::error('File too large. Maximum size is 5MB', 400);
    }
    
    // Validate file type by extension
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExtensions = ['jpg', 'jpeg', 'png'];

    if (!in_array($fileExtension, $allowedExtensions)) {
        Response::error('Invalid file type. Only JPG, JPEG, PNG allowed', 400);
    }
    
    // Validate file type by MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    $allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (!in_array($mimeType, $allowedMimeTypes)) {
        Response::error('Invalid file type. Only JPG, JPEG, PNG images allowed', 400);
    }
    
    // Check file upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        Response::error('Upload error: ' . $file['error'], 500);
    }

    // Delete old profile photo if exists
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare("SELECT photo_path FROM users WHERE id = :user_id");
    $stmt->bindParam(':user_id', $user['id']);
    $stmt->execute();
    $oldPhotoPath = $stmt->fetchColumn();
    
    if ($oldPhotoPath && file_exists(__DIR__ . '/../' . $oldPhotoPath)) {
        unlink(__DIR__ . '/../' . $oldPhotoPath);
    }

    // Generate unique filename
    $fileName = 'user_' . $user['id'] . '_' . time() . '.' . $fileExtension;
    $filePath = $uploadDir . $fileName;

    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        Response::error('Failed to upload photo', 500);
    }

    // Update user photo_path in database
    $photoPath = 'uploads/profile_photos/' . $fileName;
    $updateSql = "UPDATE users SET photo_path = :photo_path WHERE id = :user_id";
    $updateStmt = $db->prepare($updateSql);
    $updateStmt->bindParam(':photo_path', $photoPath);
    $updateStmt->bindParam(':user_id', $user['id']);
    
    if ($updateStmt->execute()) {
        // Generate full URL
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $baseUrl = $protocol . '://' . $host . '/tnd_system/tnd_system/backend-web/';
        $photoUrl = $baseUrl . $photoPath;
        
        Response::success([
            'photo_path' => $photoPath,
            'photo_url' => $photoUrl,
            'message' => 'Profile photo updated successfully'
        ]);
    } else {
        // Delete uploaded file if DB update failed
        unlink($filePath);
        Response::error('Failed to update profile photo', 500);
    }
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
