<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/Outlet.php';
require_once '../utils/Response.php';
require_once '../utils/Request.php';
require_once '../utils/Auth.php';

// Enable CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// Start session BEFORE any auth check
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// DEBUG: Log incoming request
error_log('=== OUTLETS API DEBUG ===');
error_log('Method: ' . $_SERVER['REQUEST_METHOD']);
error_log('Headers: ' . print_r(getallheaders(), true));

// Check authentication - will set session from bearer token if available
if (!Auth::checkAuth()) {
    error_log('Auth check failed');
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Authentication required',
        'errors' => null,
        'debug' => [
            'session' => $_SESSION ?? [],
            'headers' => function_exists('getallheaders') ? getallheaders() : 'getallheaders not available'
        ]
    ]);
    exit;
}

// Get current user and division
$currentUser = Auth::getUserFromHeader();
if (!$currentUser) {
    $currentUser = Auth::user();
}

if (!$currentUser) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'User not found',
        'errors' => null
    ]);
    exit;
}

// For trainer role, show all outlets; for others, filter by division
$userRole = isset($currentUser['role']) ? $currentUser['role'] : null;
$userDivisionId = (isset($currentUser['division_id']) && $userRole !== 'trainer') 
    ? (int)$currentUser['division_id'] 
    : null;

$request = new Request();
$method = $_SERVER['REQUEST_METHOD'];
$outlet = new Outlet();

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                // Get single outlet
                $id = intval($_GET['id']);
                $result = $outlet->findById($id);
                if ($result) {
                    Response::success($result);
                } else {
                    Response::error('Outlet not found', 404);
                }
            } else {
                // Get all outlets - trainer can see all, others filtered by division
                $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
                $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
                
                // Handle -1 or 0 or very small values as "get all"
                // If limit is -1, 0, or not specified, use large number to fetch all
                if ($limit <= 0) {
                    $limit = 99999; // Large number to get all outlets
                    $page = 1; // Reset to page 1 when getting all
                }
                
                // Pass division_id to method directly (null for trainer)
                $outlets = $outlet->findAllWithDivision($page, $limit, '', $userDivisionId);
                
                // Count with or without division filter
                if ($userDivisionId !== null) {
                    $total = $outlet->count('division_id = :division_id', [':division_id' => $userDivisionId]);
                } else {
                    $total = $outlet->count();
                }
                
                Response::success([
                    'data' => $outlets,
                    'pagination' => [
                        'page' => $page,
                        'limit' => $limit,
                        'total' => $total,
                        'pages' => ceil($total / $limit)
                    ],
                    'debug' => [
                        'user_division_id' => $userDivisionId,
                        'user_email' => $currentUser['email'] ?? null
                    ]
                ]);
            }
            break;
            
        case 'POST':
            $data = $request->getBody();

            // Handle frontend sending 'manager' instead of 'manager_name'
            if (isset($data['manager'])) {
                $data['manager_name'] = $data['manager'];
                unset($data['manager']);
            }
            
            // Validate required fields
            $required = ['division_id', 'name', 'code', 'address', 'phone', 'manager_name'];
            foreach ($required as $field) {
                if (empty($data[$field])) {
                    Response::error("Field {$field} is required", 400);
                    exit;
                }
            }
            
            $outletData = [
                'division_id' => intval($data['division_id']),
                'name' => $data['name'],
                'code' => $data['code'],
                'address' => $data['address'],
                'phone' => $data['phone'],
                'manager_name' => $data['manager_name'],
                'status' => isset($data['status']) ? $data['status'] : 'active'
            ];
            
            $result = $outlet->create($outletData);
            if ($result) {
                Response::success(['id' => $result, 'message' => 'Outlet created successfully'], 201);
            } else {
                Response::error('Failed to create outlet', 500);
            }
            break;
            
        case 'PUT':
            if (!isset($_GET['id'])) {
                Response::error('Outlet ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            $data = $request->getBody();
            
            // Handle frontend sending 'manager' instead of 'manager_name'
            if (isset($data['manager'])) {
                $data['manager_name'] = $data['manager'];
                unset($data['manager']);
            }

            // Check if outlet exists
            $existing = $outlet->findById($id);
            if (!$existing) {
                Response::error('Outlet not found', 404);
                exit;
            }
            
            $outletData = [];
            $allowedFields = ['division_id', 'name', 'code', 'address', 'phone', 'manager_name', 'status'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    if ($field === 'division_id') {
                        $outletData[$field] = intval($data[$field]);
                    } else {
                        $outletData[$field] = $data[$field];
                    }
                }
            }
            
            if (empty($outletData)) {
                Response::error('No valid fields to update', 400);
                exit;
            }
            
            $result = $outlet->update($id, $outletData);
            if ($result) {
                Response::success(['message' => 'Outlet updated successfully']);
            } else {
                Response::error('Failed to update outlet', 500);
            }
            break;
            
        case 'DELETE':
            if (!isset($_GET['id'])) {
                Response::error('Outlet ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            // Check if outlet exists
            $existing = $outlet->findById($id);
            if (!$existing) {
                Response::error('Outlet not found', 404);
                exit;
            }
            
            $result = $outlet->delete($id);
            // Reset auto increment jika kosong
            $outlet->resetAutoIncrementIfEmpty();
            if ($result) {
                Response::success(['message' => 'Outlet deleted successfully']);
            } else {
                Response::error('Failed to delete outlet', 500);
            }
            break;
            
        default:
            Response::error('Method not allowed', 405);
            break;
    }
    
} catch (Exception $e) {
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>