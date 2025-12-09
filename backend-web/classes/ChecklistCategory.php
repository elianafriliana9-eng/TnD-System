<?php
/**
 * ChecklistCategory Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class ChecklistCategory extends BaseModel {
    protected $table = 'checklist_categories';
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Create category
     */
    public function createCategory($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->create($data);
    }
    
    /**
     * Update category
     */
    public function updateCategory($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->update($id, $data);
    }
    
    /**
     * Get categories with points count
     */
    public function getCategoriesWithPointsCount() {
        $sql = "SELECT c.*, COUNT(cp.id) as points_count 
                FROM {$this->table} c 
                LEFT JOIN checklist_points cp ON c.id = cp.category_id 
                GROUP BY c.id 
                ORDER BY c.sort_order, c.name";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }
    
    /**
     * Get active categories
     */
    public function getActiveCategories() {
        return $this->findWhere('is_active = :is_active', [':is_active' => 1]);
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