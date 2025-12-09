<?php
/**
 * Visit Detail API
 * Get complete visit details including responses and photos grouped properly
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

// Get current user
$currentUser = Auth::user();

try {
    if (!isset($_GET['visit_id'])) {
        Response::error('Visit ID required', 400);
    }
    
    $visitId = intval($_GET['visit_id']);
    $db = Database::getInstance()->getConnection();
    
    // Build the query with role-based access control
    $sql = "SELECT v.*, 
            o.name as outlet_name, 
            u.full_name as auditor_name,
            v.uang_omset_modal,
            v.uang_ditukar,
            v.cash,
            v.qris,
            v.debit_kredit,
            v.total,
            v.kategoric,
            v.leadtime,
            v.status_keuangan,
            v.crew_in_charge
            FROM visits v
            LEFT JOIN outlets o ON v.outlet_id = o.id
            LEFT JOIN users u ON v.user_id = u.id
            WHERE v.id = :visit_id";

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $sql .= " AND v.user_id = :user_id";
    // }
    
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':visit_id', $visitId);
    // if ($currentUser['role'] !== 'super_admin') {
    //     $stmt->bindParam(':user_id', $currentUser['id']);
    // }
    $stmt->execute();
    $visit = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$visit) {
        Response::error('Visit not found or you do not have permission to view it', 404);
    }
    
    // Get checklist responses with category info
    $sql = "SELECT 
                vcr.id,
                vcr.visit_id,
                vcr.checklist_point_id,
                vcr.response,
                vcr.notes,
                cp.question,
                cp.id as point_id,
                cc.name as category_name,
                cc.id as category_id
            FROM visit_checklist_responses vcr
            INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
            INNER JOIN checklist_categories cc ON cp.category_id = cc.id
            WHERE vcr.visit_id = :visit_id
            ORDER BY cc.sort_order, cp.sort_order";
    
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':visit_id', $visitId);
    $stmt->execute();
    $responses = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get photos - Production table: photos, Production columns: item_id, file_path
    $sql = "SELECT 
                id,
                visit_id,
                item_id as checklist_item_id,
                file_path as photo_path,
                caption as description,
                uploaded_at
            FROM photos
            WHERE visit_id = :visit_id
            ORDER BY item_id, id";
    
    $stmt = $db->prepare($sql);
    $stmt->bindParam(':visit_id', $visitId);
    $stmt->execute();
    $photos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Construct response
    $result = [
        'visit' => $visit,
        'responses' => $responses,
        'photos' => $photos
    ];
    
    Response::success($result);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
