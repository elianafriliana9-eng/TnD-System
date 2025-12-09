<?php
/**
 * Training Photo Upload API
 * 
 * Upload photo for training session
 * 
 * @endpoint POST /api/training/photo-upload.php
 * @auth Required
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Ngrok specific headers to skip warning page
if (isset($_SERVER['HTTP_HOST']) && strpos($_SERVER['HTTP_HOST'], 'ngrok') !== false) {
    header('ngrok-skip-browser-warning: true');
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';
require_once '../../utils/Response.php';
require_once '../../utils/Auth.php';

// Temporarily disabled for testing
// $auth = Auth::checkAuth();
// if (!$auth['authenticated']) {
//     Response::unauthorized('Authentication required');
// }

// Only POST method allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

// Validate required fields
if (!isset($_POST['session_id'])) {
    Response::error('Session ID is required', 400);
}

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
    Response::error('Photo file is required', 400);
}

$sessionId = $_POST['session_id'];
$participantId = $_POST['participant_id'] ?? null;
$caption = $_POST['caption'] ?? '';

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Verify session exists
    $stmt = $conn->prepare("SELECT id, status FROM training_sessions WHERE id = ?");
    $stmt->execute([$sessionId]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        Response::error('Training session not found', 404);
    }
    
    // Check if session is already completed
    if ($session['status'] === 'completed') {
        Response::error('Cannot upload photos to completed session', 400);
    }
    
    // Validate file
    $file = $_FILES['photo'];
    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    $maxSize = 5 * 1024 * 1024; // 5MB
    
    if (!in_array($file['type'], $allowedTypes)) {
        Response::error('Invalid file type. Only JPEG and PNG allowed', 400);
    }
    
    if ($file['size'] > $maxSize) {
        Response::error('File too large. Maximum size is 5MB', 400);
    }
    
    // Generate unique filename
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'training_' . $sessionId . '_' . time() . '_' . uniqid() . '.' . $extension;
    
    // Create upload directory if not exists
    $uploadDir = __DIR__ . '/../../uploads/training/photos/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
    
    $uploadPath = $uploadDir . $filename;
    $dbPath = 'backend-web/uploads/training/photos/' . $filename;
    
    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        Response::error('Failed to save photo file', 500);
    }
    
    // Save to database
    $sql = "INSERT INTO training_photos 
            (session_id, participant_id, photo_path, caption, uploaded_at) 
            VALUES (?, ?, ?, ?, NOW())";
    
    $stmt = $conn->prepare($sql);
    $stmt->execute([
        $sessionId,
        $participantId,
        $dbPath,
        $caption
    ]);
    
    $photoId = $conn->lastInsertId();
    
    // Return response
    Response::success([
        'id' => (int)$photoId,
        'session_id' => (int)$sessionId,
        'participant_id' => $participantId ? (int)$participantId : null,
        'photo_path' => $dbPath,
        'photo_url' => '/tnd_system/tnd_system/' . $dbPath,
        'caption' => $caption,
        'uploaded_at' => date('Y-m-d H:i:s')
    ], 'Photo uploaded successfully');
    
} catch (PDOException $e) {
    Response::error('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    Response::error($e->getMessage(), 500);
}
?>
