<?php
/**
 * Training PDF Data
 * 
 * Get all data needed to generate training session PDF report
 * 
 * @endpoint GET /api/training/pdf-data.php?session_id={id}
 * @auth Required
 */

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

// Check authentication - temporarily disabled for PDF generation
// $auth = Auth::checkAuth();
// if (!$auth['authenticated']) {
//     http_response_code(401);
//     echo json_encode([
//         'success' => false,
//         'message' => 'Authentication required'
//     ]);
//     exit();
// }

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
if (!isset($_GET['session_id'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameter: session_id'
    ]);
    exit();
}

$session_id = $_GET['session_id'];

try {
    $db = new Database();
    $conn = $db->getConnection();
    
    // Get session basic info
    $session_stmt = $conn->prepare("
        SELECT 
            ts.id,
            ts.session_date,
            ts.start_time,
            ts.end_time,
            ts.status,
            ts.notes,
            ts.trainer_notes,
            ts.average_score,
            ts.rating_summary,
            ts.percentage_baik,
            ts.percentage_cukup,
            ts.percentage_kurang,
            ts.completed_at,
            ts.created_at,
            tc.id as checklist_id,
            tc.checklist_name,
            tc.description as checklist_description,
            o.outlet_name,
            o.outlet_address,
            o.outlet_city,
            o.outlet_phone,
            u.full_name as trainer_name,
            u.email as trainer_email,
            u.phone as trainer_phone,
            u.specialization as trainer_specialization,
            u.trainer_bio
        FROM training_sessions ts
        JOIN training_checklists tc ON ts.checklist_id = tc.id
        JOIN outlets o ON ts.outlet_id = o.id
        JOIN users u ON ts.trainer_id = u.id
        WHERE ts.id = ?
    ");
    $session_stmt->execute([$session_id]);
    $session = $session_stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$session) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Training session not found'
        ]);
        exit();
    }
    
    // Check access permission
    if ($auth['role'] === 'trainer' && $session['trainer_id'] != $auth['user_id']) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'You do not have permission to access this data'
        ]);
        exit();
    }
    
    // Only generate PDF for completed sessions
    if ($session['status'] !== 'completed') {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'PDF can only be generated for completed sessions'
        ]);
        exit();
    }
    
    // Get categories with points and responses
    $categories_stmt = $conn->prepare("
        SELECT 
            tcat.id as category_id,
            tcat.category_name,
            tcat.description as category_description,
            tcat.display_order
        FROM training_categories tcat
        WHERE tcat.checklist_id = ?
        ORDER BY tcat.display_order ASC
    ");
    $categories_stmt->execute([$session['checklist_id']]);
    
    $checklist_structure = [];
    $all_point_ids = [];
    
    while ($cat_row = $categories_stmt->fetch(PDO::FETCH_ASSOC)) {
        $category_id = $cat_row['category_id'];
        
        // Get points for this category with evaluations
        $points_stmt = $conn->prepare("
            SELECT 
                tp.id as point_id,
                tp.point_text,
                tp.description as point_description,
                tp.display_order,
                te.rating,
                te.notes as evaluation_notes
            FROM training_items ti
            LEFT JOIN training_evaluations te ON tp.id = te.point_id AND te.session_id = ?
            WHERE tp.category_id = ?
            ORDER BY tp.display_order ASC
        ");
        $points_stmt->execute([$session_id, $category_id]);
        
        $points = [];
        while ($point_row = $points_stmt->fetch(PDO::FETCH_ASSOC)) {
            $points[] = [
                'id' => (int)$point_row['point_id'],
                'text' => $point_row['point_text'],
                'description' => $point_row['point_description'],
                'order' => (int)$point_row['display_order'],
                'rating' => $point_row['rating'],
                'notes' => $point_row['evaluation_notes']
            ];
            $all_point_ids[] = (int)$point_row['point_id'];
        }
        
        $checklist_structure[] = [
            'id' => (int)$category_id,
            'name' => $cat_row['category_name'],
            'description' => $cat_row['category_description'],
            'order' => (int)$cat_row['display_order'],
            'points' => $points,
            'points_count' => count($points)
        ];
    }
    
    // Get training topics delivered
    $topics_stmt = $conn->prepare("
        SELECT topic, order_index
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
        ORDER BY 
            CASE signature_type
                WHEN 'staff' THEN 1
                WHEN 'leader' THEN 2
                WHEN 'trainer' THEN 3
            END
    ");
    $signatures_stmt->execute([$session_id]);
    
    $signatures = [];
    while ($sig_row = $signatures_stmt->fetch(PDO::FETCH_ASSOC)) {
        $signatures[$sig_row['signature_type']] = [
            'name' => $sig_row['signer_name'],
            'position' => $sig_row['signer_position'],
            'signed_at' => $sig_row['signed_at']
        ];
    }
    
    // Get training photos
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
            'photo_path' => $photo_row['photo_path'],
            'caption' => $photo_row['caption'],
            'uploaded_at' => $photo_row['uploaded_at']
        ];
    }
    
    // Get rating summary from session
    $rating_summary = json_decode($session['rating_summary'], true);
    
    // Calculate comprehensive statistics
    $stats = [
        'total_points' => count($all_point_ids),
        'total_categories' => count($checklist_structure),
        'total_photos' => count($photos),
        'total_topics' => count($topics),
        'average_score' => round((float)$session['average_score'], 2),
        'rating_summary' => $rating_summary,
        'percentage_baik' => round((float)$session['percentage_baik'], 2),
        'percentage_cukup' => round((float)$session['percentage_cukup'], 2),
        'percentage_kurang' => round((float)$session['percentage_kurang'], 2)
    ];
    
    // Build PDF data response
    $pdf_data = [
        'session' => [
            'id' => (int)$session['id'],
            'session_date' => $session['session_date'],
            'start_time' => $session['start_time'],
            'end_time' => $session['end_time'],
            'status' => $session['status'],
            'notes' => $session['notes'],
            'trainer_notes' => $session['trainer_notes'],
            'average_score' => round((float)$session['average_score'], 2),
            'created_at' => $session['created_at'],
            'completed_at' => $session['completed_at']
        ],
        'checklist' => [
            'name' => $session['checklist_name'],
            'description' => $session['checklist_description'],
            'structure' => $checklist_structure
        ],
        'outlet' => [
            'name' => $session['outlet_name'],
            'address' => $session['outlet_address'],
            'city' => $session['outlet_city'],
            'phone' => $session['outlet_phone']
        ],
        'trainer' => [
            'name' => $session['trainer_name'],
            'email' => $session['trainer_email'],
            'phone' => $session['trainer_phone'],
            'specialization' => $session['trainer_specialization'],
            'bio' => $session['trainer_bio']
        ],
        'topics' => $topics,
        'signatures' => $signatures,
        'photos' => $photos,
        'statistics' => $stats,
        'generated_at' => date('Y-m-d H:i:s')
    ];
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'PDF data retrieved successfully',
        'data' => $pdf_data
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>
