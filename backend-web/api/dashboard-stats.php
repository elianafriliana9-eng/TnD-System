<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/User.php';
require_once '../classes/Outlet.php';
require_once '../classes/ChecklistCategory.php';
require_once '../classes/Audit.php';
require_once '../utils/Response.php';
require_once '../utils/Auth.php';
require_once '../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication - return default stats if not authenticated
$isAuthenticated = Auth::checkAuth();
if (!$isAuthenticated) {
    // Return default stats for non-authenticated users
    $defaultStats = [
        'summary' => [
            'total_users' => 0,
            'total_outlets' => 0,
            'total_categories' => 0,
            'total_divisions' => 0
        ],
        'recent_divisions' => [],
        'current_user' => null,
        'authenticated' => false
    ];
    Response::success($defaultStats);
    exit;
}

try {
    require_once '../classes/Divisi.php';
    
    $user = new User();
    $outlet = new Outlet();
    $category = new ChecklistCategory();
    $divisi = new Divisi();
    $audit = new Audit();
    
    // Get counts safely
    try { $totalUsers = $user->count(); } catch (Exception $e) { $totalUsers = 0; }
    try { $totalOutlets = $outlet->count(); } catch (Exception $e) { $totalOutlets = 0; }
    try { $totalCategories = $category->count(); } catch (Exception $e) { $totalCategories = 0; }
    try { $totalDivisions = $divisi->count(); } catch (Exception $e) { $totalDivisions = 0; }

    // Initialize data to prevent errors
    $recentAudits = [];
    $auditTrends = [];

    // Try to get recent audits, but don't fail if table doesn't exist
    try {
        $allRecentAudits = $audit->getAuditsWithDetails();
        $recentAudits = array_slice($allRecentAudits, 0, 5);
    } catch (Exception $e) {
        // table likely doesn't exist, do nothing
    }

    // Try to get audit trends, but don't fail if table doesn't exist
    try {
        $auditTrendsQuery = "SELECT DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(id) as count 
                             FROM audits 
                             WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) 
                             GROUP BY month 
                             ORDER BY month ASC";
        $auditTrends = $audit->query($auditTrendsQuery);
    } catch (Exception $e) {
        // table likely doesn't exist, do nothing
    }

    // Get user info
    $currentUser = Auth::user();
    
    $stats = [
        'summary' => [
            'total_users' => $totalUsers,
            'total_outlets' => $totalOutlets,
            'total_categories' => $totalCategories,
            'total_divisions' => $totalDivisions
        ],
        'recent_audits' => $recentAudits,
        'audit_trends' => $auditTrends,
        'current_user' => $currentUser,
        'authenticated' => true
    ];
    
    Response::success($stats);
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>