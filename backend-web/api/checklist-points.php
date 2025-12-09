<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/ChecklistPoint.php';
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

// Check authentication
if (!Auth::checkAuth()) {
    Response::error('Authentication required', 401);
    exit;
}

$request = new Request();
$method = $_SERVER['REQUEST_METHOD'];
$point = new ChecklistPoint();

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                // Get single point
                $id = intval($_GET['id']);
                $result = $point->findById($id);
                if ($result) {
                    Response::success($result);
                } else {
                    Response::error('Checklist point not found', 404);
                }
            } elseif (isset($_GET['category_id'])) {
                // Get points by category
                $categoryId = intval($_GET['category_id']);
                $points = $point->findByCategory($categoryId);
                Response::success(['data' => $points]);
            } else {
                // Get all points
                $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
                $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
                $search = isset($_GET['search']) ? $_GET['search'] : '';
                
                $points = $point->findAll($page, $limit, $search);
                $total = $point->count($search);
                
                Response::success([
                    'data' => $points,
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
            
            // Validate required fields - support both 'question' and 'name' fields
            if (empty($data['category_id'])) {
                Response::error("Field category_id is required", 400);
                exit;
            }
            
            if (empty($data['question']) && empty($data['name'])) {
                Response::error("Field question (or name) is required", 400);
                exit;
            }
            
            if (empty($data['description'])) {
                Response::error("Field description is required", 400);
                exit;
            }
            
            $pointData = [
                'category_id' => intval($data['category_id']),
                'question' => $data['question'] ?? $data['name'], // Support both fields
                'description' => $data['description'],
                'max_score' => isset($data['max_score']) ? intval($data['max_score']) : 10,
                'is_active' => isset($data['is_active']) ? intval($data['is_active']) : 1
            ];
            
            $result = $point->create($pointData);
            if ($result) {
                Response::success(['id' => $result, 'message' => 'Checklist point created successfully'], 201);
            } else {
                Response::error('Failed to create checklist point', 500);
            }
            break;
            
        case 'PUT':
            if (!isset($_GET['id'])) {
                Response::error('Checklist point ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            $data = $request->getBody();
            
            // Check if point exists
            $existing = $point->findById($id);
            if (!$existing) {
                Response::error('Checklist point not found', 404);
                exit;
            }
            
            $pointData = [];
            $allowedFields = ['category_id', 'question', 'description', 'max_score', 'is_active'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    if ($field === 'category_id' || $field === 'max_score' || $field === 'is_active') {
                        $pointData[$field] = intval($data[$field]);
                    } else {
                        $pointData[$field] = $data[$field];
                    }
                }
                
                // Support legacy 'name' field for 'question'
                if ($field === 'question' && !isset($data['question']) && isset($data['name'])) {
                    $pointData['question'] = $data['name'];
                }
            }
            
            if (empty($pointData)) {
                Response::error('No valid fields to update', 400);
                exit;
            }
            
            $result = $point->update($id, $pointData);
            if ($result) {
                Response::success(['message' => 'Checklist point updated successfully']);
            } else {
                Response::error('Failed to update checklist point', 500);
            }
            break;
            
        case 'DELETE':
            if (!isset($_GET['id'])) {
                Response::error('Checklist point ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            // Check if point exists
            $existing = $point->findById($id);
            if (!$existing) {
                Response::error('Checklist point not found', 404);
                exit;
            }
            
            $result = $point->delete($id);
            if ($result) {
                Response::success(['message' => 'Checklist point deleted successfully']);
            } else {
                Response::error('Failed to delete checklist point', 500);
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