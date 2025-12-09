<?php
/**
 * Start Training Session API
 * Create new training session
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Response.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../utils/Headers.php';

Headers::setAPIHeaders();

if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Temporarily disabled for testing
// if (!Auth::checkAuth()) {
//     Response::unauthorized('Authentication required');
// }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    $data = json_decode(file_get_contents('php://input'), true);

    // Validate required fields
    if (!isset($data['outlet_id'])) {
        Response::error('Outlet ID required', 400);
    }

    $db = Database::getInstance()->getConnection();

    // Get trainer_id from request or session
    $trainerId = $data['trainer_id'] ?? ($_SESSION['user_id'] ?? null);

    if (!$trainerId) {
        Response::error('Trainer ID required', 400);
    }

    // Check if trainer exists
    $stmt = $db->prepare("SELECT role FROM users WHERE id = :id");
    $stmt->execute([':id' => $trainerId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        Response::error('Trainer not found', 404);
    }

    // Handle checklist_id - convert 0 to NULL for proper foreign key
    $checklistId = isset($data['checklist_id']) && $data['checklist_id'] != 0 ? $data['checklist_id'] : null;

    // Always create with 'scheduled' status
    $status = 'scheduled';

    // Handle crew_leader (as name/text) - use the crew_leader from the request data
    $crewLeader = $data['crew_leader'] ?? null;
    
    // Handle crew_name (nama crew yang sedang ditraining)
    $crewName = $data['crew_name'] ?? null;

    // Create training session
    $sql = "INSERT INTO training_sessions
            (outlet_id, trainer_id, checklist_id, crew_leader, crew_name, session_date, start_time, status, notes)
            VALUES
            (:outlet_id, :trainer_id, :checklist_id, :crew_leader, :crew_name, :session_date, :start_time, :status, :notes)";

    $stmt = $db->prepare($sql);
    $stmt->execute([
        ':outlet_id' => $data['outlet_id'],
        ':trainer_id' => $trainerId,
        ':checklist_id' => $checklistId,
        ':crew_leader' => $crewLeader,
        ':crew_name' => $crewName,
        ':session_date' => $data['session_date'] ?? date('Y-m-d'),
        ':start_time' => $data['start_time'] ?? date('H:i:s'),
        ':status' => $status,
        ':notes' => $data['notes'] ?? null
    ]);

    $sessionId = $db->lastInsertId();

    // Save selected categories if the table exists
    if (!empty($data['category_ids']) && is_array($data['category_ids'])) {
        // Check if the table exists first
        $tableCheck = $db->query("SHOW TABLES LIKE 'training_session_categories'");
        if ($tableCheck->rowCount() > 0) {
            // Validate category IDs exist in training_categories table
            $validCategoryIds = [];
            foreach ($data['category_ids'] as $categoryId) {
                $catCheck = $db->prepare("SELECT id FROM training_categories WHERE id = :id");
                $catCheck->execute([':id' => $categoryId]);
                if ($catCheck->rowCount() > 0) {
                    $validCategoryIds[] = $categoryId;
                }
            }

            // Only insert valid category IDs
            if (!empty($validCategoryIds)) {
                $catSql = "INSERT INTO training_session_categories (session_id, category_id) VALUES (:session_id, :category_id)";
                $catStmt = $db->prepare($catSql);
                foreach ($validCategoryIds as $categoryId) {
                    $catStmt->execute([':session_id' => $sessionId, ':category_id' => $categoryId]);
                }
            }
        }
    }

    // Get created session details
    $sql = "SELECT
                ts.*,
                o.name as outlet_name,
                u.full_name as trainer_name,
                ts.crew_leader as crew_leader_name,
                ts.crew_name,
                tc.name as checklist_name
            FROM training_sessions ts
            LEFT JOIN outlets o ON ts.outlet_id = o.id
            LEFT JOIN users u ON ts.trainer_id = u.id
            LEFT JOIN training_checklists tc ON ts.checklist_id = tc.id
            WHERE ts.id = :id";

    $stmt = $db->prepare($sql);
    $stmt->execute([':id' => $sessionId]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);

    Response::success([
        'message' => 'Training session scheduled successfully',
        'session' => $session
    ], 'Training session created', 201);

} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
