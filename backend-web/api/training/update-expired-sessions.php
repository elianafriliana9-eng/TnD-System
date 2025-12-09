<?php
/**
 * Update Expired Training Sessions
 * 
 * This script updates the status of training sessions to 'expired' 
 * if they are past their scheduled date and still have a 'scheduled' status.
 * 
 * This script is intended to be run by a cron job daily.
 */

header('Content-Type: application/json');

require_once '../../config/database.php';
require_once '../../classes/Database.php';

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();

    $sql = "
        UPDATE training_sessions
        SET status = 'expired'
        WHERE status = 'scheduled'
        AND session_date < CURDATE()
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();

    $affected_rows = $stmt->rowCount();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Expired training sessions updated successfully.",
        'updated_sessions' => $affected_rows
    ]);

} catch (PDOException $e) {
    error_log("Update Expired Sessions - PDO Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("Update Expired Sessions - General Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>
