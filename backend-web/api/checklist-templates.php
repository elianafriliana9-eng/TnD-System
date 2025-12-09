<?php
/**
 * Checklist Templates API
 * Get available checklist templates
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../classes/ChecklistTemplate.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    // Check authentication
    if (!Auth::check()) {
        Response::error('Authentication required', 401);
    }

    $templateModel = new ChecklistTemplate();
    $user = Auth::user();

    // Get template with items if ID provided
    if (isset($_GET['id'])) {
        $template = $templateModel->getTemplateWithItems($_GET['id']);
        if (!$template) {
            Response::error('Template not found', 404);
        }
        Response::success($template);
    }

    // Get templates by division or all
    if (isset($user['division_id']) && $user['division_id']) {
        $templates = $templateModel->findByDivision($user['division_id']);
    } else {
        $templates = $templateModel->findAll();
    }

    Response::success($templates);
} catch (Exception $e) {
    Response::error('Error: ' . $e->getMessage(), 500);
}
?>
