<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/Divisi.php';
require_once '../utils/Response.php';
require_once '../utils/Request.php';
require_once '../utils/Auth.php';
require_once '../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Allow simple query without authentication (for dropdowns in forms)
$isSimpleQuery = isset($_GET['simple']) && $_GET['simple'] == 'true';

// Check authentication (except for simple queries)
if (!$isSimpleQuery && !Auth::checkAuth()) {
    Response::error('Authentication required', 401);
    exit;
}

$request = new Request();
$method = $_SERVER['REQUEST_METHOD'];
$divisi = new Divisi();

try {
    switch ($method) {
        case 'GET':
            if ($isSimpleQuery) {
                // Get simple list of all divisions for dropdowns (no auth required)
                $divisions = $divisi->findAllSimple();
                Response::success($divisions);
            } else if (isset($_GET['id'])) {
                // Get single division with categories and outlets
                $id = intval($_GET['id']);
                $division = $divisi->findById($id);
                if ($division) {
                    $division['categories'] = $divisi->getCategories($id);
                    $division['outlets'] = $divisi->getOutlets($id);
                    Response::success($division);
                } else {
                    Response::error('Division not found', 404);
                }
            } else {
                // Get all divisions with counts and pagination
                $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
                $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
                $search = isset($_GET['search']) ? $_GET['search'] : '';
                
                $divisions = $divisi->findWithCounts($page, $limit, $search);
                $total = $divisi->count($search);
                
                Response::success([
                    'data' => $divisions,
                    'pagination' => [
                        'page' => $page,
                        'limit' => $limit,
                        'total' => $total,
                        'pages' => ceil($total / $limit)
                    ]
                ]);
            }
            break;
            
        case 'POST':
            $data = $request->getBody();
            
            // Validate data
            $errors = $divisi->validate($data);
            if (!empty($errors)) {
                Response::error(implode(', ', $errors), 400);
                exit;
            }
            
            $divisionData = [
                'name' => $data['name'],
                'description' => $data['description'],
                'status' => isset($data['status']) ? $data['status'] : 'active'
            ];
            
            $result = $divisi->create($divisionData);
            if ($result) {
                Response::success(['id' => $result, 'message' => 'Division created successfully'], 201);
            } else {
                Response::error('Failed to create division', 500);
            }
            break;
            
        case 'PUT':
            if (!isset($_GET['id'])) {
                Response::error('Division ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            $data = $request->getBody();
            
            // Check if division exists
            $existing = $divisi->findById($id);
            if (!$existing) {
                Response::error('Division not found', 404);
                exit;
            }
            
            // Validate data
            $errors = $divisi->validate($data, $id);
            if (!empty($errors)) {
                Response::error(implode(', ', $errors), 400);
                exit;
            }
            
            $divisionData = [];
            $allowedFields = ['name', 'description', 'status'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    $divisionData[$field] = $data[$field];
                }
            }
            
            if (empty($divisionData)) {
                Response::error('No valid fields to update', 400);
                exit;
            }
            
            $result = $divisi->update($id, $divisionData);
            if ($result) {
                Response::success(['message' => 'Division updated successfully']);
            } else {
                Response::error('Failed to update division', 500);
            }
            break;
            
        case 'DELETE':
            if (!isset($_GET['id'])) {
                Response::error('Division ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            // Check if division exists
            $existing = $divisi->findById($id);
            if (!$existing) {
                Response::error('Division not found', 404);
                exit;
            }
            
            // Check if division has categories or outlets
            $categories = $divisi->getCategories($id);
            $outlets = $divisi->getOutlets($id);
            
            if (!empty($categories) || !empty($outlets)) {
                Response::error('Cannot delete division that has categories or outlets. Please move them first.', 400);
                exit;
            }
            
            $result = $divisi->delete($id);
            if ($result) {
                Response::success(['message' => 'Division deleted successfully']);
            } else {
                Response::error('Failed to delete division', 500);
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