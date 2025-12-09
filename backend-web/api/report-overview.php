<?php
/**
 * Report Overview API
 * Get overall statistics for reports dashboard
 * 
 * Endpoints:
 * GET /api/report-overview.php?user_id={id}&start_date={date}&end_date={date}
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

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
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
    
    // 1. Get Total Visits
    $stmt = $conn->prepare("
        SELECT COUNT(DISTINCT v.id) as total_visits
        FROM visits v
        $whereClause
    ");
    $stmt->execute($params);
    $totalVisits = $stmt->fetch(PDO::FETCH_ASSOC)['total_visits'];
    
    // 2. Get Total Outlets Visited
    $stmt = $conn->prepare("
        SELECT COUNT(DISTINCT v.outlet_id) as total_outlets
        FROM visits v
        $whereClause
    ");
    $stmt->execute($params);
    $totalOutlets = $stmt->fetch(PDO::FETCH_ASSOC)['total_outlets'];
    
    // 3. Get OK, NOK, NA counts from checklist responses
    $stmt = $conn->prepare("
        SELECT 
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
            END) as na_count,
            COUNT(*) as total_responses
        FROM visit_checklist_responses vcr
        JOIN visits v ON vcr.visit_id = v.id
        $whereClause
    ");
    $stmt->execute($params);
    $responseCounts = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $okCount = intval($responseCounts['ok_count']);
    $nokCount = intval($responseCounts['nok_count']);
    $naCount = intval($responseCounts['na_count']);
    $totalResponses = intval($responseCounts['total_responses']);
    
    // Calculate percentages (exclude NA from calculation)
    $totalWithoutNA = $okCount + $nokCount;
    $okPercentage = $totalWithoutNA > 0 ? round(($okCount / $totalWithoutNA) * 100, 1) : 0;
    $nokPercentage = $totalWithoutNA > 0 ? round(($nokCount / $totalWithoutNA) * 100, 1) : 0;
    
    // 4. Get Recent Visits (last 10)
    $stmt = $conn->prepare("
        SELECT 
            v.id,
            v.outlet_id,
            o.name AS outlet_name,
            v.visit_date,
            v.status,
            COUNT(vcr.id) as total_items,
            SUM(CASE 
                WHEN LOWER(vcr.response) = 'ok' OR vcr.response = 'OK' 
                THEN 1 ELSE 0 
            END) as ok_items,
            SUM(CASE 
                WHEN LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
                     OR LOWER(vcr.response) = 'not ok'
                     OR vcr.response = 'NOT OK'
                THEN 1 ELSE 0 
            END) as nok_items
        FROM visits v
        LEFT JOIN outlets o ON v.outlet_id = o.id
        LEFT JOIN visit_checklist_responses vcr ON v.id = vcr.visit_id
        $whereClause
        GROUP BY v.id, v.outlet_id, o.name, v.visit_date, v.status
        ORDER BY v.visit_date DESC, v.created_at DESC
        LIMIT 10
    ");
    $stmt->execute($params);
    $recentVisitsRaw = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Process recent visits with status calculation
    $recentVisits = [];
    foreach ($recentVisitsRaw as $visit) {
        $okItems = intval($visit['ok_items']);
        $nokItems = intval($visit['nok_items']);
        $totalItems = $okItems + $nokItems;
        
        $okPercent = $totalItems > 0 ? round(($okItems / $totalItems) * 100, 1) : 0;
        
        // Determine status based on OK percentage
        if ($okPercent >= 85) {
            $status = 'Good';
            $statusColor = '#4CAF50'; // Green
        } elseif ($okPercent >= 70) {
            $status = 'Warning';
            $statusColor = '#FF9800'; // Orange
        } else {
            $status = 'Critical';
            $statusColor = '#F44336'; // Red
        }
        
        $recentVisits[] = [
            'visit_id' => intval($visit['id']),
            'outlet_id' => intval($visit['outlet_id']),
            'outlet_name' => $visit['outlet_name'],
            'visit_date' => $visit['visit_date'],
            'visit_status' => $visit['status'],
            'total_items' => $totalItems,
            'ok_items' => $okItems,
            'nok_items' => $nokItems,
            'ok_percentage' => $okPercent,
            'status' => $status,
            'status_color' => $statusColor
        ];
    }
    
    // 5. Get Division Info
    $divisionInfo = [
        'id' => $currentUser['division_id'] ?? null,
        'name' => $currentUser['division_name'] ?? null,
    ];
    
    // Build response
    $response = [
        'success' => true,
        'data' => [
            'total_visits' => intval($totalVisits),
            'total_outlets' => intval($totalOutlets),
            'ok_count' => $okCount,
            'nok_count' => $nokCount,
            'na_count' => $naCount,
            'total_responses' => $totalResponses,
            'ok_percentage' => $okPercentage,
            'nok_percentage' => $nokPercentage,
            'recent_visits' => $recentVisits,
            'division_id' => $divisionInfo['id'],
            'division_name' => $divisionInfo['name'],
            'filters' => [
                'start_date' => $startDate,
                'end_date' => $endDate
            ]
        ]
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    error_log("Database error in report-overview.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred',
        'error' => $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("Error in report-overview.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred',
        'error' => $e->getMessage()
    ]);
}
