<?php
/**
 * Training Statistics Dashboard - SIMPLIFIED VERSION
 * 
 * Get comprehensive training statistics and trends
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';
require_once '../../utils/Auth.php';

// Authentication disabled for demo
$auth = [
    'authenticated' => true,
    'user_id' => Auth::id() ?? 1,
    'role' => $_SESSION['user_role'] ?? 'admin'
];

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Check if training_sessions table exists
    $check_table = $db->query("SHOW TABLES LIKE 'training_sessions'");
    if ($check_table->rowCount() === 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Training module not initialized yet',
            'data' => [
                'period' => ['from' => date('Y-m-d', strtotime('-30 days')), 'to' => date('Y-m-d'), 'days' => 31],
                'summary' => [
                    'total_sessions' => 0,
                    'completed_sessions' => 0,
                    'in_progress_sessions' => 0,
                    'pending_sessions' => 0,
                    'total_participants' => 0,
                    'total_trainers' => 0,
                    'overall_average_score' => 0,
                    'total_photos' => 0,
                    'completion_rate' => 0
                ],
                'sessions_by_status' => (object)[],
                'daily_trend' => [],
                'top_trainers' => [],
                'top_outlets' => [],
                'top_checklists' => [],
                'score_distribution' => [],
                'recent_sessions' => []
            ]
        ]);
        exit();
    }
    
    // Get filter parameters
    $outlet_id = $_GET['outlet_id'] ?? null;
    $trainer_id = $_GET['trainer_id'] ?? null;
    $date_from = $_GET['date_from'] ?? date('Y-m-d', strtotime('-30 days'));
    $date_to = $_GET['date_to'] ?? date('Y-m-d');
    
    $where_clauses = ["ts.session_date BETWEEN ? AND ?"];
    $params = [$date_from, $date_to];
    
    if ($outlet_id) {
        $where_clauses[] = "ts.outlet_id = ?";
        $params[] = $outlet_id;
    }
    
    if ($trainer_id) {
        $where_clauses[] = "ts.trainer_id = ?";
        $params[] = $trainer_id;
    } else if ($auth['role'] === 'trainer') {
        $where_clauses[] = "ts.trainer_id = ?";
        $params[] = $auth['user_id'];
    }
    
    $where_sql = "WHERE " . implode(" AND ", $where_clauses);
    
    // === OVERALL SUMMARY ===
    $summary_sql = "
        SELECT 
            COUNT(DISTINCT ts.id) as total_sessions,
            COUNT(DISTINCT CASE WHEN ts.status = 'completed' THEN ts.id END) as completed_sessions,
            COUNT(DISTINCT CASE WHEN ts.status = 'in_progress' THEN ts.id END) as in_progress_sessions,
            COUNT(DISTINCT CASE WHEN ts.status = 'pending' THEN ts.id END) as pending_sessions,
            COUNT(DISTINCT tp.id) as total_participants,
            COUNT(DISTINCT ts.trainer_id) as total_trainers,
            0 as overall_average_score,
            COUNT(DISTINCT tph.id) as total_photos
        FROM training_sessions ts
        LEFT JOIN training_participants tp ON ts.id = tp.session_id
        LEFT JOIN training_photos tph ON ts.id = tph.session_id
        $where_sql
    ";
    
    $summary_stmt = $db->prepare($summary_sql);
    $summary_stmt->execute($params);
    $summary = $summary_stmt->fetch(PDO::FETCH_ASSOC);
    
    // === SESSIONS BY STATUS ===
    $status_sql = "
        SELECT 
            status,
            COUNT(*) as count
        FROM training_sessions ts
        $where_sql
        GROUP BY status
    ";
    
    $status_stmt = $db->prepare($status_sql);
    $status_stmt->execute($params);
    $sessions_by_status = [];
    
    while ($row = $status_stmt->fetch(PDO::FETCH_ASSOC)) {
        $sessions_by_status[$row['status']] = (int)$row['count'];
    }
    
    // === DAILY TREND ===
    $trend_sql = "
        SELECT 
            DATE(ts.session_date) as date,
            COUNT(*) as sessions_count,
            COUNT(DISTINCT tp.id) as participants_count
        FROM training_sessions ts
        LEFT JOIN training_participants tp ON ts.id = tp.session_id
        $where_sql
        GROUP BY DATE(ts.session_date)
        ORDER BY date ASC
    ";
    
    $trend_stmt = $db->prepare($trend_sql);
    $trend_stmt->execute($params);
    $daily_trend = [];
    
    while ($row = $trend_stmt->fetch(PDO::FETCH_ASSOC)) {
        $daily_trend[] = [
            'date' => $row['date'],
            'sessions_count' => (int)$row['sessions_count'],
            'participants_count' => (int)$row['participants_count']
        ];
    }
    
    // === TOP TRAINERS ===
    $trainers_sql = "
        SELECT 
            u.id,
            u.full_name,
            COUNT(DISTINCT ts.id) as sessions_count,
            COUNT(DISTINCT CASE WHEN ts.status = 'completed' THEN ts.id END) as completed_count,
            COUNT(DISTINCT tp.id) as total_participants
        FROM users u
        LEFT JOIN training_sessions ts ON u.id = ts.trainer_id
        LEFT JOIN training_participants tp ON ts.id = tp.session_id
        WHERE 1=1
    ";
    
    if ($trainer_id) {
        $trainers_sql .= " AND u.id = ?";
    }
    
    $trainers_sql .= " GROUP BY u.id ORDER BY completed_count DESC, sessions_count DESC LIMIT 10";
    
    $trainers_stmt = $db->prepare($trainers_sql);
    if ($trainer_id) {
        $trainers_stmt->execute([$trainer_id]);
    } else {
        $trainers_stmt->execute();
    }
    
    $top_trainers = [];
    while ($row = $trainers_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_trainers[] = [
            'id' => (int)$row['id'],
            'name' => $row['full_name'],
            'sessions_count' => (int)$row['sessions_count'],
            'completed_count' => (int)$row['completed_count'],
            'total_participants' => (int)$row['total_participants']
        ];
    }
    
    // === TOP OUTLETS ===
    $outlets_sql = "
        SELECT 
            o.id,
            o.name as outlet_name,
            COUNT(DISTINCT ts.id) as sessions_count,
            COUNT(DISTINCT tp.id) as total_participants
        FROM outlets o
        LEFT JOIN training_sessions ts ON o.id = ts.outlet_id
        LEFT JOIN training_participants tp ON ts.id = tp.session_id
        GROUP BY o.id
        ORDER BY sessions_count DESC
        LIMIT 10
    ";
    
    $outlets_stmt = $db->prepare($outlets_sql);
    $outlets_stmt->execute();
    $top_outlets = [];
    
    while ($row = $outlets_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_outlets[] = [
            'id' => (int)$row['id'],
            'name' => $row['outlet_name'],
            'sessions_count' => (int)$row['sessions_count'],
            'total_participants' => (int)$row['total_participants']
        ];
    }
    
    // === TOP CHECKLISTS ===
    $checklists_sql = "
        SELECT 
            tc.id,
            tc.name as checklist_name,
            COUNT(DISTINCT ts.id) as usage_count
        FROM training_checklists tc
        LEFT JOIN training_sessions ts ON tc.id = ts.checklist_id
        GROUP BY tc.id
        ORDER BY usage_count DESC
        LIMIT 10
    ";
    
    $checklists_stmt = $db->prepare($checklists_sql);
    $checklists_stmt->execute();
    $top_checklists = [];
    
    while ($row = $checklists_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_checklists[] = [
            'id' => (int)$row['id'],
            'name' => $row['checklist_name'],
            'usage_count' => (int)$row['usage_count']
        ];
    }
    
    // === RECENT SESSIONS ===
    $recent_sql = "
        SELECT 
            ts.id,
            ts.session_date,
            tc.name as checklist_name,
            o.name as outlet_name,
            u.full_name as trainer_name,
            COUNT(DISTINCT tp.id) as participants_count
        FROM training_sessions ts
        LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id
        LEFT JOIN outlets o ON ts.outlet_id = o.id
        LEFT JOIN users u ON ts.trainer_id = u.id
        LEFT JOIN training_participants tp ON ts.id = tp.session_id
        $where_sql
        GROUP BY ts.id
        ORDER BY ts.session_date DESC
        LIMIT 5
    ";
    
    $recent_stmt = $db->prepare($recent_sql);
    $recent_stmt->execute($params);
    $recent_sessions = [];
    
    while ($row = $recent_stmt->fetch(PDO::FETCH_ASSOC)) {
        $recent_sessions[] = [
            'id' => (int)$row['id'],
            'session_date' => $row['session_date'],
            'checklist_name' => $row['checklist_name'],
            'outlet_name' => $row['outlet_name'],
            'trainer_name' => $row['trainer_name'],
            'participants_count' => (int)$row['participants_count']
        ];
    }
    
    // Calculate completion rate
    $completion_rate = 0;
    if ($summary['total_sessions'] > 0) {
        $completion_rate = round(($summary['completed_sessions'] / $summary['total_sessions']) * 100, 2);
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Statistics retrieved successfully',
        'data' => [
            'period' => [
                'from' => $date_from,
                'to' => $date_to,
                'days' => intval((strtotime($date_to) - strtotime($date_from)) / (60 * 60 * 24)) + 1
            ],
            'summary' => [
                'total_sessions' => (int)$summary['total_sessions'],
                'completed_sessions' => (int)$summary['completed_sessions'],
                'in_progress_sessions' => (int)$summary['in_progress_sessions'],
                'pending_sessions' => (int)$summary['pending_sessions'],
                'total_participants' => (int)$summary['total_participants'],
                'total_trainers' => (int)$summary['total_trainers'],
                'overall_average_score' => 0,
                'total_photos' => (int)$summary['total_photos'],
                'completion_rate' => $completion_rate
            ],
            'sessions_by_status' => (object)$sessions_by_status,
            'daily_trend' => $daily_trend,
            'top_trainers' => $top_trainers,
            'top_outlets' => $top_outlets,
            'top_checklists' => $top_checklists,
            'score_distribution' => [],
            'recent_sessions' => $recent_sessions
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'error_details' => [
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ], JSON_PRETTY_PRINT);
}
?>
