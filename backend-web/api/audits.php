<?php
/**
 * DEPRECATED FOR WEB USE - RE-ENABLED FOR REPORTING
 * This endpoint was previously mobile-only.
 * It has been re-enabled to allow the web application to access audit data for reporting purposes.
 */

// Return deprecation notice for web requests
// Response::error('Audit features are only available in mobile application', 410);
// exit;

require_once '../config/database.php';
require_once '../classes/Database.php';
require_once '../classes/BaseModel.php';
require_once '../classes/Audit.php';
require_once '../classes/AuditResult.php';
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
    exit(0);
}

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
$audit = new Audit();
$auditResult = new AuditResult();

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                // Get single audit with results
                $id = intval($_GET['id']);
                $auditData = $audit->findById($id);
                if ($auditData) {
                    // Get audit results
                    $results = $auditResult->findByAudit($id);
                    $auditData['results'] = $results;
                    Response::success($auditData);
                } else {
                    Response::error('Audit not found', 404);
                }
            } elseif (isset($_GET['outlet_id'])) {
                // Get audits by outlet
                $outletId = intval($_GET['outlet_id']);
                $audits = $audit->findByOutlet($outletId);
                Response::success(['data' => $audits]);
            } elseif (isset($_GET['findings'])) {
                // Get all audit findings
                $findings = $audit->getAuditFindings();
                Response::success(['data' => $findings]);
            } else {
                // Get all audits
                $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
                $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
                $search = isset($_GET['search']) ? $_GET['search'] : '';
                
                $audits = $audit->findAll($page, $limit, $search);
                $total = $audit->count($search);
                
                Response::success([
                    'data' => $audits,
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
            $required = ['outlet_id', 'audit_date'];
            foreach ($required as $field) {
                if (empty($data[$field])) {
                    Response::error("Field {$field} is required", 400);
                    exit;
                }
            }
            
            $currentUser = Auth::user();
            
            $auditData = [
                'outlet_id' => intval($data['outlet_id']),
                'auditor_id' => $currentUser['id'],
                'audit_date' => $data['audit_date'],
                'status' => isset($data['status']) ? $data['status'] : 'draft',
                'notes' => isset($data['notes']) ? $data['notes'] : ''
            ];
            
            $result = $audit->create($auditData);
            if ($result) {
                // Create audit results if provided
                if (isset($data['results']) && is_array($data['results'])) {
                    foreach ($data['results'] as $resultData) {
                        $auditResultData = [
                            'audit_id' => $result,
                            'checklist_point_id' => intval($resultData['checklist_point_id']),
                            'score' => floatval($resultData['score']),
                            'notes' => isset($resultData['notes']) ? $resultData['notes'] : '',
                            'nok_remarks' => isset($resultData['nok_remarks']) ? $resultData['nok_remarks'] : null
                        ];
                        $auditResult->create($auditResultData);
                    }
                }
                
                Response::success(['id' => $result, 'message' => 'Audit created successfully'], 201);
            } else {
                Response::error('Failed to create audit', 500);
            }
            break;
            
        case 'PUT':
            if (!isset($_GET['id'])) {
                Response::error('Audit ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            $data = $request->getBody();
            
            // Check if audit exists
            $existing = $audit->findById($id);
            if (!$existing) {
                Response::error('Audit not found', 404);
                exit;
            }
            
            $auditData = [];
            $allowedFields = ['outlet_id', 'audit_date', 'status', 'notes'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    if ($field === 'outlet_id') {
                        $auditData[$field] = intval($data[$field]);
                    } else {
                        $auditData[$field] = $data[$field];
                    }
                }
            }
            
            if (!empty($auditData)) {
                $result = $audit->update($id, $auditData);
                if (!$result) {
                    Response::error('Failed to update audit', 500);
                    exit;
                }
            }
            
            // Update audit results if provided
            if (isset($data['results']) && is_array($data['results'])) {
                // Delete existing results
                $auditResult->deleteByAudit($id);
                
                // Create new results
                foreach ($data['results'] as $resultData) {
                    $auditResultData = [
                        'audit_id' => $id,
                        'checklist_point_id' => intval($resultData['checklist_point_id']),
                        'score' => floatval($resultData['score']),
                        'notes' => isset($resultData['notes']) ? $resultData['notes'] : '',
                        'nok_remarks' => isset($resultData['nok_remarks']) ? $resultData['nok_remarks'] : null
                    ];
                    $auditResult->create($auditResultData);
                }
            }
            
            Response::success(['message' => 'Audit updated successfully']);
            break;
            
        case 'DELETE':
            if (!isset($_GET['id'])) {
                Response::error('Audit ID is required', 400);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            // Check if audit exists
            $existing = $audit->findById($id);
            if (!$existing) {
                Response::error('Audit not found', 404);
                exit;
            }
            
            // Delete audit results first
            $auditResult->deleteByAudit($id);
            
            // Delete audit
            $result = $audit->delete($id);
            if ($result) {
                Response::success(['message' => 'Audit deleted successfully']);
            } else {
                Response::error('Failed to delete audit', 500);
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