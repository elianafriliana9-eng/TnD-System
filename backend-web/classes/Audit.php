<?php
/**
 * Audit Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class Audit extends BaseModel {
    protected $table = 'audits';
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Create audit
     */
    public function createAudit($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->create($data);
    }
    
    /**
     * Update audit
     */
    public function updateAudit($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->update($id, $data);
    }
    
    /**
     * Get audits with outlet and user information
     */
    public function getAuditsWithDetails() {
        $sql = "SELECT a.*, o.name as outlet_name, o.address as outlet_address, 
                       u.full_name as user_name 
                FROM {$this->table} a 
                LEFT JOIN outlets o ON a.outlet_id = o.id 
                LEFT JOIN users u ON a.user_id = u.id 
                ORDER BY a.created_at DESC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }
    
    /**
     * Get audits by outlet
     */
    public function findByOutlet($outletId) {
        return $this->findWhere('outlet_id = :outlet_id ORDER BY created_at DESC', 
                               [':outlet_id' => $outletId]);
    }
    
    /**
     * Get audits by user
     */
    public function findByUser($userId) {
        return $this->findWhere('user_id = :user_id ORDER BY created_at DESC', 
                               [':user_id' => $userId]);
    }
    
    /**
     * Get audits by status
     */
    public function findByStatus($status) {
        return $this->findWhere('status = :status ORDER BY created_at DESC', 
                               [':status' => $status]);
    }
    
    /**
     * Get audits by date range
     */
    public function findByDateRange($startDate, $endDate) {
        return $this->findWhere(
            'audit_date BETWEEN :start_date AND :end_date ORDER BY audit_date DESC',
            [':start_date' => $startDate, ':end_date' => $endDate]
        );
    }
    
    /**
     * Get audit statistics
     */
    public function getAuditStatistics() {
        $sql = "SELECT 
                    COUNT(*) as total_audits,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_audits,
                    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_audits,
                    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_audits,
                    AVG(score) as average_score
                FROM {$this->table}";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetch();
    }
    
    /**
     * Complete audit
     */
    public function completeAudit($id, $score, $notes = null) {
        return $this->update($id, [
            'status' => 'completed',
            'score' => $score,
            'notes' => $notes,
            'completed_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s')
        ]);
    }

    public function getAuditFindings() {
        $sql = "SELECT 
                    ar.id as finding_id,
                    a.id as audit_id,
                    o.id as outlet_id,
                    o.name as outlet_name,
                    cp.id as checklist_point_id,
                    cp.question as checklist_point_question,
                    a.audit_date
                FROM audit_results ar
                JOIN audits a ON ar.audit_id = a.id
                JOIN outlets o ON a.outlet_id = o.id
                JOIN checklist_points cp ON ar.checklist_point_id = cp.id
                WHERE ar.score = 0
                ORDER BY o.id, cp.id, a.audit_date";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}