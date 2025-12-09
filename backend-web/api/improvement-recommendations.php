<?php
/**
 * Improvement Recommendations API
 * Get NOK findings for improvement recommendations
 */

// Enable error logging
error_log("=== IMPROVEMENT RECOMMENDATIONS API CALLED ===");
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request URI: " . $_SERVER['REQUEST_URI']);
error_log("GET params: " . json_encode($_GET));

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
    exit;
}

// Get current user from auth
$currentUser = Auth::user();
if (!$currentUser || !isset($currentUser['id'])) {
    Response::unauthorized('User not found');
    exit;
}

try {
    error_log("=== IMPROVEMENT RECOMMENDATIONS: Start ===");
    error_log("Step 1: Getting database instance");
    $db = Database::getInstance()->getConnection();
    error_log("Step 2: Database connected successfully");
    
    // Check if requesting specific visit's findings
    if (isset($_GET['visit_id'])) {
        error_log("Step 3: Processing specific visit_id = " . $_GET['visit_id']);
        $visitId = $_GET['visit_id'];
        
        // Build the query with role-based access control
        $sql = "SELECT 
                    v.id,
                    v.visit_date,
                    v.check_in_time,
                    v.started_at,
                    v.status,
                    v.notes,
                    o.name as outlet_name,
                    o.address as outlet_address,
                    o.region as outlet_region,
                    u.full_name as auditor_name,
                    u.email as auditor_email,
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
            Response::error('Visit not found or you do not have permission to view it', 404);
            exit;
        }
        
        // Get NOK findings with photos for this visit
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
                AND LOWER(REPLACE(vcr.response, ' ', '')) = 'notok'
                ORDER BY cc.id, cp.id";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$visitId]);
        $findings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get photos separately to avoid duplicate rows
        $photoSql = "SELECT 
                        p.item_id as checklist_item_id,
                        p.file_path as photo_path
                     FROM photos p
                     WHERE p.visit_id = ?
                     AND p.item_id IN (
                         SELECT vcr.checklist_point_id 
                         FROM visit_checklist_responses vcr 
                         WHERE vcr.visit_id = ? 
                         AND LOWER(REPLACE(vcr.response, ' ', '')) = 'notok'
                     )
                     ORDER BY p.item_id, p.id";
        
        $stmt = $db->prepare($photoSql);
        $stmt->execute([$visitId, $visitId]);
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
        
        // Process findings to add photo URLs
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
        $baseUrl = $protocol . '://' . $host . '/backend-web/';
        
        $processedFindings = [];
        foreach ($findings as $finding) {
            $itemId = $finding['checklist_item_id'];
            
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
            
            unset($finding['checklist_item_id']);
            $processedFindings[] = $finding;
        }
        
        $groupedFindings = [];
        foreach ($processedFindings as $finding) {
            $categoryName = $finding['category_name'];
            if (!isset($groupedFindings[$categoryName])) {
                $groupedFindings[$categoryName] = [
                    'category_id' => $finding['category_id'],
                    'category_name' => $categoryName,
                    'findings' => []
                ];
            }
            $groupedFindings[$categoryName]['findings'][] = $finding;
        }
        
        Response::success([
            'visit' => $visit,
            'findings_grouped' => array_values($groupedFindings),
            'findings_flat' => $processedFindings,
            'total_findings' => count($processedFindings)
        ]);
        exit;
    }
    
    // Build the main query for all visits with NOK findings
    error_log("Step 4: Building query for all visits with NOK findings");
    $sql = "SELECT DISTINCT
                v.id,
                v.visit_date,
                v.check_in_time,
                v.started_at,
                v.status,
                o.name as outlet_name,
                o.region as outlet_region,
                d.name as division_name,
                -- Count NOK findings (case-insensitive)
                (SELECT COUNT(*) 
                 FROM visit_checklist_responses vcr 
                 WHERE vcr.visit_id = v.id 
                 AND LOWER(REPLACE(vcr.response, ' ', '')) = 'notok') as nok_count,
                -- Count photos for NOK findings
                (SELECT COUNT(*)
                 FROM photos p
                 INNER JOIN visit_checklist_responses vcr ON p.item_id = vcr.checklist_point_id AND p.visit_id = vcr.visit_id
                 WHERE p.visit_id = v.id
                 AND LOWER(REPLACE(vcr.response, ' ', '')) = 'notok') as photo_count
            FROM visits v
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN users u ON v.user_id = u.id
            LEFT JOIN divisions d ON u.division_id = d.id
            WHERE v.status = 'completed'
            AND EXISTS (
                SELECT 1 FROM visit_checklist_responses vcr
                WHERE vcr.visit_id = v.id 
                AND LOWER(REPLACE(vcr.response, ' ', '')) = 'notok'
            )";

    $params = [];

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $sql .= " AND v.user_id = ?";
    //     $params[] = $currentUser['id'];
    // }

    $sql .= " ORDER BY v.visit_date DESC";
    
    error_log("Step 5: Executing query");
    error_log("SQL: " . substr($sql, 0, 200));
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    error_log("Step 6: Query successful. Found " . count($visits) . " visits");
    
    Response::success([
        'data' => $visits,
        'total' => count($visits)
    ]);
    
} catch (Exception $e) {
    error_log("=== ERROR in improvement-recommendations.php ===");
    error_log("ERROR Message: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
