<?php
/**
 * AuditResult Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class AuditResult extends BaseModel {
    protected $table = 'audit_results';
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Create audit result
     */
    public function createResult($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->create($data);
    }
    
    /**
     * Update audit result
     */
    public function updateResult($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->update($id, $data);
    }
    
    /**
     * Get results by audit
     */
    public function findByAudit($auditId) {
        return $this->findWhere('audit_id = :audit_id', [':audit_id' => $auditId]);
    }
    
    /**
     * Get results with checklist point information
     */
    public function getResultsWithPoints($auditId) {
        $sql = "SELECT ar.*, cp.question, cp.description as point_description,
                       cc.name as category_name, cp.max_score
                FROM {$this->table} ar 
                LEFT JOIN checklist_points cp ON ar.checklist_point_id = cp.id 
                LEFT JOIN checklist_categories cc ON cp.category_id = cc.id 
                WHERE ar.audit_id = :audit_id 
                ORDER BY cc.sort_order, cp.sort_order";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':audit_id', $auditId);
        $stmt->execute();
        $results = $stmt->fetchAll();
        
        // Ensure nok_remarks is included in result
        foreach ($results as &$result) {
            if (!isset($result['nok_remarks'])) {
                $result['nok_remarks'] = null;
            }
        }
        
        return $results;
    }
    
    /**
     * Get results grouped by category
     */
    public function getResultsByCategory($auditId) {
        $sql = "SELECT cc.id as category_id, cc.name as category_name,
                       ar.*, cp.question, cp.max_score
                FROM {$this->table} ar 
                LEFT JOIN checklist_points cp ON ar.checklist_point_id = cp.id 
                LEFT JOIN checklist_categories cc ON cp.category_id = cc.id 
                WHERE ar.audit_id = :audit_id 
                ORDER BY cc.sort_order, cp.sort_order";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':audit_id', $auditId);
        $stmt->execute();
        $results = $stmt->fetchAll();
        
        // Group by category
        $grouped = [];
        foreach ($results as $result) {
            $categoryId = $result['category_id'];
            if (!isset($grouped[$categoryId])) {
                $grouped[$categoryId] = [
                    'category_name' => $result['category_name'],
                    'results' => []
                ];
            }
            // Ensure nok_remarks is included
            if (!isset($result['nok_remarks'])) {
                $result['nok_remarks'] = null;
            }
            $grouped[$categoryId]['results'][] = $result;
        }
        
        return $grouped;
    }
    
    /**
     * Calculate audit score
     */
    public function calculateAuditScore($auditId) {
        $sql = "SELECT 
                    SUM(ar.score) as total_score,
                    SUM(cp.max_score) as max_possible_score,
                    COUNT(*) as total_points
                FROM {$this->table} ar 
                LEFT JOIN checklist_points cp ON ar.checklist_point_id = cp.id 
                WHERE ar.audit_id = :audit_id";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':audit_id', $auditId);
        $stmt->execute();
        return $stmt->fetch();
    }
    
    /**
     * Bulk create audit results
     */
    public function createBulkResults($results) {
        $this->db->beginTransaction();
        
        try {
            foreach ($results as $result) {
                $this->createResult($result);
            }
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            return false;
        }
    }
    
    /**
     * Delete results by audit
     */
    public function deleteByAudit($auditId) {
        $sql = "DELETE FROM {$this->table} WHERE audit_id = :audit_id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':audit_id', $auditId);
        return $stmt->execute();
    }
}