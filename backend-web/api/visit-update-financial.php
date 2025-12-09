<?php
/**
 * Visit Update Financial & Assessment Data API
 * Update financial and assessment fields for a visit
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../classes/Database.php';
require_once __DIR__ . '/../classes/Visit.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Headers.php';

// Handle preflight and set headers
Headers::setAPIHeaders();

// Start session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!Auth::checkAuth()) {
    Response::unauthorized('Authentication required');
}

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['visit_id'])) {
        Response::error('Visit ID is required', 400);
    }
    
    $visitId = intval($input['visit_id']);
    
    // Build update data array
    $updateData = [];
    
    // Financial fields (optional)
    if (isset($input['uang_omset_modal'])) {
        $updateData['uang_omset_modal'] = floatval($input['uang_omset_modal']);
    }
    if (isset($input['uang_ditukar'])) {
        $updateData['uang_ditukar'] = floatval($input['uang_ditukar']);
    }
    if (isset($input['cash'])) {
        $updateData['cash'] = floatval($input['cash']);
    }
    if (isset($input['qris'])) {
        $updateData['qris'] = floatval($input['qris']);
    }
    if (isset($input['debit_kredit'])) {
        $updateData['debit_kredit'] = floatval($input['debit_kredit']);
    }
    
    // Calculate total automatically
    if (isset($input['uang_omset_modal']) || isset($input['uang_ditukar']) || 
        isset($input['cash']) || isset($input['qris']) || isset($input['debit_kredit'])) {
        
        $total = 0;
        $total += isset($updateData['uang_omset_modal']) ? $updateData['uang_omset_modal'] : 0;
        $total += isset($updateData['uang_ditukar']) ? $updateData['uang_ditukar'] : 0;
        $total += isset($updateData['cash']) ? $updateData['cash'] : 0;
        $total += isset($updateData['qris']) ? $updateData['qris'] : 0;
        $total += isset($updateData['debit_kredit']) ? $updateData['debit_kredit'] : 0;
        
        $updateData['total'] = $total;
    }
    
    // Assessment fields (optional)
    if (isset($input['kategoric'])) {
        // Validate enum value
        $validKategoric = ['minor', 'major', 'ZT'];
        if (!in_array($input['kategoric'], $validKategoric)) {
            Response::error('Invalid kategoric value. Must be: minor, major, or ZT', 400);
        }
        $updateData['kategoric'] = $input['kategoric'];
    }
    
    if (isset($input['leadtime'])) {
        $updateData['leadtime'] = intval($input['leadtime']);
    }
    
    if (isset($input['status_keuangan'])) {
        // Validate enum value
        $validStatus = ['open', 'close'];
        if (!in_array($input['status_keuangan'], $validStatus)) {
            Response::error('Invalid status_keuangan value. Must be: open or close', 400);
        }
        $updateData['status_keuangan'] = $input['status_keuangan'];
    }
    
    if (isset($input['crew_in_charge'])) {
        $updateData['crew_in_charge'] = trim($input['crew_in_charge']);
    }
    
    // Check if there's anything to update
    if (empty($updateData)) {
        Response::error('No data to update', 400);
    }
    
    // Update visit
    $visit = new Visit();
    $result = $visit->update($visitId, $updateData);
    
    if ($result) {
        // Get updated visit data
        $updatedVisit = $visit->findById($visitId);
        
        Response::success([
            'message' => 'Financial and assessment data updated successfully',
            'visit_id' => $visitId,
            'updated_fields' => array_keys($updateData),
            'visit' => $updatedVisit
        ]);
    } else {
        Response::error('Failed to update visit data', 500);
    }
    
} catch (PDOException $e) {
    error_log("Database error in visit-update-financial.php: " . $e->getMessage());
    Response::error('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    error_log("Error in visit-update-financial.php: " . $e->getMessage());
    Response::error('Server error: ' . $e->getMessage(), 500);
}
?>
