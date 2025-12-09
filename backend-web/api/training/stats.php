<?php
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
try {
    $db = Database::getInstance()->getConnection();
    $check_table = $db->query("SHOW TABLES LIKE 'training_sessions'");
    if ($check_table->rowCount() === 0) {
        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Training module not initialized', 'data' => ['period' => ['from' => date('Y-m-d', strtotime('-30 days')), 'to' => date('Y-m-d'), 'days' => 31], 'summary' => ['total_sessions' => 0, 'completed_sessions' => 0, 'in_progress_sessions' => 0, 'pending_sessions' => 0, 'total_participants' => 0, 'total_trainers' => 0, 'overall_average_score' => 0, 'total_photos' => 0, 'completion_rate' => 0], 'sessions_by_status' => new stdClass(), 'daily_trend' => [], 'top_trainers' => [], 'top_outlets' => [], 'top_checklists' => [], 'score_distribution' => [], 'recent_sessions' => []]]);
        exit();
    }
    $date_from = $_GET['date_from'] ?? date('Y-m-d', strtotime('-30 days'));
    $date_to = $_GET['date_to'] ?? date('Y-m-d');
    $outlet_id = $_GET['outlet_id'] ?? null;
    $trainer_id = $_GET['trainer_id'] ?? null;
    $division_id = $_GET['division_id'] ?? null;
    $where_clauses = ["ts.session_date BETWEEN ? AND ?"];
    $params = [$date_from, $date_to];
    if ($outlet_id) {
        $where_clauses[] = "ts.outlet_id = ?";
        $params[] = $outlet_id;
    }
    if ($trainer_id) {
        $where_clauses[] = "ts.trainer_id = ?";
        $params[] = $trainer_id;
    }
    if ($division_id) {
        $where_clauses[] = "o.division_id = ?";
        $params[] = $division_id;
    }
    $where_sql = "WHERE " . implode(" AND ", $where_clauses);
    
    // DEBUG: Log query parameters
    error_log("TRAINING STATS - Date range: $date_from to $date_to");
    error_log("TRAINING STATS - Division ID: " . ($division_id ?? 'NULL'));
    error_log("TRAINING STATS - WHERE clause: $where_sql");
    
    // Simple query without complex subqueries
    // Note: 'pending' status includes both 'pending' and 'scheduled' status
    $summary_sql = "SELECT 
        COUNT(DISTINCT ts.id) as total_sessions, 
        COUNT(DISTINCT CASE WHEN ts.status = 'completed' THEN ts.id END) as completed_sessions, 
        COUNT(DISTINCT CASE WHEN ts.status = 'in_progress' THEN ts.id END) as in_progress_sessions, 
        COUNT(DISTINCT CASE WHEN ts.status = 'ongoing' THEN ts.id END) as ongoing_sessions,
        COUNT(DISTINCT CASE WHEN ts.status IN ('pending', 'scheduled') THEN ts.id END) as pending_sessions, 
        COUNT(DISTINCT CASE WHEN ts.status = 'scheduled' THEN ts.id END) as scheduled_sessions,
        COUNT(DISTINCT tp.id) as total_participants, 
        COUNT(DISTINCT ts.trainer_id) as total_trainers
        FROM training_sessions ts 
        LEFT JOIN outlets o ON ts.outlet_id = o.id 
        LEFT JOIN training_participants tp ON ts.id = tp.session_id 
        $where_sql";
    $summary_stmt = $db->prepare($summary_sql);
    $summary_stmt->execute($params);
    $summary = $summary_stmt->fetch(PDO::FETCH_ASSOC);
    
    // DEBUG: Log the summary results
    error_log("TRAINING STATS DEBUG - Total sessions: " . $summary['total_sessions']);
    error_log("TRAINING STATS DEBUG - Completed: " . $summary['completed_sessions']);
    error_log("TRAINING STATS DEBUG - Pending: " . $summary['pending_sessions']);
    error_log("TRAINING STATS DEBUG - Scheduled: " . $summary['scheduled_sessions']);
    
    // Get total photos separately
    $photos_count_sql = "SELECT COUNT(*) as total_photos FROM training_photos tph 
                         INNER JOIN training_sessions ts ON tph.session_id = ts.id 
                         LEFT JOIN outlets o ON ts.outlet_id = o.id 
                         $where_sql";
    $photos_count_stmt = $db->prepare($photos_count_sql);
    $photos_count_stmt->execute($params);
    $photos_result = $photos_count_stmt->fetch(PDO::FETCH_ASSOC);
    $summary['total_photos'] = (int)$photos_result['total_photos'];
    
    // Get average score separately from training_scores
    $avg_score_sql = "SELECT AVG(tsc.score) as average_score 
                      FROM training_scores tsc
                      INNER JOIN training_evaluations tev ON tsc.evaluation_id = tev.id
                      WHERE tev.evaluation_date BETWEEN ? AND ?";
    $avg_score_stmt = $db->prepare($avg_score_sql);
    $avg_score_stmt->execute([$date_from, $date_to]);
    $avg_result = $avg_score_stmt->fetch(PDO::FETCH_ASSOC);
    $summary['average_score'] = $avg_result['average_score'];
    
    // Combine in_progress and ongoing counts (they might use different status names)
    $summary['in_progress_sessions'] = (int)$summary['in_progress_sessions'] + (int)$summary['ongoing_sessions'];
    
    $status_sql = "SELECT ts.status, COUNT(*) as count FROM training_sessions ts LEFT JOIN outlets o ON ts.outlet_id = o.id $where_sql GROUP BY ts.status";
    $status_stmt = $db->prepare($status_sql);
    $status_stmt->execute($params);
    $sessions_by_status = [];
    while ($row = $status_stmt->fetch(PDO::FETCH_ASSOC)) {
        $sessions_by_status[$row['status']] = (int)$row['count'];
    }
    $trend_sql = "SELECT DATE(ts.session_date) as date, COUNT(*) as sessions_count, COUNT(DISTINCT tp.id) as participants_count FROM training_sessions ts LEFT JOIN outlets o ON ts.outlet_id = o.id LEFT JOIN training_participants tp ON ts.id = tp.session_id $where_sql GROUP BY DATE(ts.session_date) ORDER BY date ASC";
    $trend_stmt = $db->prepare($trend_sql);
    $trend_stmt->execute($params);
    $daily_trend = [];
    while ($row = $trend_stmt->fetch(PDO::FETCH_ASSOC)) {
        $daily_trend[] = ['date' => $row['date'], 'sessions_count' => (int)$row['sessions_count'], 'participants_count' => (int)$row['participants_count']];
    }
    $trainers_sql = "SELECT u.id, u.full_name, COUNT(DISTINCT ts.id) as sessions_count, COUNT(DISTINCT CASE WHEN ts.status = 'completed' THEN ts.id END) as completed_count, COUNT(DISTINCT tp.id) as total_participants FROM users u LEFT JOIN training_sessions ts ON u.id = ts.trainer_id LEFT JOIN outlets o ON ts.outlet_id = o.id LEFT JOIN training_participants tp ON ts.id = tp.session_id $where_sql GROUP BY u.id, u.full_name ORDER BY completed_count DESC LIMIT 10";
    $trainers_stmt = $db->prepare($trainers_sql);
    $trainers_stmt->execute($params);
    $top_trainers = [];
    while ($row = $trainers_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_trainers[] = ['id' => (int)$row['id'], 'name' => $row['full_name'], 'sessions_count' => (int)$row['sessions_count'], 'completed_count' => (int)$row['completed_count'], 'total_participants' => (int)$row['total_participants']];
    }
    $outlets_sql = "SELECT o.id, o.name as outlet_name, COUNT(DISTINCT ts.id) as sessions_count, COUNT(DISTINCT tp.id) as total_participants FROM outlets o LEFT JOIN training_sessions ts ON o.id = ts.outlet_id LEFT JOIN training_participants tp ON ts.id = tp.session_id $where_sql GROUP BY o.id, o.name ORDER BY sessions_count DESC LIMIT 10";
    $outlets_stmt = $db->prepare($outlets_sql);
    $outlets_stmt->execute($params);
    $top_outlets = [];
    while ($row = $outlets_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_outlets[] = ['id' => (int)$row['id'], 'name' => $row['outlet_name'], 'sessions_count' => (int)$row['sessions_count'], 'total_participants' => (int)$row['total_participants']];
    }
    $checklists_sql = "SELECT tc.id, tc.name as checklist_name, COUNT(DISTINCT ts.id) as usage_count FROM training_checklists tc LEFT JOIN training_sessions ts ON tc.id = ts.checklist_id LEFT JOIN outlets o ON ts.outlet_id = o.id $where_sql GROUP BY tc.id, tc.name ORDER BY usage_count DESC LIMIT 10";
    $checklists_stmt = $db->prepare($checklists_sql);
    $checklists_stmt->execute($params);
    $top_checklists = [];
    while ($row = $checklists_stmt->fetch(PDO::FETCH_ASSOC)) {
        $top_checklists[] = ['id' => (int)$row['id'], 'name' => $row['checklist_name'], 'usage_count' => (int)$row['usage_count']];
    }
    $recent_sql = "SELECT ts.id, ts.session_date, tc.name as checklist_name, o.name as outlet_name, u.full_name as trainer_name, COUNT(DISTINCT tp.id) as participants_count FROM training_sessions ts LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id LEFT JOIN outlets o ON ts.outlet_id = o.id LEFT JOIN users u ON ts.trainer_id = u.id LEFT JOIN training_participants tp ON ts.id = tp.session_id $where_sql GROUP BY ts.id ORDER BY ts.session_date DESC LIMIT 5";
    $recent_stmt = $db->prepare($recent_sql);
    $recent_stmt->execute($params);
    $recent_sessions = [];
    while ($row = $recent_stmt->fetch(PDO::FETCH_ASSOC)) {
        $recent_sessions[] = ['id' => (int)$row['id'], 'session_date' => $row['session_date'], 'checklist_name' => $row['checklist_name'], 'outlet_name' => $row['outlet_name'], 'trainer_name' => $row['trainer_name'], 'participants_count' => (int)$row['participants_count']];
    }
    $completion_rate = 0;
    if ($summary['total_sessions'] > 0) {
        $completion_rate = round(($summary['completed_sessions'] / $summary['total_sessions']) * 100, 2);
    }
    $overall_average_score = $summary['average_score'] ? round((float)$summary['average_score'], 1) : 0;
    
    // Get photos for the period
    $photos_where_clauses = ["ts.session_date BETWEEN ? AND ?"];
    $photos_params = [$date_from, $date_to];
    if ($outlet_id) {
        $photos_where_clauses[] = "ts.outlet_id = ?";
        $photos_params[] = $outlet_id;
    }
    if ($trainer_id) {
        $photos_where_clauses[] = "ts.trainer_id = ?";
        $photos_params[] = $trainer_id;
    }
    if ($division_id) {
        $photos_where_clauses[] = "o.division_id = ?";
        $photos_params[] = $division_id;
    }
    $photos_where_sql = "WHERE " . implode(" AND ", $photos_where_clauses);
    
    $photos_sql = "SELECT tph.id, tph.photo_url, tph.caption, tph.uploaded_at, ts.session_date, tc.name as checklist_name, o.name as outlet_name 
                   FROM training_photos tph 
                   INNER JOIN training_sessions ts ON tph.session_id = ts.id 
                   LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id 
                   LEFT JOIN outlets o ON ts.outlet_id = o.id 
                   $photos_where_sql
                   ORDER BY tph.uploaded_at DESC LIMIT 50";
    $photos_stmt = $db->prepare($photos_sql);
    $photos_stmt->execute($photos_params);
    $photos = [];
    while ($row = $photos_stmt->fetch(PDO::FETCH_ASSOC)) {
        $photos[] = ['id' => (int)$row['id'], 'photo_path' => $row['photo_url'], 'caption' => $row['caption'], 'uploaded_at' => $row['uploaded_at'], 'session_date' => $row['session_date'], 'checklist_name' => $row['checklist_name'], 'outlet_name' => $row['outlet_name']];
    }
    
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Statistics retrieved successfully', 'data' => ['period' => ['from' => $date_from, 'to' => $date_to, 'days' => intval((strtotime($date_to) - strtotime($date_from)) / (60 * 60 * 24)) + 1], 'summary' => ['total_sessions' => (int)$summary['total_sessions'], 'completed_sessions' => (int)$summary['completed_sessions'], 'in_progress_sessions' => (int)$summary['in_progress_sessions'], 'pending_sessions' => (int)$summary['pending_sessions'], 'total_participants' => (int)$summary['total_participants'], 'total_trainers' => (int)$summary['total_trainers'], 'overall_average_score' => $overall_average_score, 'total_photos' => (int)$summary['total_photos'], 'completion_rate' => $completion_rate], 'sessions_by_status' => (object)$sessions_by_status, 'daily_trend' => $daily_trend, 'top_trainers' => $top_trainers, 'top_outlets' => $top_outlets, 'top_checklists' => $top_checklists, 'score_distribution' => [], 'recent_sessions' => $recent_sessions, 'photos' => $photos]]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
