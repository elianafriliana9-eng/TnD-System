<?php
require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/ChecklistCategory.php';
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
$category = new ChecklistCategory();

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                // Get single category
                $id = intval($_GET['id']);
                $result = $category->findById($id);
                if ($result) {
                    Response::success($result);
                } else {
                    Response::error('Category not found', 404);
                }
            } else {
                // Get all categories
                $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
                $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
                $search = isset($_GET['search']) ? $_GET['search'] : '';
                
                $categories = $category->findAll($page, $limit, $search);
                $total = $category->count($search);
                
                Response::success([
                    'data' => $categories,
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
            
            // Validate required fields
            $required = ['division_id', 'name', 'description'];
            foreach ($required as $field) {
                if (empty($data[$field])) {
                    Response::error("Field {$field} is required", 400);
                    exit;
                }
            }
            
            $categoryData = [
                'division_id' => intval($data['division_id']),
                'name' => $data['name'],
                'description' => $data['description'],
                'is_active' => isset($data['is_active']) ? intval($data['is_active']) : 1
            ];
            
            $result = $category->create($categoryData);
            if ($result) {
                Response::success(['id' => $result, 'message' => 'Category created successfully'], 201);
            } else {
                Response::error('Failed to create category', 500);
            }
            break;
            
        case 'PUT':
            if (!isset($_GET['id'])) {
                Response::error('Category ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            $data = $request->getBody();
            
            // Check if category exists
            $existing = $category->findById($id);
            if (!$existing) {
                Response::error('Category not found', 404);
                exit;
            }
            
            $categoryData = [];
            $allowedFields = ['division_id', 'name', 'description', 'is_active'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    if ($field === 'division_id' || $field === 'is_active') {
                        $categoryData[$field] = intval($data[$field]);
                    } else {
                        $categoryData[$field] = $data[$field];
                    }
                }
            }
            
            if (empty($categoryData)) {
                Response::error('No valid fields to update', 400);
                exit;
            }
            
            $result = $category->update($id, $categoryData);
            if ($result) {
                Response::success(['message' => 'Category updated successfully']);
            } else {
                Response::error('Failed to update category', 500);
            }
            break;
            
        case 'DELETE':
            if (!isset($_GET['id'])) {
                Response::error('Category ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            // Check if category exists
            $existing = $category->findById($id);
            if (!$existing) {
                Response::error('Category not found', 404);
                exit;
            }
            
            $result = $category->delete($id);
            if ($result) {
                Response::success(['message' => 'Category deleted successfully']);
            } else {
                Response::error('Failed to delete category', 500);
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