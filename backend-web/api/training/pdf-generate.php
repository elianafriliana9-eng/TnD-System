<?php
/**
 * Training PDF Generator
 * Generate PDF report for completed training session
 */

error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
ini_set('display_errors', '0');

header('Content-Type: application/pdf');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../utils/Auth.php';
require_once __DIR__ . '/../../vendor/autoload.php'; // For TCPDF or similar

use Dompdf\Dompdf;
use Dompdf\Options;

// Start session
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
    $db = Database::getInstance()->getConnection();
    
    // Get session data (same as pdf-data.php)
    $stmt = $db->prepare("
        SELECT 
            ts.*,
            tc.name as checklist_name,
            o.name as outlet_name,
            o.address as outlet_address,
            u.full_name as trainer_name
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
        echo json_encode(['success' => false, 'message' => 'Session not found']);
        exit();
    }
    
    // Get evaluations
    $eval_stmt = $db->prepare("
        SELECT 
            te.*,
            tcat.name as category_name,
            tp.question as point_text
        FROM training_evaluations te
        JOIN training_items ti ON te.point_id = ti.id
        JOIN training_categories tcat ON tp.category_id = tcat.id
        WHERE te.session_id = ?
        ORDER BY tcat.order_index, tp.order_index
    ");
    $eval_stmt->execute([$session_id]);
    $evaluations = $eval_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get topics
    $topics_stmt = $db->prepare("
        SELECT topic_text 
        FROM training_topics_delivered 
        WHERE session_id = ?
        ORDER BY id
    ");
    $topics_stmt->execute([$session_id]);
    $topics = $topics_stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Get signatures
    $sig_stmt = $db->prepare("
        SELECT signature_type as role, signer_name as name, signer_position as position
        FROM training_signatures
        WHERE session_id = ?
        ORDER BY 
            CASE signature_type
                WHEN 'staff' THEN 1
                WHEN 'leader' THEN 2
                WHEN 'trainer' THEN 3
            END
    ");
    $sig_stmt->execute([$session_id]);
    $signatures = $sig_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Group evaluations by category
    $categories = [];
    foreach ($evaluations as $eval) {
        $cat_name = $eval['category_name'];
        if (!isset($categories[$cat_name])) {
            $categories[$cat_name] = [];
        }
        $categories[$cat_name][] = $eval;
    }
    
    // Generate HTML
    $html = generatePDFHTML($session, $categories, $topics, $signatures);
    
    // Generate PDF using Dompdf
    $options = new Options();
    $options->set('isHtml5ParserEnabled', true);
    $options->set('isRemoteEnabled', true);
    
    $dompdf = new Dompdf($options);
    $dompdf->loadHtml($html);
    $dompdf->setPaper('A4', 'portrait');
    $dompdf->render();
    
    // Output PDF
    $filename = 'Training_Report_' . $session['outlet_name'] . '_' . date('Ymd', strtotime($session['session_date'])) . '.pdf';
    $dompdf->stream($filename, ['Attachment' => false]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error generating PDF: ' . $e->getMessage()
    ]);
}

function generatePDFHTML($session, $categories, $topics, $signatures) {
    $rating_summary = json_decode($session['rating_summary'], true);
    
    $html = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; font-size: 12px; }
            .header { text-align: center; margin-bottom: 20px; }
            .header h1 { margin: 0; font-size: 18px; }
            .header h2 { margin: 5px 0; font-size: 14px; color: #666; }
            .info-table { width: 100%; margin-bottom: 20px; }
            .info-table td { padding: 5px; }
            .info-table td:first-child { width: 150px; font-weight: bold; }
            .section-title { 
                background: #4A90E2; 
                color: white; 
                padding: 8px; 
                margin: 20px 0 10px 0;
                font-weight: bold;
            }
            .eval-table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
            .eval-table th, .eval-table td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            .eval-table th { background: #f5f5f5; font-weight: bold; }
            .rating-baik { background: #d4edda; color: #155724; }
            .rating-cukup { background: #fff3cd; color: #856404; }
            .rating-kurang { background: #f8d7da; color: #721c24; }
            .summary-box { 
                background: #f8f9fa; 
                border: 1px solid #dee2e6; 
                padding: 15px; 
                margin: 15px 0;
                border-radius: 5px;
            }
            .signatures { 
                display: table; 
                width: 100%; 
                margin-top: 30px;
            }
            .signature-box { 
                display: table-cell; 
                width: 33%; 
                text-align: center; 
                padding: 10px;
            }
            .signature-line {
                border-top: 1px solid #000;
                margin-top: 60px;
                padding-top: 5px;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>LAPORAN EVALUASI TRAINING</h1>
            <h2>' . htmlspecialchars($session['checklist_name']) . '</h2>
        </div>
        
        <table class="info-table">
            <tr>
                <td>Outlet</td>
                <td>: ' . htmlspecialchars($session['outlet_name']) . '</td>
            </tr>
            <tr>
                <td>Alamat</td>
                <td>: ' . htmlspecialchars($session['outlet_address']) . '</td>
            </tr>
            <tr>
                <td>Tanggal Training</td>
                <td>: ' . date('d F Y', strtotime($session['session_date'])) . '</td>
            </tr>
            <tr>
                <td>Waktu</td>
                <td>: ' . $session['start_time'] . ' - ' . ($session['end_time'] ?? '-') . '</td>
            </tr>
            <tr>
                <td>Trainer</td>
                <td>: ' . htmlspecialchars($session['trainer_name']) . '</td>
            </tr>
        </table>';
    
    // Evaluations by category
    $html .= '<div class="section-title">HASIL EVALUASI</div>';
    
    foreach ($categories as $cat_name => $points) {
        $html .= '<h3 style="margin: 15px 0 10px 0;">' . htmlspecialchars($cat_name) . '</h3>';
        $html .= '<table class="eval-table">
            <thead>
                <tr>
                    <th style="width: 50px;">No</th>
                    <th>Point Evaluasi</th>
                    <th style="width: 100px;">Rating</th>
                    <th style="width: 200px;">Catatan</th>
                </tr>
            </thead>
            <tbody>';
        
        $no = 1;
        foreach ($points as $point) {
            $rating_class = 'rating-' . strtolower($point['rating']);
            $html .= '<tr>
                <td>' . $no++ . '</td>
                <td>' . htmlspecialchars($point['point_text']) . '</td>
                <td class="' . $rating_class . '">' . strtoupper($point['rating']) . '</td>
                <td>' . htmlspecialchars($point['notes'] ?? '-') . '</td>
            </tr>';
        }
        
        $html .= '</tbody></table>';
    }
    
    // Summary
    if ($rating_summary) {
        $html .= '<div class="summary-box">
            <h3 style="margin-top: 0;">Ringkasan Penilaian</h3>
            <p>Total Point Evaluasi: <strong>' . $rating_summary['total_points'] . '</strong></p>
            <p>
                <span class="rating-baik" style="padding: 5px 10px; border-radius: 3px;">Baik: ' . $rating_summary['baik']['count'] . ' (' . $rating_summary['baik']['percentage'] . '%)</span>
                <span class="rating-cukup" style="padding: 5px 10px; border-radius: 3px; margin-left: 10px;">Cukup: ' . $rating_summary['cukup']['count'] . ' (' . $rating_summary['cukup']['percentage'] . '%)</span>
                <span class="rating-kurang" style="padding: 5px 10px; border-radius: 3px; margin-left: 10px;">Kurang: ' . $rating_summary['kurang']['count'] . ' (' . $rating_summary['kurang']['percentage'] . '%)</span>
            </p>
            <p>Skor Rata-rata: <strong>' . number_format($session['average_score'], 2) . '</strong></p>
        </div>';
    }
    
    // Training topics
    if (!empty($topics)) {
        $html .= '<div class="section-title">MATERI TRAINING YANG DIBERIKAN</div>';
        $html .= '<ol>';
        foreach ($topics as $topic) {
            $html .= '<li>' . htmlspecialchars($topic) . '</li>';
        }
        $html .= '</ol>';
    }
    
    // Trainer notes
    if (!empty($session['trainer_notes'])) {
        $html .= '<div class="section-title">CATATAN TRAINER</div>';
        $html .= '<p>' . nl2br(htmlspecialchars($session['trainer_notes'])) . '</p>';
    }
    
    // Signatures
    $html .= '<div class="signatures">';
    foreach ($signatures as $sig) {
        $role_label = [
            'staff' => 'Staff',
            'leader' => 'Leader',
            'trainer' => 'Trainer'
        ];
        
        $html .= '<div class="signature-box">
            <p><strong>' . $role_label[$sig['role']] . '</strong></p>
            <div class="signature-line">
                <strong>' . htmlspecialchars($sig['name']) . '</strong><br>
                ' . htmlspecialchars($sig['position']) . '
            </div>
        </div>';
    }
    $html .= '</div>';
    
    $html .= '
    </body>
    </html>';
    
    return $html;
}
