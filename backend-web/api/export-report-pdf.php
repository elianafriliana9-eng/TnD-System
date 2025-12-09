<?php
/**
 * Export Report PDF API
 * Get complete data for PDF generation
 * 
 * Endpoints:
 * GET /api/export-report-pdf.php?user_id={id}&report_type={type}&start_date={date}&end_date={date}&outlet_id={id}
 * report_type: overview | outlet | outlet_detail
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

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

// Get parameters
$reportType = isset($_GET['report_type']) ? $_GET['report_type'] : 'overview';
$startDate = isset($_GET['start_date']) ? $_GET['start_date'] : null;
$endDate = isset($_GET['end_date']) ? $_GET['end_date'] : null;
$outletId = isset($_GET['outlet_id']) ? intval($_GET['outlet_id']) : null;

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Get user info
    $stmt = $conn->prepare("
        SELECT u.id, u.full_name, u.email, d.name as division_name
        FROM users u
        LEFT JOIN divisions d ON u.division_id = d.id
        WHERE u.id = ?
    ");
    $stmt->execute([$currentUser['id']]);
    $userInfo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$userInfo) {
        throw new Exception("User not found");
    }
    
    $response = [
        'success' => true,
        'report_type' => $reportType,
        'generated_at' => date('Y-m-d H:i:s'),
        'user' => [
            'id' => intval($userInfo['id']),
            'name' => $userInfo['full_name'],
            'email' => $userInfo['email'],
            'division' => $userInfo['division_name']
        ],
        'filters' => [
            'start_date' => $startDate,
            'end_date' => $endDate
        ],
        'data' => []
    ];
    
    // Build base WHERE clause and params
    $whereConditions = ["v.status = 'completed'"];
    $params = [];

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $whereConditions[] = "v.user_id = ?";
    //     $params[] = $currentUser['id'];
    // }

    // Date filtering
    if ($startDate && $endDate) {
        $whereConditions[] = "DATE(v.visit_date) BETWEEN ? AND ?";
        $params[] = $startDate;
        $params[] = $endDate;
    } elseif ($startDate) {
        $whereConditions[] = "DATE(v.visit_date) >= ?";
        $params[] = $startDate;
    } elseif ($endDate) {
        $whereConditions[] = "DATE(v.visit_date) <= ?";
        $params[] = $endDate;
    }

    $whereClause = "WHERE " . implode(' AND ', $whereConditions);
    
    if ($reportType === 'overview') {
        // Get overview statistics
        $stmt = $conn->prepare("
            SELECT 
                COUNT(DISTINCT v.id) as total_visits,
                COUNT(DISTINCT v.outlet_id) as total_outlets,
                SUM(CASE WHEN LOWER(vcr.response) = 'ok' THEN 1 ELSE 0 END) as ok_count,
                SUM(CASE WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok' THEN 1 ELSE 0 END) as nok_count,
                SUM(CASE WHEN LOWER(vcr.response) = 'na' THEN 1 ELSE 0 END) as na_count
            FROM visits v
            LEFT JOIN visit_checklist_responses vcr ON v.id = vcr.visit_id
            $whereClause
        ");
        $stmt->execute($params);
        $stats = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $okCount = intval($stats['ok_count']);
        $nokCount = intval($stats['nok_count']);
        $totalWithoutNA = $okCount + $nokCount;
        
        $response['data']['statistics'] = [
            'total_visits' => intval($stats['total_visits']),
            'total_outlets' => intval($stats['total_outlets']),
            'ok_count' => $okCount,
            'nok_count' => $nokCount,
            'na_count' => intval($stats['na_count']),
            'ok_percentage' => $totalWithoutNA > 0 ? round(($okCount / $totalWithoutNA) * 100, 1) : 0,
            'nok_percentage' => $totalWithoutNA > 0 ? round(($nokCount / $totalWithoutNA) * 100, 1) : 0
        ];
        
        // Get all outlets summary for PDF
        $stmt = $conn->prepare("
            SELECT 
                o.name as outlet_name,
                COUNT(DISTINCT v.id) as visits,
                SUM(CASE WHEN LOWER(vcr.response) = 'ok' THEN 1 ELSE 0 END) as ok_count,
                SUM(CASE WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok' THEN 1 ELSE 0 END) as nok_count
            FROM outlets o
            INNER JOIN visits v ON o.id = v.outlet_id
            LEFT JOIN visit_checklist_responses vcr ON v.id = vcr.visit_id
            $whereClause
            GROUP BY o.id, o.name
            ORDER BY o.name
        ");
        $stmt->execute($params);
        $outlets = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $response['data']['outlets'] = array_map(function($outlet) {
            $ok = intval($outlet['ok_count']);
            $nok = intval($outlet['nok_count']);
            $total = $ok + $nok;
            $percent = $total > 0 ? round(($ok / $total) * 100, 1) : 0;
            
            return [
                'outlet_name' => $outlet['outlet_name'],
                'visits' => intval($outlet['visits']),
                'ok_count' => $ok,
                'nok_count' => $nok,
                'ok_percentage' => $percent,
                'status' => $percent >= 85 ? 'Good' : ($percent >= 70 ? 'Warning' : 'Critical')
            ];
        }, $outlets);
        
    } elseif ($reportType === 'outlet' || $reportType === 'outlet_detail') {
        // Get outlet-specific report
        if ($outletId <= 0) {
            throw new Exception("Outlet ID is required for outlet report");
        }
        
        // Add outlet_id to where clause and params
        $whereConditions[] = "v.outlet_id = ?";
        $params[] = $outletId;
        $whereClause = "WHERE " . implode(' AND ', $whereConditions);

        // Get outlet info
        $stmt = $conn->prepare("SELECT * FROM outlets WHERE id = ?");
        $stmt->execute([$outletId]);
        $outletInfo = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$outletInfo) {
            throw new Exception("Outlet not found");
        }
        
        $response['data']['outlet'] = [
            'id' => intval($outletInfo['id']),
            'name' => $outletInfo['name'],
            'address' => $outletInfo['address'],
            'region' => $outletInfo['region']
        ];
        
        // Get visit history for this outlet
        $stmt = $conn->prepare("
            SELECT 
                v.id,
                v.visit_date,
                v.status,
                COUNT(vcr.id) as total_items,
                SUM(CASE WHEN LOWER(vcr.response) = 'ok' THEN 1 ELSE 0 END) as ok_count,
                SUM(CASE WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok' THEN 1 ELSE 0 END) as nok_count
            FROM visits v
            LEFT JOIN visit_checklist_responses vcr ON v.id = vcr.visit_id
            $whereClause
            GROUP BY v.id, v.visit_date, v.status
            ORDER BY v.visit_date DESC
        ");
        
        $stmt->execute($params);
        $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $response['data']['visits'] = array_map(function($visit) {
            $ok = intval($visit['ok_count']);
            $nok = intval($visit['nok_count']);
            $total = $ok + $nok;
            $percent = $total > 0 ? round(($ok / $total) * 100, 1) : 0;
            
            return [
                'visit_id' => intval($visit['id']),
                'visit_date' => $visit['visit_date'],
                'status' => $visit['status'],
                'total_items' => $total,
                'ok_count' => $ok,
                'nok_count' => $nok,
                'ok_percentage' => $percent
            ];
        }, $visits);
        
        // Get NOK findings summary
        $stmt = $conn->prepare("
            SELECT 
                cp.question as checklist_point,
                cc.name as category_name,
                COUNT(*) as nok_frequency
            FROM visit_checklist_responses vcr
            JOIN visits v ON vcr.visit_id = v.id
            JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
            JOIN checklist_categories cc ON cp.category_id = cc.id
            $whereClause AND (LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok')
            GROUP BY cp.question, cc.name
            ORDER BY nok_frequency DESC
            LIMIT 10
        ");
        $stmt->execute($params);
        $nokIssues = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $response['data']['top_nok_issues'] = array_map(function($issue) {
            return [
                'point' => $issue['checklist_point'],
                'category' => $issue['category_name'],
                'frequency' => intval($issue['nok_frequency'])
            ];
        }, $nokIssues);

        if ($reportType === 'outlet_detail') {
            // Get detailed checklist point breakdown
            $stmt = $conn->prepare("
                SELECT 
                    cc.name as category_name,
                    cp.question as point_question,
                    SUM(CASE WHEN LOWER(vcr.response) = 'ok' THEN 1 ELSE 0 END) as ok_count,
                    SUM(CASE WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok' THEN 1 ELSE 0 END) as nok_count
                FROM checklist_points cp
                LEFT JOIN checklist_categories cc ON cp.category_id = cc.id
                LEFT JOIN visit_checklist_responses vcr ON cp.id = vcr.checklist_point_id
                LEFT JOIN visits v ON vcr.visit_id = v.id AND v.outlet_id = ?
                $whereClause
                GROUP BY cc.name, cp.question
                ORDER BY cc.sort_order, cp.sort_order
            ");
            $detailedParams = $params;
            array_unshift($detailedParams, $outletId);
            $stmt->execute($detailedParams);
            $detailedPoints = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $response['data']['detailed_points'] = $detailedPoints;
        }
    }
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    error_log("Database error in export-report-pdf.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred',
        'error' => $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("Error in export-report-pdf.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
