<?php
/**
 * ChecklistPoint Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class ChecklistPoint extends BaseModel {
    protected $table = 'checklist_points';
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Create point
     */
    public function createPoint($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->create($data);
    }
    
    /**
     * Update point
     */
    public function updatePoint($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->update($id, $data);
    }
    
    /**
     * Get points by category
     */
    public function findByCategory($categoryId) {
        return $this->findWhere('category_id = :category_id ORDER BY sort_order, question', 
                               [':category_id' => $categoryId]);
    }
    
    /**
     * Get points with category information
     */
    public function getPointsWithCategory() {
        $sql = "SELECT cp.*, cc.name as category_name 
                FROM {$this->table} cp 
                LEFT JOIN checklist_categories cc ON cp.category_id = cc.id 
                ORDER BY cc.sort_order, cp.sort_order, cp.question";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }
    
    /**
     * Get active points
     */
    public function getActivePoints() {
        return $this->findWhere('is_active = :is_active', [':is_active' => 1]);
    }
    
    /**
     * Get active points by category
     */
    public function getActivePointsByCategory($categoryId) {
        return $this->findWhere(
            'category_id = :category_id AND is_active = :is_active ORDER BY sort_order',
            [':category_id' => $categoryId, ':is_active' => 1]
        );
    }
    
    /**
     * Search points
     */
    public function searchPoints($search) {
        $search = "%{$search}%";
        return $this->findWhere(
            'question LIKE :search OR description LIKE :search',
            [':search' => $search]
        );
    }
    
    /**
     * Update sort order
     */
    public function updateSortOrder($id, $sortOrder) {
        return $this->update($id, [
            'sort_order' => $sortOrder,
            'updated_at' => date('Y-m-d H:i:s')
        ]);
    }
}