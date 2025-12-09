<?php
/**
 * Finding Photos API
 * Get photos for specific finding (outlet + checklist point)
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

try {
    // Accept both 'outlet' and 'outlet_name' for backward compatibility
    if ((!isset($_GET['outlet']) && !isset($_GET['outlet_name'])) || !isset($_GET['question'])) {
        Response::error('Outlet name and question required', 400);
        exit;
    }
    
    $db = Database::getInstance()->getConnection();
    
    $question = $_GET['question'];
    $outletName = isset($_GET['outlet']) ? $_GET['outlet'] : $_GET['outlet_name'];
    
    // Get photos for this finding
    // Production table: photos (not visit_photos)
    // Production columns: item_id (not checklist_item_id), file_path (not photo_path)
    $sql = "SELECT 
                p.id,
                p.file_path as photo_path,
                p.uploaded_at,
                v.visit_date,
                o.name as outlet_name,
                cp.question as checklist_point,
                cc.name as category_name
            FROM photos p
            INNER JOIN visits v ON p.visit_id = v.id
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN checklist_points cp ON p.item_id = cp.id
            INNER JOIN checklist_categories cc ON cp.category_id = cc.id
            WHERE o.name = :outlet_name 
            AND cp.question = :question
            ORDER BY v.visit_date DESC";
    
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':outlet_name', $outletName);
    $stmt->bindParam(':question', $question);
    $stmt->execute();
    $photos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Convert photo_path to full URL
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . '://' . $host . '/backend-web/';
    
    foreach ($photos as &$photo) {
        if (!empty($photo['photo_path'])) {
            $photo['photo_url'] = $baseUrl . $photo['photo_path'];
        }
    }
    
    Response::success([
        'data' => $photos,
        'total' => count($photos)
    ]);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
