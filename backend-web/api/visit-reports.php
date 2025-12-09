<?php
/**
 * Visit Reports API
 * For Web Super Admin to view visit data from mobile app
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
    $db = Database::getInstance()->getConnection();
    
    // Check if requesting divisions list
    if (isset($_GET['divisions']) && $_GET['divisions'] === 'true') {
        $sql = "SELECT DISTINCT d.name as division_name
                FROM visits v
                INNER JOIN users u ON v.user_id = u.id
                LEFT JOIN divisions d ON u.division_id = d.id
                WHERE d.name IS NOT NULL
                ORDER BY d.name";
        
        $stmt = $db->query($sql);
        $divisions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        Response::success([
            'data' => $divisions,
            'total' => count($divisions)
        ]);
        exit;
    }
    
    // Check if requesting findings (NOK responses)
    if (isset($_GET['findings']) && $_GET['findings'] === 'true') {
        // Build WHERE clause for filters
        // Production: response case-insensitive (NOT OK, not_ok, not ok, etc.)
        $whereConditions = ["(LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
                             OR LOWER(vcr.response) = 'not ok'
                             OR vcr.response = 'NOT OK')"];
        $params = [];

        // Role-based filtering - DISABLED to show all data
        // if ($currentUser['role'] !== 'super_admin') {
        //     $whereConditions[] = "v.user_id = :user_id";
        //     $params[':user_id'] = $currentUser['id'];
        // }
        
        if (!empty($_GET['outlet_id'])) {
            $whereConditions[] = "v.outlet_id = :outlet_id";
            $params[':outlet_id'] = $_GET['outlet_id'];
        }
        
        if (!empty($_GET['division'])) {
            $whereConditions[] = "d.name = :division";
            $params[':division'] = $_GET['division'];
        }
        
        if (!empty($_GET['date_from'])) {
            $whereConditions[] = "DATE(v.visit_date) >= :date_from";
            $params[':date_from'] = $_GET['date_from'];
        }
        
        if (!empty($_GET['date_to'])) {
            $whereConditions[] = "DATE(v.visit_date) <= :date_to";
            $params[':date_to'] = $_GET['date_to'];
        }
        
        $whereClause = implode(' AND ', $whereConditions);
        
        // Get all NOK (not_ok) responses with details
        $sql = "SELECT 
                    vcr.id,
                    vcr.visit_id,
                    v.visit_date,
                    o.name as outlet_name,
                    o.id as outlet_id,
                    u.full_name as auditor_name,
                    d.name as division_name,
                    cp.question as checklist_point_question,
                    cp.id as checklist_point_id,
                    cc.name as category_name,
                    vcr.response,
                    -- Get photo count for this response
                    (SELECT COUNT(*) FROM photos p 
                     WHERE p.visit_id = vcr.visit_id 
                     AND p.item_id = vcr.checklist_point_id) as photo_count
                FROM visit_checklist_responses vcr
                INNER JOIN visits v ON vcr.visit_id = v.id
                INNER JOIN outlets o ON v.outlet_id = o.id
                INNER JOIN users u ON v.user_id = u.id
                LEFT JOIN divisions d ON u.division_id = d.id
                INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
                INNER JOIN checklist_categories cc ON cp.category_id = cc.id
                WHERE $whereClause
                ORDER BY v.visit_date DESC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $findings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        Response::success([
            'data' => $findings,
            'total' => count($findings)
        ]);
        exit;
    }
    
    // Build WHERE clause for visits filters
    $whereConditions = ["v.status = 'completed'"];
    $params = [];

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $whereConditions[] = "v.user_id = :user_id";
    //     $params[':user_id'] = $currentUser['id'];
    // }
    
    if (!empty($_GET['outlet_id'])) {
        $whereConditions[] = "v.outlet_id = :outlet_id";
        $params[':outlet_id'] = $_GET['outlet_id'];
    }
    
    if (!empty($_GET['division'])) {
        $whereConditions[] = "d.name = :division";
        $params[':division'] = $_GET['division'];
    }
    
    if (!empty($_GET['date_from'])) {
        $whereConditions[] = "DATE(v.visit_date) >= :date_from";
        $params[':date_from'] = $_GET['date_from'];
    }
    
    if (!empty($_GET['date_to'])) {
        $whereConditions[] = "DATE(v.visit_date) <= :date_to";
        $params[':date_to'] = $_GET['date_to'];
    }
    
    $whereClause = implode(' AND ', $whereConditions);
    
    // Get all visits with details
    $sql = "SELECT 
                v.id,
                v.outlet_id,
                v.user_id,
                v.visit_date,
                v.status,
                v.notes,
                o.name as outlet_name,
                o.address as outlet_address,
                o.region as outlet_region,
                u.full_name as auditor_name,
                u.email as auditor_email,
                d.name as division_name,
                -- Calculate score from checklist responses (case-insensitive)
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id 
                    AND (LOWER(vcr.response) = 'ok' OR vcr.response = 'OK')
                ) as ok_count,
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id 
                    AND (LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
                         OR LOWER(vcr.response) = 'not ok'
                         OR vcr.response = 'NOT OK')
                ) as not_ok_count,
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id 
                    AND (LOWER(vcr.response) = 'na' OR vcr.response = 'NA' OR vcr.response = 'N/A')
                ) as na_count,
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id
                ) as total_responses
            FROM visits v
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN users u ON v.user_id = u.id
            LEFT JOIN divisions d ON u.division_id = d.id
            WHERE $whereClause
            ORDER BY v.visit_date DESC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Calculate score percentage for each visit
    foreach ($visits as &$visit) {
        $total = $visit['total_responses'];
        if ($total > 0) {
            // Score = (OK responses / Total responses excluding NA) * 100
            $totalExcludingNA = $total - $visit['na_count'];
            if ($totalExcludingNA > 0) {
                $visit['score'] = round(($visit['ok_count'] / $totalExcludingNA) * 100, 2);
            } else {
                $visit['score'] = 0;
            }
        } else {
            $visit['score'] = 0;
        }
    }
    
    Response::success([
        'data' => $visits,
        'total' => count($visits)
    ]);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
