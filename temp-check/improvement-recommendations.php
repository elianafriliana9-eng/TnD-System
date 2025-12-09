<?php
/**
 * Improvement Recommendations API
 * Get NOK findings for improvement recommendations
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
    $db = Database::getInstance()->getConnection();
    $userId = $_SESSION['user_id'];
    
    // Get user info
    $stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Check if requesting specific visit's findings
    if (isset($_GET['visit_id'])) {
        $visitId = $_GET['visit_id'];
        
        // Get visit details
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
                    d.name as division_name
                FROM visits v
                INNER JOIN outlets o ON v.outlet_id = o.id
                INNER JOIN users u ON v.user_id = u.id
                LEFT JOIN divisions d ON u.division_id = d.id
                WHERE v.id = ?";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$visitId]);
        $visit = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$visit) {
            Response::error('Visit not found', 404);
            exit;
        }
        
        // Get NOK findings with photos for this visit
        // Simplified query to avoid duplicates
        $sql = "SELECT 
                    vcr.id as response_id,
                    vcr.response,
                    vcr.notes as response_notes,
                    vcr.recommendation,
                    vcr.checklist_item_id,
                    cp.question as checklist_question,
                    cp.id as checklist_id,
                    cc.name as category_name,
                    cc.id as category_id
                FROM visit_checklist_responses vcr
                INNER JOIN checklist_points cp ON vcr.checklist_item_id = cp.id
                INNER JOIN checklist_categories cc ON cp.category_id = cc.id
                WHERE vcr.visit_id = ?
                AND vcr.response = 'not_ok'
                ORDER BY cc.id, cp.id";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$visitId]);
        $findings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // DEBUG: Log findings after query
        error_log("DEBUG API - Visit $visitId - Findings after query: " . count($findings));
        foreach ($findings as $i => $f) {
            error_log("  Finding $i: Response {$f['response_id']}, Item {$f['checklist_item_id']}, Question: {$f['checklist_question']}");
        }
        
        // Get photos separately to avoid duplicate rows
        $photoSql = "SELECT 
                        vp.checklist_item_id,
                        vp.photo_path
                     FROM visit_photos vp
                     WHERE vp.visit_id = ?
                     ORDER BY vp.checklist_item_id, vp.id";
        
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
        
        // Process findings to add photo URLs
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $baseUrl = $protocol . '://' . $host . '/tnd_system/tnd_system/backend-web/';
        
        // Create processed findings array (avoid modifying original)
        $processedFindings = [];
        foreach ($findings as $finding) {
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
            
            // Remove checklist_item_id from output (internal use only)
            unset($finding['checklist_item_id']);
            
            $processedFindings[] = $finding;
        }
        
        // DEBUG: Log findings after adding photos
        error_log("DEBUG API - Findings after adding photos: " . count($processedFindings));
        foreach ($processedFindings as $i => $f) {
            error_log("  Finding $i: Response {$f['response_id']}, Question: {$f['checklist_question']}");
        }
        
        // Group findings by category NAME to handle any remaining duplicates
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
        
        // DEBUG: Log final findings_flat before response
        error_log("DEBUG API - Final findings_flat count: " . count($processedFindings));
        error_log("DEBUG API - Final findings_flat: " . json_encode(array_map(function($f) {
            return ['response_id' => $f['response_id'], 'question' => $f['checklist_question']];
        }, $processedFindings)));
        
        Response::success([
            'visit' => $visit,
            'findings_grouped' => array_values($groupedFindings),
            'findings_flat' => $processedFindings,
            'total_findings' => count($processedFindings)
        ]);
        exit;
    }
    
    // Get all visits with NOK findings for current user
    $sql = "SELECT DISTINCT
                v.id,
                v.visit_date,
                v.status,
                o.name as outlet_name,
                o.region as outlet_region,
                d.name as division_name,
                -- Count NOK findings
                (SELECT COUNT(*) 
                 FROM visit_checklist_responses vcr 
                 WHERE vcr.visit_id = v.id 
                 AND vcr.response = 'not_ok') as nok_count,
                -- Count photos
                (SELECT COUNT(*)
                 FROM visit_photos vp
                 WHERE vp.visit_id = v.id) as photo_count
            FROM visits v
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN users u ON v.user_id = u.id
            LEFT JOIN divisions d ON u.division_id = d.id
            WHERE v.user_id = ?
            AND v.status = 'completed'
            AND EXISTS (
                SELECT 1 FROM visit_checklist_responses vcr
                WHERE vcr.visit_id = v.id AND vcr.response = 'not_ok'
            )
            ORDER BY v.visit_date DESC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute([$userId]);
    $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    Response::success([
        'data' => $visits,
        'total' => count($visits)
    ]);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
