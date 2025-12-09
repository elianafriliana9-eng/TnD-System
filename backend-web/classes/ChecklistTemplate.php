<?php
/**
 * Checklist Template Model
 */

class ChecklistTemplate {
    private $db;
    private $table = 'checklist_templates';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Get all active checklist templates
     */
    public function findAll($orderBy = 'name ASC') {
        $sql = "SELECT * FROM {$this->table} WHERE is_active = 1 ORDER BY {$orderBy}";
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get template by ID
     */
    public function findById($id) {
        $sql = "SELECT * FROM {$this->table} WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Get templates by division
     */
    public function findByDivision($divisionId) {
        $sql = "SELECT * FROM {$this->table} 
                WHERE (division_id = :division_id OR division_id IS NULL) 
                AND is_active = 1 
                ORDER BY name ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':division_id', $divisionId);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get template with items
     */
    public function getTemplateWithItems($id) {
        $template = $this->findById($id);
        if (!$template) {
            return null;
        }

        $sql = "SELECT * FROM checklist_items WHERE template_id = :template_id ORDER BY category, item_order ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':template_id', $id);
        $stmt->execute();
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $template['items'] = $items;
        
        // Group items by category
        $groupedItems = [];
        foreach ($items as $item) {
            $category = $item['category'] ?? 'Uncategorized';
            if (!isset($groupedItems[$category])) {
                $groupedItems[$category] = [];
            }
            $groupedItems[$category][] = $item;
        }
        $template['items_grouped'] = $groupedItems;
        
        return $template;
    }
}
?>
