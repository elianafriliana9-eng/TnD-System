<?php
/**
 * Generate Improvement Recommendation PDF Report
 * Creates PDF report with NOK findings and recommendations
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';

// Set CORS headers manually
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Authentication required']);
    exit;
}

// Get current user
$currentUser = Auth::user();

if (!isset($_GET['visit_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Visit ID required']);
    exit;
}

try {
    $db = Database::getInstance()->getConnection();
    $visitId = $_GET['visit_id'];
    
    // Build the query with role-based access control
    $sql = "SELECT 
                v.id,
                v.visit_date,
                v.status,
                v.notes,
                o.name as outlet_name,
                o.address as outlet_address,
                o.region as outlet_region,
                u.full_name as auditor_name,
                u.email as auditor_email,
                u.phone as auditor_phone,
                d.name as division_name
            FROM visits v
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN users u ON v.user_id = u.id
            LEFT JOIN divisions d ON u.division_id = d.id
            WHERE v.id = ?";

    $params = [$visitId];

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $sql .= " AND v.user_id = ?";
    //     $params[] = $currentUser['id'];
    // }
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $visit = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$visit) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Visit not found or you do not have permission to view it']);
        exit;
    }
    
    // Get NOK findings with recommendations - Use separate queries to avoid duplicates
    // Production schema: NO 'recommendation' column, use 'notes' instead
    // Production: checklist_point_id (not checklist_item_id)
    $sql = "SELECT 
                vcr.id as response_id,
                vcr.response,
                vcr.notes as response_notes,
                vcr.checklist_point_id as checklist_item_id,
                cp.question as checklist_question,
                cp.id as checklist_id,
                cc.name as category_name,
                cc.id as category_id
            FROM visit_checklist_responses vcr
            INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
            INNER JOIN checklist_categories cc ON cp.category_id = cc.id
            WHERE vcr.visit_id = ?
            AND (LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
                 OR LOWER(vcr.response) = 'not ok'
                 OR vcr.response = 'NOT OK')
            ORDER BY cc.id, cp.id";
    
    $stmt = $db->prepare($sql);
    $stmt->execute([$visitId]);
    $findings = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get photos separately
    // Production table: photos (not visit_photos)
    // Production columns: item_id (not checklist_item_id), file_path (not photo_path)
    $photoSql = "SELECT 
                    p.item_id as checklist_item_id,
                    p.file_path as photo_path
                 FROM photos p
                 WHERE p.visit_id = ?
                 ORDER BY p.item_id, p.id";
    
    $stmt = $db->prepare($photoSql);
    $stmt->execute([$visitId]);
    $photos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Group photos by checklist_item_id
    $photosByItem = [];
    foreach ($photos as $photo) {
        $itemId = $photo['checklist_item_id'];
        if (!isset($photosByItem[$itemId])) {
            $photosByItem[$itemId] = [];
        }
        $photosByItem[$itemId][] = $photo['photo_path'];
    }
    
    // Return JSON data for client-side PDF generation
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . '://' . $host . '/backend-web/';
    
    // Process findings to add photo URLs
    foreach ($findings as &$finding) {
        $itemId = $finding['checklist_item_id'];
        
        // Add photos for this checklist item
        if (isset($photosByItem[$itemId])) {
            $photoUrls = [];
            foreach ($photosByItem[$itemId] as $path) {
                $photoUrls[] = [
                    'path' => $path,
                    'url' => $baseUrl . $path
                ];
            }
            $finding['photos'] = $photoUrls;
        } else {
            $finding['photos'] = [];
        }
        
        // Remove checklist_item_id from output
        unset($finding['checklist_item_id']);
    }
    
    // Return data for PDF generation (flat structure expected by Flutter)
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'data' => [
            'visit' => $visit,
            'findings_flat' => $findings,
            'total_findings' => count($findings)
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
