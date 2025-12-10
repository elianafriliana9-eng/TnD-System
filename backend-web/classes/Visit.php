<?php
/**
 * Visit Model
 */

class Visit {
    private $db;
    private $table = 'visits';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create new visit
     */
    public function create($data) {
        $sql = "INSERT INTO {$this->table} 
                (outlet_id, user_id, visit_date, check_in_time, status, notes, crew_in_charge) 
                VALUES 
                (:outlet_id, :user_id, :visit_date, :check_in_time, :status, :notes, :crew_in_charge)";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':outlet_id', $data['outlet_id']);
        $stmt->bindParam(':user_id', $data['user_id']);
        $stmt->bindParam(':visit_date', $data['visit_date']);
        
        // Set check_in_time to current time
        $checkInTime = date('H:i:s');
        $stmt->bindParam(':check_in_time', $checkInTime);
        
        $stmt->bindParam(':status', $data['status']);
        $stmt->bindParam(':notes', $data['notes']);
        
        // Bind crew_in_charge (can be NULL)
        $crewInCharge = $data['crew_in_charge'] ?? null;
        $stmt->bindParam(':crew_in_charge', $crewInCharge);
        
        if ($stmt->execute()) {
            return $this->db->lastInsertId();
        }
        return false;
    }

    /**
     * Update visit
     */
    public function update($id, $data) {
        $sql = "UPDATE {$this->table} SET ";
        $fields = [];
        $params = [':id' => $id];

        foreach ($data as $key => $value) {
            $fields[] = "{$key} = :{$key}";
            $params[":{$key}"] = $value;
        }

        $sql .= implode(', ', $fields) . " WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        
        return $stmt->execute($params);
    }

    /**
     * Get visit by ID
     */
    public function findById($id) {
        $sql = "SELECT v.*, 
                o.name AS outlet_name, o.address AS outlet_location,
                u.full_name AS user_name,
                v.uang_omset_modal,
                v.uang_ditukar,
                v.cash,
                v.qris,
                v.debit_kredit,
                v.total,
                v.kategoric,
                v.leadtime,
                v.status_keuangan,
                v.crew_in_charge
                FROM {$this->table} v
                LEFT JOIN outlets o ON v.outlet_id = o.id
                LEFT JOIN users u ON v.user_id = u.id
                WHERE v.id = :id";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Get visits by user
     */
    public function findByUser($userId, $limit = 100) {
        $sql = "SELECT v.*, 
                o.name AS outlet_name, o.address AS outlet_location,
                u.full_name AS user_name,
                v.uang_omset_modal,
                v.uang_ditukar,
                v.cash,
                v.qris,
                v.debit_kredit,
                v.total,
                v.kategoric,
                v.leadtime,
                v.status_keuangan,
                v.crew_in_charge
                FROM {$this->table} v
                LEFT JOIN outlets o ON v.outlet_id = o.id
                LEFT JOIN users u ON v.user_id = u.id
                WHERE v.user_id = :user_id
                ORDER BY v.visit_date DESC
                LIMIT :limit";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get visits by outlet
     */
    public function findByOutlet($outletId, $limit = 50) {
        $sql = "SELECT v.*, 
                u.full_name AS user_name,
                v.uang_omset_modal,
                v.uang_ditukar,
                v.cash,
                v.qris,
                v.debit_kredit,
                v.total,
                v.kategoric,
                v.leadtime,
                v.status_keuangan,
                v.crew_in_charge
                FROM {$this->table} v
                LEFT JOIN users u ON v.user_id = u.id
                WHERE v.outlet_id = :outlet_id
                ORDER BY v.visit_date DESC
                LIMIT :limit";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':outlet_id', $outletId);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get visit with full details (checklist responses and photos)
     */
    public function getVisitDetails($visitId) {
        $visit = $this->findById($visitId);
        if (!$visit) {
            return null;
        }

        // Get checklist responses with grouped photos
        $sql = "SELECT vcr.*, 
                       cp.question as item_text, 
                       vcr.nok_remarks,
                       GROUP_CONCAT(p.file_path ORDER BY p.uploaded_at ASC SEPARATOR '|||') as photo_urls
                FROM visit_checklist_responses vcr
                LEFT JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
                LEFT JOIN photos p ON p.visit_id = vcr.visit_id AND p.item_id = vcr.checklist_point_id
                WHERE vcr.visit_id = :visit_id
                GROUP BY vcr.id, vcr.visit_id, vcr.checklist_point_id, vcr.response, vcr.notes, vcr.nok_remarks, cp.question
                ORDER BY cp.sort_order ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':visit_id', $visitId);
        $stmt->execute();
        $responses = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Split photo_urls string into array
        foreach ($responses as &$response) {
            if (!empty($response['photo_urls'])) {
                $response['photo_urls'] = explode('|||', $response['photo_urls']);
            } else {
                $response['photo_urls'] = [];
            }
        }
        $visit['responses'] = $responses;

        // Get photos separately for backward compatibility
        $sql = "SELECT p.id, p.visit_id, 
                       p.item_id as checklist_item_id, 
                       p.file_path as photo_path, 
                       p.caption as description,
                       p.uploaded_at,
                       cp.question as item_text 
                FROM photos p
                LEFT JOIN checklist_points cp ON p.item_id = cp.id
                WHERE p.visit_id = :visit_id
                ORDER BY p.uploaded_at ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':visit_id', $visitId);
        $stmt->execute();
        $visit['photos'] = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $visit;
    }

    /**
     * Save checklist response
     */
    public function saveChecklistResponse($data) {
        try {
            // Map checklist_item_id (from mobile) → checklist_point_id (in database)
            $checklistPointId = $data['checklist_item_id'];
            
            // CRITICAL FIX: Delete photos when response changes from NOT OK to OK or N/A
            // This prevents orphaned photos from showing on OK/NA items
            if ($data['response'] === 'OK' || $data['response'] === 'N/A') {
                // Check if there's an existing response that was NOT OK
                $checkSql = "SELECT response FROM visit_checklist_responses 
                            WHERE visit_id = :visit_id AND checklist_point_id = :checklist_point_id";
                $checkStmt = $this->db->prepare($checkSql);
                $checkStmt->bindParam(':visit_id', $data['visit_id']);
                $checkStmt->bindParam(':checklist_point_id', $checklistPointId);
                $checkStmt->execute();
                $existingResponse = $checkStmt->fetch(PDO::FETCH_ASSOC);
                
                // If changing from NOT OK to OK/NA, delete associated photos
                if ($existingResponse && $existingResponse['response'] === 'NOT OK') {
                    error_log('Response changed from NOT OK to ' . $data['response'] . ' - deleting photos');
                    
                    // Get photo paths for deletion from filesystem
                    $photoSql = "SELECT file_path FROM photos 
                                WHERE visit_id = :visit_id AND item_id = :item_id";
                    $photoStmt = $this->db->prepare($photoSql);
                    $photoStmt->bindParam(':visit_id', $data['visit_id']);
                    $photoStmt->bindParam(':item_id', $checklistPointId);
                    $photoStmt->execute();
                    $photos = $photoStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    // Delete from database
                    $deleteSql = "DELETE FROM photos 
                                 WHERE visit_id = :visit_id AND item_id = :item_id";
                    $deleteStmt = $this->db->prepare($deleteSql);
                    $deleteStmt->bindParam(':visit_id', $data['visit_id']);
                    $deleteStmt->bindParam(':item_id', $checklistPointId);
                    $deleteStmt->execute();
                    
                    // Delete from filesystem
                    foreach ($photos as $photo) {
                        $filePath = '../' . $photo['file_path'];
                        if (file_exists($filePath)) {
                            unlink($filePath);
                            error_log('Deleted photo file: ' . $filePath);
                        }
                    }
                    
                    error_log('Deleted ' . count($photos) . ' photos for item ' . $checklistPointId);
                }
            }
            
            // Production table: visit_checklist_responses
            // Production column: checklist_point_id (not checklist_item_id)
            $sql = "INSERT INTO visit_checklist_responses 
                    (visit_id, checklist_point_id, response, notes, nok_remarks) 
                    VALUES 
                    (:visit_id, :checklist_point_id, :response, :notes, :nok_remarks)
                    ON DUPLICATE KEY UPDATE 
                    response = VALUES(response), 
                    notes = VALUES(notes), 
                    nok_remarks = VALUES(nok_remarks)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':visit_id', $data['visit_id']);
            $stmt->bindParam(':checklist_point_id', $checklistPointId);
            $stmt->bindParam(':response', $data['response']);
            $stmt->bindParam(':notes', $data['notes']);
            $stmt->bindParam(':nok_remarks', $data['nok_remarks']);
            
            if ($stmt->execute()) {
                error_log('Checklist response saved successfully for visit_id: ' . $data['visit_id'] . ', checklist_point_id: ' . $checklistPointId);
                return true;
            }
            
            // Log PDO error
            $errorInfo = $stmt->errorInfo();
            error_log('CRITICAL: Failed to save checklist response to database');
            error_log('SQL State: ' . $errorInfo[0]);
            error_log('Error Code: ' . $errorInfo[1]);
            error_log('Error Message: ' . $errorInfo[2]);
            error_log('Data: ' . json_encode($data));
            
            return false;
        } catch (Exception $e) {
            error_log('EXCEPTION in saveChecklistResponse: ' . $e->getMessage());
            error_log('Trace: ' . $e->getTraceAsString());
            return false;
        }
    }

    /**
     * Save visit photo
     */
    public function savePhoto($data) {
        try {
            // Production table: photos (not visit_photos)
            // Production columns: item_id, file_path, file_name, file_size, mime_type, caption
            $sql = "INSERT INTO photos 
                    (visit_id, item_id, file_path, file_name, file_size, mime_type, caption) 
                    VALUES 
                    (:visit_id, :item_id, :file_path, :file_name, :file_size, :mime_type, :caption)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':visit_id', $data['visit_id']);
            
            // CRITICAL: item_id has foreign key to 'items' table, but we need to store checklist_point_id
            // Try to save checklist_item_id first, if FK fails, save as NULL
            $itemId = $data['checklist_item_id'] ?? null;
            $stmt->bindParam(':item_id', $itemId);
            
            // Map photo_path → file_path
            $stmt->bindParam(':file_path', $data['photo_path']);
            
            // Extract file_name from photo_path
            $fileName = isset($data['photo_path']) ? basename($data['photo_path']) : '';
            $stmt->bindParam(':file_name', $fileName);
            
            // file_size and mime_type (optional, can be null)
            $fileSize = $data['file_size'] ?? null;
            $mimeType = $data['mime_type'] ?? null;
            $stmt->bindParam(':file_size', $fileSize);
            $stmt->bindParam(':mime_type', $mimeType);
            
            // Map description → caption
            $caption = $data['description'] ?? null;
            $stmt->bindParam(':caption', $caption);
            
            if ($stmt->execute()) {
                $insertId = $this->db->lastInsertId();
                error_log('Visit photo saved successfully with ID: ' . $insertId);
                return $insertId;
            }
            
            // Log PDO error
            $errorInfo = $stmt->errorInfo();
            error_log('CRITICAL: Failed to save visit photo to database');
            error_log('SQL State: ' . $errorInfo[0]);
            error_log('Error Code: ' . $errorInfo[1]);
            error_log('Error Message: ' . $errorInfo[2]);
            error_log('Data: ' . json_encode($data));
            
            return false;
        } catch (Exception $e) {
            error_log('EXCEPTION in savePhoto: ' . $e->getMessage());
            error_log('Trace: ' . $e->getTraceAsString());
            return false;
        }
    }
}
?>
