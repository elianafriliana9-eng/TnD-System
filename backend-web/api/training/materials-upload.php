<?php
/**
 * Training Materials Upload API
 * Upload training materials (PDF, PPTX)
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../utils/Headers.php';

Headers::setAPIHeaders();

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Temporarily disabled for testing
// if (!Auth::checkAuth()) {
//     Response::unauthorized('Authentication required');
// }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Validate required fields
    if (!isset($_POST['title']) || !isset($_FILES['file'])) {
        Response::error('Title and file are required', 400);
    }
    
    $title = $_POST['title'];
    $description = $_POST['description'] ?? null;
    $category = $_POST['category'] ?? 'other';
    
    // Validate file
    $file = $_FILES['file'];
    $allowedTypes = ['application/pdf', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'];
    $allowedExtensions = ['pdf', 'ppt', 'pptx'];
    
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $fileType = $file['type'];
    
    if (!in_array($fileExtension, $allowedExtensions)) {
        Response::error('Invalid file type. Only PDF, PPT, and PPTX are allowed', 400);
    }
    
    // Check file size (max 10MB)
    $maxSize = 10 * 1024 * 1024; // 10MB
    if ($file['size'] > $maxSize) {
        Response::error('File size exceeds maximum limit of 10MB', 400);
    }
    
    // Create upload directory if not exists
    $uploadDir = __DIR__ . '/../../uploads/training_materials/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
    
    // Generate unique filename
    $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $file['name']);
    $filePath = $uploadDir . $filename;
    $relativeFilePath = '/tnd_system/tnd_system/backend-web/uploads/training_materials/' . $filename;
    
    // Upload file
    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        Response::error('Failed to upload file', 500);
    }
    
    // Handle thumbnail if provided
    $thumbnailPath = null;
    if (isset($_FILES['thumbnail']) && $_FILES['thumbnail']['error'] === UPLOAD_ERR_OK) {
        $thumbnail = $_FILES['thumbnail'];
        $thumbExtension = strtolower(pathinfo($thumbnail['name'], PATHINFO_EXTENSION));
        $allowedThumbTypes = ['jpg', 'jpeg', 'png', 'gif'];
        
        if (in_array($thumbExtension, $allowedThumbTypes)) {
            $thumbDir = __DIR__ . '/../../uploads/training_thumbnails/';
            if (!is_dir($thumbDir)) {
                mkdir($thumbDir, 0777, true);
            }
            
            $thumbFilename = time() . '_thumb_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $thumbnail['name']);
            $thumbPath = $thumbDir . $thumbFilename;
            $relativeThumbnailPath = '/tnd_system/tnd_system/backend-web/uploads/training_thumbnails/' . $thumbFilename;
            
            if (move_uploaded_file($thumbnail['tmp_name'], $thumbPath)) {
                $thumbnailPath = $relativeThumbnailPath;
            }
        }
    }
    
    // Save to database
    $db = Database::getInstance()->getConnection();
    
    // Create table if not exists
    $db->exec("
        CREATE TABLE IF NOT EXISTS training_materials (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            category VARCHAR(100),
            file_path VARCHAR(255) NOT NULL,
            file_type VARCHAR(50),
            file_size INT,
            thumbnail_path VARCHAR(255),
            uploaded_by INT,
            uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_category (category),
            INDEX idx_uploaded_at (uploaded_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    
    $stmt = $db->prepare("
        INSERT INTO training_materials 
        (title, description, category, file_path, file_type, file_size, thumbnail_path, uploaded_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $uploadedBy = $_SESSION['user_id'] ?? null;
    
    $stmt->execute([
        $title,
        $description,
        $category,
        $relativeFilePath,
        $fileExtension,
        $file['size'],
        $thumbnailPath,
        $uploadedBy
    ]);
    
    $materialId = $db->lastInsertId();
    
    // Get inserted material
    $stmt = $db->prepare("SELECT * FROM training_materials WHERE id = ?");
    $stmt->execute([$materialId]);
    $material = $stmt->fetch(PDO::FETCH_ASSOC);
    
    Response::success($material, 'Material uploaded successfully', 201);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
