<?php
/**
 * Divisi Model Class
 * TND System - PHP Native Version
 */
require_once __DIR__ . '/ChecklistPoint.php';

class Divisi extends BaseModel {
    
    protected $table = 'divisions';
    protected $fillable = ['name', 'description', 'status'];
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Get all categories for this division
     */
    public function getCategories($divisionId) {
        $sql = "SELECT * FROM checklist_categories WHERE division_id = ? AND is_active = 1 ORDER BY name ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$divisionId]);
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $checklistPoint = new ChecklistPoint();
        foreach ($categories as &$category) {
            $category['points'] = $checklistPoint->findByCategory($category['id']);
        }

        return $categories;
    }
    
    /**
     * Get all outlets for this division
     */
    public function getOutlets($divisionId) {
        $sql = "SELECT * FROM outlets WHERE division_id = ? AND status = 'active' ORDER BY name ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$divisionId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Get division with categories and outlets count
     */
    public function findWithCounts($page = 1, $limit = 10, $search = '') {
        $offset = ($page - 1) * $limit;
        $searchCondition = $search ? "WHERE d.name LIKE ? OR d.description LIKE ?" : "";
        
        $sql = "SELECT d.*, 
                       COUNT(DISTINCT c.id) as categories_count,
                       COUNT(DISTINCT o.id) as outlets_count
                FROM {$this->table} d 
                LEFT JOIN checklist_categories c ON d.id = c.division_id
                LEFT JOIN outlets o ON d.id = o.division_id AND o.status = 'active'
                {$searchCondition}
                GROUP BY d.id
                ORDER BY d.name ASC 
                LIMIT {$limit} OFFSET {$offset}";
        
        $stmt = $this->db->prepare($sql);
        
        if ($search) {
            $searchTerm = "%{$search}%";
            $stmt->execute([$searchTerm, $searchTerm]);
        } else {
            $stmt->execute();
        }
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function findAllSimple() {
        $sql = "SELECT id, name FROM {$this->table} WHERE status = 'active' ORDER BY FIELD(LOWER(name), 'minimarket', 'wrapping', 'cellular', 'fnb', 'reflexology')";
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Validate division data
     */
    public function validate($data, $id = null) {
        $errors = [];
        
        // Required fields
        if (empty($data['name'])) {
            $errors[] = 'Division name is required';
        }
        
        if (empty($data['description'])) {
            $errors[] = 'Division description is required';
        }
        
        // Check unique name
        $existingCondition = $id ? "AND id != {$id}" : "";
        $sql = "SELECT COUNT(*) FROM {$this->table} WHERE name = ? {$existingCondition}";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$data['name']]);
        
        if ($stmt->fetchColumn() > 0) {
            $errors[] = 'Division name already exists';
        }
        
        return $errors;
    }
}
?>