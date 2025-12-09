<?php
/**
 * Report by Outlet API
 * Get report statistics grouped by outlet
 * 
 * Endpoints:
 * GET /api/report-by-outlet.php?user_id={id}&start_date={date}&end_date={date}&outlet_id={id}
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

require_once __DIR__ . '/../classes/Database.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Response.php';

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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Get current user from auth
$currentUser = Auth::user();
if (!$currentUser) {
    Response::unauthorized('Authentication required');
}

// Get parameters
$startDate = isset($_GET['start_date']) ? $_GET['start_date'] : null;
$endDate = isset($_GET['end_date']) ? $_GET['end_date'] : null;
$outletId = isset($_GET['outlet_id']) ? intval($_GET['outlet_id']) : null;

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Build base query
    $baseQuery = "FROM outlets o
                  INNER JOIN visits v ON o.id = v.outlet_id
                  LEFT JOIN visit_checklist_responses vcr ON v.id = vcr.visit_id";

    // Build WHERE clause
    $whereConditions = ["v.status = 'completed'"];
    $params = [];

    // Role-based filtering - DISABLED to show all data
    // if ($currentUser['role'] !== 'super_admin') {
    //     $whereConditions[] = "v.user_id = ?";
    //     $params[] = $currentUser['id'];
    // }

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
    
    if ($outletId > 0) {
        $whereConditions[] = "o.id = ?";
        $params[] = $outletId;
    }

    $whereClause = "WHERE " . implode(' AND ', $whereConditions);
    
    // Get outlet reports with statistics
    $stmt = $conn->prepare("
        SELECT 
            o.id as outlet_id,
            o.name as outlet_name,
            o.address,
            o.region as city,
            COUNT(DISTINCT v.id) as total_visits,
            MAX(v.visit_date) as last_visit_date,
            COUNT(vcr.id) as total_items,
            SUM(CASE 
                WHEN LOWER(vcr.response) = 'ok' OR vcr.response = 'OK' 
                THEN 1 ELSE 0 
            END) as ok_count,
            SUM(CASE 
                WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
                     OR LOWER(vcr.response) = 'not ok'
                     OR vcr.response = 'NOT OK'
                THEN 1 ELSE 0 
            END) as nok_count,
            SUM(CASE 
                WHEN LOWER(vcr.response) = 'na' OR vcr.response = 'NA' OR vcr.response = 'N/A'
                THEN 1 ELSE 0 
            END) as na_count
        $baseQuery
        $whereClause
        GROUP BY o.id, o.name, o.address, o.region
        ORDER BY o.name ASC
    ");
    
    $stmt->execute($params);
    $outletsRaw = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Process outlets with status calculation
    $outlets = [];
    foreach ($outletsRaw as $outlet) {
        $okCount = intval($outlet['ok_count']);
        $nokCount = intval($outlet['nok_count']);
        $naCount = intval($outlet['na_count']);
        $totalItems = $okCount + $nokCount;
        
        // Calculate percentage (exclude NA)
        $okPercentage = $totalItems > 0 ? round(($okCount / $totalItems) * 100, 1) : 0;
        $nokPercentage = $totalItems > 0 ? round(($nokCount / $totalItems) * 100, 1) : 0;
        
        // Determine status based on OK percentage
        if ($okPercentage >= 85) {
            $status = 'Good';
            $statusColor = '#4CAF50'; // Green
        } elseif ($okPercentage >= 70) {
            $status = 'Warning';
            $statusColor = '#FF9800'; // Orange
        } else {
            $status = 'Critical';
            $statusColor = '#F44336'; // Red
        }
        
        // Get most recent NOK findings for this outlet
        $nokWhereConditions = ["v.outlet_id = ?", "v.status = 'completed'", "(LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' OR LOWER(vcr.response) = 'not ok' OR vcr.response = 'NOT OK')"];
        $nokParams = [$outlet['outlet_id']];

        // Role-based filtering - DISABLED to show all data
        // if ($currentUser['role'] !== 'super_admin') {
        //     $nokWhereConditions[] = "v.user_id = ?";
        //     $nokParams[] = $currentUser['id'];
        // }

        if ($startDate && $endDate) {
            $nokWhereConditions[] = "DATE(v.visit_date) BETWEEN ? AND ?";
            $nokParams[] = $startDate;
            $nokParams[] = $endDate;
        } elseif ($startDate) {
            $nokWhereConditions[] = "DATE(v.visit_date) >= ?";
            $nokParams[] = $startDate;
        } elseif ($endDate) {
            $nokWhereConditions[] = "DATE(v.visit_date) <= ?";
            $nokParams[] = $endDate;
        }

        $nokWhereClause = "WHERE " . implode(' AND ', $nokWhereConditions);

        $stmtNok = $conn->prepare("
            SELECT 
                cp.question as checklist_point,
                cc.name as category_name,
                COUNT(*) as nok_frequency
            FROM visit_checklist_responses vcr
            JOIN visits v ON vcr.visit_id = v.id
            JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
            JOIN checklist_categories cc ON cp.category_id = cc.id
            $nokWhereClause
            GROUP BY cp.question, cc.name
            ORDER BY nok_frequency DESC
            LIMIT 3
        ");
        
        $stmtNok->execute($nokParams);
        $topNokIssues = $stmtNok->fetchAll(PDO::FETCH_ASSOC);
        
        $outlets[] = [
            'outlet_id' => intval($outlet['outlet_id']),
            'outlet_name' => $outlet['outlet_name'],
            'address' => $outlet['address'],
            'city' => $outlet['city'],
            'total_visits' => intval($outlet['total_visits']),
            'last_visit_date' => $outlet['last_visit_date'],
            'total_items' => $totalItems,
            'ok_count' => $okCount,
            'nok_count' => $nokCount,
            'na_count' => $naCount,
            'ok_percentage' => $okPercentage,
            'nok_percentage' => $nokPercentage,
            'status' => $status,
            'status_color' => $statusColor,
            'top_nok_issues' => array_map(function($issue) {
                return [
                    'point' => $issue['checklist_point'],
                    'category' => $issue['category_name'],
                    'frequency' => intval($issue['nok_frequency'])
                ];
            }, $topNokIssues)
        ];
    }
    
    // Build response
    $response = [
        'success' => true,
        'data' => $outlets,
        'filters' => [
            'start_date' => $startDate,
            'end_date' => $endDate,
            'outlet_id' => $outletId
        ],
        'summary' => [
            'total_outlets' => count($outlets),
            'good_outlets' => count(array_filter($outlets, fn($o) => $o['status'] === 'Good')),
            'warning_outlets' => count(array_filter($outlets, fn($o) => $o['status'] === 'Warning')),
            'critical_outlets' => count(array_filter($outlets, fn($o) => $o['status'] === 'Critical'))
        ]
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    error_log("Database error in report-by-outlet.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred',
        'error' => $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("Error in report-by-outlet.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred',
        'error' => $e->getMessage()
    ]);
}
