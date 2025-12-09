<?php
/**
 * Training Sessions - Get List
 * 
 * Get filtered list of training sessions with pagination
 * 
 * @endpoint GET /api/training/sessions-list.php
 * @auth Required
 * @params status, outlet_id, trainer_id, date_from, date_to, page, limit
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
require_once '../../classes/Database.php';
require_once '../../utils/Auth.php';

// Check authentication (DISABLED FOR DEMO - ENABLE IN PRODUCTION)
// if (!Auth::checkAuth()) {
//     http_response_code(401);
//     echo json_encode([
//         'success' => false,
//         'message' => 'Authentication required'
//     ]);
//     exit();
// }

// Get authenticated user info (default to demo user if not logged in)
$auth = [
    'authenticated' => true,
    'user_id' => Auth::id() ?? 1, // Default to user ID 1 if not logged in
    'role' => $_SESSION['user_role'] ?? 'admin'
];

// Only GET method allowed
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit();
}

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Check if training_sessions table exists
    $check_table = $conn->query("SHOW TABLES LIKE 'training_sessions'");
    if ($check_table->rowCount() === 0) {
        // Return empty list if table doesn't exist yet
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Training module not initialized yet. Please run database migration.',
            'data' => [],
            'pagination' => [
                'page' => 1,
                'limit' => 20,
                'total' => 0,
                'total_pages' => 0
            ]
        ]);
        exit();
    }
    
    // Get filter parameters
    $status = isset($_GET['status']) ? $_GET['status'] : null;
    $outlet_id = isset($_GET['outlet_id']) ? $_GET['outlet_id'] : null;
    $trainer_id = isset($_GET['trainer_id']) ? $_GET['trainer_id'] : null;
    $date_from = isset($_GET['date_from']) ? $_GET['date_from'] : null;
    $date_to = isset($_GET['date_to']) ? $_GET['date_to'] : null;
    $search = isset($_GET['search']) ? $_GET['search'] : null;
    
    // Pagination
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 20;
    $offset = ($page - 1) * $limit;
    
    // Build WHERE clause
    $where_clauses = [];
    $params = [];
    
    // Filter by status
    if ($status && in_array($status, ['pending', 'in_progress', 'completed', 'cancelled'])) {
        $where_clauses[] = "ts.status = ?";
        $params[] = $status;
    }
    
    // Filter by outlet
    if ($outlet_id) {
        $where_clauses[] = "ts.outlet_id = ?";
        $params[] = $outlet_id;
    }
    
    // Filter by trainer
    if ($trainer_id) {
        $where_clauses[] = "ts.trainer_id = ?";
        $params[] = $trainer_id;
    } else if ($auth['role'] === 'trainer') {
        // Trainers only see their own sessions
        $where_clauses[] = "ts.trainer_id = ?";
        $params[] = $auth['user_id'];
    }
    
    // Filter by date range
    if ($date_from) {
        $where_clauses[] = "ts.session_date >= ?";
        $params[] = $date_from;
    }
    
    if ($date_to) {
        $where_clauses[] = "ts.session_date <= ?";
        $params[] = $date_to;
    }
    
    // Search in checklist name or trainer name
    if ($search) {
        $where_clauses[] = "(tc.checklist_name LIKE ? OR u.full_name LIKE ?)";
        $search_param = "%$search%";
        $params[] = $search_param;
        $params[] = $search_param;
    }
    
    $where_sql = !empty($where_clauses) ? "WHERE " . implode(" AND ", $where_clauses) : "";
    
    // Get total count
    $count_sql = "
        SELECT COUNT(*) as total
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        JOIN users u ON ts.trainer_id = u.id
        $where_sql
    ";
    
    $count_stmt = $conn->prepare($count_sql);
    $count_stmt->execute($params);
    $total_records = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];
    $total_pages = ceil($total_records / $limit);
    
    // Get sessions with details
    $sql = "
        SELECT 
            ts.id,
            ts.session_date,
            ts.start_time,
            ts.status,
            ts.notes,
            ts.created_at,
            ts.updated_at,
            tc.id as checklist_id,
            tc.name as checklist_name,
            tc.description as checklist_description,
            o.name as outlet_name,
            o.address as outlet_address,
            u.id as trainer_id,
            u.full_name as trainer_name,
            ts.crew_name,
            (SELECT signer_name FROM training_signatures WHERE session_id = ts.id AND signature_type = 'leader' LIMIT 1) as crew_leader_name,
            (SELECT COUNT(*) FROM training_participants WHERE session_id = ts.id) as participant_count,
            (SELECT COUNT(*) FROM training_responses WHERE session_id = ts.id) as response_count,
            (SELECT COUNT(*) FROM training_photos WHERE session_id = ts.id) as photo_count
        FROM training_sessions ts
        LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id
        LEFT JOIN outlets o ON ts.outlet_id = o.id
        LEFT JOIN users u ON ts.trainer_id = u.id
        $where_sql
        ORDER BY ts.session_date DESC, ts.start_time DESC
        LIMIT ? OFFSET ?
    ";
    
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt = $conn->prepare($sql);
    $stmt->execute($params);
    
    $sessions = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sessions[] = [
            'id' => (int)$row['id'],
            'session_date' => $row['session_date'],
            'start_time' => $row['start_time'],
            'status' => $row['status'],
            'notes' => $row['notes'],
            'checklist' => [
                'id' => (int)$row['checklist_id'],
                'name' => $row['checklist_name'],
                'description' => $row['checklist_description']
            ],
            'outlet' => [
                'name' => $row['outlet_name'],
                'address' => $row['outlet_address']
            ],
            'trainer' => [
                'id' => (int)$row['trainer_id'],
                'name' => $row['trainer_name']
            ],
            'crew_name' => $row['crew_name'],
            'crew_leader' => $row['crew_leader_name'],
            'counts' => [
                'participants' => (int)$row['participant_count'],
                'responses' => (int)$row['response_count'],
                'photos' => (int)$row['photo_count']
            ],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at']
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Training sessions retrieved successfully',
        'data' => $sessions,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => $total_pages,
            'total_records' => (int)$total_records,
            'per_page' => $limit,
            'has_next' => $page < $total_pages,
            'has_prev' => $page > 1
        ]
    ]);
    
} catch (PDOException $e) {
    error_log("Training Sessions List API - PDO Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'error_details' => [
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
} catch (Exception $e) {
    error_log("Training Sessions List API - General Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
        'error_details' => [
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
}
?>
