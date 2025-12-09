<?php
/**
 * Visit Statistics API for Dashboard
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
    
    // Get visit statistics
    $stats = [];
    
    // Total visits
    $sql = "SELECT COUNT(*) as total FROM visits";
    $stmt = $db->query($sql);
    $stats['total_visits'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Visits by status
    $sql = "SELECT status, COUNT(*) as count FROM visits GROUP BY status";
    $stmt = $db->query($sql);
    $stats['visits_by_status'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Recent visits (last 5)
    $sql = "SELECT 
                v.id,
                v.visit_date,
                v.status,
                o.name as outlet_name,
                u.full_name as auditor_name,
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id AND vcr.response = 'ok'
                ) as ok_count,
                (
                    SELECT COUNT(*) 
                    FROM visit_checklist_responses vcr 
                    WHERE vcr.visit_id = v.id
                ) as total_responses
            FROM visits v
            INNER JOIN outlets o ON v.outlet_id = o.id
            INNER JOIN users u ON v.user_id = u.id
            ORDER BY v.visit_date DESC
            LIMIT 5";
    $stmt = $db->query($sql);
    $recentVisits = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Calculate score for recent visits
    foreach ($recentVisits as &$visit) {
        if ($visit['total_responses'] > 0) {
            $visit['score'] = round(($visit['ok_count'] / $visit['total_responses']) * 100, 2);
        } else {
            $visit['score'] = 0;
        }
    }
    $stats['recent_visits'] = $recentVisits;
    
    // Daily visit trends per division (last 7 days)
    $sql = "SELECT 
                COALESCE(d.name, 'No Division') as division_name,
                DATE(v.visit_date) as visit_day,
                DATE_FORMAT(v.visit_date, '%a, %d %b') as day_label,
                COUNT(v.id) as visit_count
            FROM visits v
            INNER JOIN users u ON v.user_id = u.id
            LEFT JOIN divisions d ON u.division_id = d.id
            WHERE v.visit_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
            GROUP BY division_name, visit_day, day_label
            ORDER BY visit_day, division_name";
    $stmt = $db->query($sql);
    $dailyData = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Generate last 7 days
    $days = [];
    for ($i = 6; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        $label = date('D, d M', strtotime("-$i days"));
        $days[] = [
            'date' => $date,
            'label' => $label
        ];
    }
    
    // Get unique divisions
    $divisions = [];
    $chartData = [];
    
    foreach ($dailyData as $row) {
        $divisionName = $row['division_name'] ?? 'No Division';
        
        if (!in_array($divisionName, $divisions)) {
            $divisions[] = $divisionName;
            $chartData[$divisionName] = [];
            
            // Initialize all days with 0
            foreach ($days as $day) {
                $chartData[$divisionName][$day['date']] = 0;
            }
        }
        
        $chartData[$divisionName][$row['visit_day']] = (int)$row['visit_count'];
    }
    
    // Prepare final data structure
    $dayLabels = array_column($days, 'label');
    $dayDates = array_column($days, 'date');
    
    $stats['daily_trends'] = [
        'divisions' => $divisions,
        'days' => $dayLabels,
        'dates' => $dayDates,
        'data' => $chartData
    ];
    
    Response::success($stats);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
