<?php
/**
 * Training Session - Get Full Details
 * 
 * Get complete training session data including participants, responses, and photos
 * 
 * @endpoint GET /api/training/session-detail.php?id={session_id}
 * @auth Required
 */

// Suppress PHP errors in JSON response
error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

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

// Start session if not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Authentication required'
    ]);
    exit();
}

// Only GET method allowed
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit();
}

// Validate session_id
if (!isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameter: id'
    ]);
    exit();
}

$session_id = $_GET['id'];

try {
    $db = Database::getInstance();
    $conn = $db->getConnection();
    
    // Get session details
    $stmt = $conn->prepare("
        SELECT 
            ts.*,
            tc.name as checklist_name,
            tc.description as checklist_description,
            o.name as outlet_name,
            o.address as outlet_address,
            o.region as outlet_city,
            u.full_name as trainer_name,
            u.email as trainer_email
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        JOIN outlets o ON ts.outlet_id = o.id
        JOIN users u ON ts.trainer_id = u.id
        WHERE ts.id = ?
    ");
    $stmt->execute([$session_id]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Training session not found'
        ]);
        exit();
    }
    
    // Get checklist structure with categories, points, and evaluations
    $categories_stmt = $conn->prepare("
        SELECT 
            tcat.id as category_id,
            tcat.name as category_name,
            tcat.description as category_description,
            tcat.order_index as category_order
        FROM training_categories tcat
        WHERE tcat.checklist_id = ?
        ORDER BY tcat.order_index ASC
    ");
    $categories_stmt->execute([$session['checklist_id']]);
    $categories = [];
    error_log("DEBUG: Checklist ID: " . $session['checklist_id'] . ", Categories found: " . $categories_stmt->rowCount());
    
    while ($cat_row = $categories_stmt->fetch(PDO::FETCH_ASSOC)) {
        error_log("DEBUG: Processing category - ID: {$cat_row['category_id']}, Name: {$cat_row['category_name']}");
        // Get points for this category with evaluations
        // Try training_points first (new normalized table), fallback to training_items if needed
        $points = [];
        
        try {
            // First try training_points table
            $points_stmt = $conn->prepare("
                SELECT 
                    tp.id as point_id,
                    tp.question as point_text,
                    tp.order_index as point_order,
                    te.rating,
                    te.notes
                FROM training_points tp
                LEFT JOIN training_evaluations te ON tp.id = te.point_id AND te.session_id = ?
                WHERE tp.category_id = ?
                ORDER BY tp.order_index ASC
            ");
            $points_stmt->execute([$session_id, $cat_row['category_id']]);
        } catch (PDOException $e) {
            // Fallback to training_items if training_points doesn't exist
            error_log("training_points query failed, trying training_items: " . $e->getMessage());
            $points_stmt = $conn->prepare("
                SELECT 
                    tp.id as point_id,
                    tp.question as point_text,
                    tp.order_index as point_order,
                    te.rating,
                    te.notes
                FROM training_items tp
                LEFT JOIN training_evaluations te ON tp.id = te.point_id AND te.session_id = ?
                WHERE tp.category_id = ?
                ORDER BY tp.order_index ASC
            ");
            $points_stmt->execute([$session_id, $cat_row['category_id']]);
        }
        
        $points = [];
        while ($point_row = $points_stmt->fetch(PDO::FETCH_ASSOC)) {
            $points[] = [
                'id' => (int)$point_row['point_id'],
                'point_text' => $point_row['point_text'],
                'order' => (int)$point_row['point_order'],
                'rating' => $point_row['rating'],
                'notes' => $point_row['notes']
            ];
        }
        
        $categories[] = [
            'id' => (int)$cat_row['category_id'],
            'category_name' => $cat_row['category_name'],
            'description' => $cat_row['category_description'],
            'order' => (int)$cat_row['category_order'],
            'points' => $points
        ];
    }
    
    error_log("DEBUG: Total categories returned for session: " . count($categories));
    foreach ($categories as $cat) {
        error_log("DEBUG: Returning category - ID: {$cat['id']}, Name: {$cat['category_name']}, Points: " . count($cat['points']));
    }
    
    // Get training topics delivered
    $topics_stmt = $conn->prepare("
        SELECT topic
        FROM training_topics_delivered
        WHERE session_id = ?
        ORDER BY order_index ASC
    ");
    $topics_stmt->execute([$session_id]);
    
    $topics = [];
    while ($topic_row = $topics_stmt->fetch(PDO::FETCH_ASSOC)) {
        $topics[] = $topic_row['topic'];
    }
    
    // Get signatures
    $signatures_stmt = $conn->prepare("
        SELECT 
            signature_type,
            signer_name,
            signer_position,
            signed_at
        FROM training_signatures
        WHERE session_id = ?
    ");
    $signatures_stmt->execute([$session_id]);
    
    $signatures = [
        'staff' => null,
        'leader' => null,
        'trainer' => null
    ];
    
    while ($sig_row = $signatures_stmt->fetch(PDO::FETCH_ASSOC)) {
        $signatures[$sig_row['signature_type']] = [
            'name' => $sig_row['signer_name'],
            'position' => $sig_row['signer_position'],
            'signed_at' => $sig_row['signed_at']
        ];
    }
    
    // Get photos
    $photos_stmt = $conn->prepare("
        SELECT 
            id,
            photo_path,
            caption,
            uploaded_at
        FROM training_photos
        WHERE session_id = ?
        ORDER BY uploaded_at ASC
    ");
    $photos_stmt->execute([$session_id]);
    
    $photos = [];
    while ($photo_row = $photos_stmt->fetch(PDO::FETCH_ASSOC)) {
        $photos[] = [
            'id' => (int)$photo_row['id'],
            'photo_url' => '/tnd_system/tnd_system/' . $photo_row['photo_path'],
            'caption' => $photo_row['caption'],
            'uploaded_at' => $photo_row['uploaded_at']
        ];
    }
    
    // Parse rating summary if available
    $rating_summary = null;
    if ($session['rating_summary']) {
        $rating_summary = json_decode($session['rating_summary'], true);
    }
    
    // Build response
    $response_data = [
        'id' => (int)$session['id'],
        'session_date' => $session['session_date'],
        'start_time' => $session['start_time'],
        'end_time' => $session['end_time'],
        'status' => $session['status'],
        'notes' => $session['notes'],
        'trainer_notes' => $session['trainer_notes'],
        'average_score' => $session['average_score'] ? round((float)$session['average_score'], 2) : null,
        'rating_summary' => $rating_summary,
        'checklist' => [
            'id' => (int)$session['checklist_id'],
            'name' => $session['checklist_name'],
            'description' => $session['checklist_description']
        ],
        'outlet' => [
            'id' => (int)$session['outlet_id'],
            'name' => $session['outlet_name'],
            'address' => $session['outlet_address'],
            'city' => $session['outlet_city']
        ],
        'trainer' => [
            'id' => (int)$session['trainer_id'],
            'name' => $session['trainer_name'],
            'email' => $session['trainer_email']
        ],
        'topics' => $topics,
        'signatures' => $signatures,
        'photos' => $photos,
        'evaluation_summary' => $categories,
        'counts' => [
            'topics' => count($topics),
            'photos' => count($photos),
            'total_points' => array_sum(array_map(function($cat) {
                return count($cat['points']);
            }, $categories))
        ],
        'created_at' => $session['created_at'],
        'updated_at' => $session['updated_at'],
        'completed_at' => $session['completed_at']
    ];
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Training session details retrieved successfully',
        'data' => $response_data
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
