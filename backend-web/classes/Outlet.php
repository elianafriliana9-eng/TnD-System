<?php
/**
 * Outlet Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class Outlet extends BaseModel {
    protected $table = 'outlets';

    public function __construct() {
        parent::__construct();
    }

    /**
     * Find all outlets with division name (for listing)
     */
    public function findAllWithDivision($page = 1, $limit = 10, $search = '', $divisionId = null) {
        $offset = ($page - 1) * $limit;
        $where = '';
        $params = [];
        
        // Priority: parameter divisionId, then $_GET
        if ($divisionId !== null) {
            $where = 'WHERE o.division_id = :division_id';
            $params[':division_id'] = (int)$divisionId;
        } elseif (isset($_GET['division_id']) && $_GET['division_id'] !== '') {
            $where = 'WHERE o.division_id = :division_id';
            $params[':division_id'] = (int)$_GET['division_id'];
        }
        
        $sql = "SELECT o.*, d.name AS division_name FROM outlets o LEFT JOIN divisions d ON o.division_id = d.id $where ORDER BY o.id DESC LIMIT :limit OFFSET :offset";
        $stmt = $this->db->prepare($sql);
        if ($where) {
            $stmt->bindValue(':division_id', $params[':division_id'], \PDO::PARAM_INT);
        }
        $stmt->bindValue(':limit', (int)$limit, \PDO::PARAM_INT);
        $stmt->bindValue(':offset', (int)$offset, \PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /**
     * Reset auto increment if table is empty
     */
    public function resetAutoIncrementIfEmpty() {
        $sql = "SELECT COUNT(*) as cnt FROM outlets";
        $stmt = $this->db->query($sql);
        $row = $stmt->fetch();
        if ($row && $row['cnt'] == 0) {
            // MySQL: reset auto increment
            $this->db->exec("ALTER TABLE outlets AUTO_INCREMENT = 1");
        } else {
            // Jika ada data, urutkan ulang ID (DANGEROUS, hanya jika benar-benar ingin reindex)
            // Nonaktifkan jika tidak ingin merubah ID existing
            // $this->reindexOutletIds();
        }
    }

    // Optional: fungsi reindex id (tidak direkomendasikan di production, hanya untuk development/testing)
    // public function reindexOutletIds() {
    //     $this->db->exec('SET @num := 0');
    //     $this->db->exec('UPDATE outlets SET id = (@num := @num + 1) ORDER BY id');
    //     $this->db->exec('ALTER TABLE outlets AUTO_INCREMENT = 1');
    // }
    
    /**
     * Create outlet
     */
    public function createOutlet($data) {
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->create($data);
    }
    
    /**
     * Update outlet
     */
    public function updateOutlet($id, $data) {
        $data['updated_at'] = date('Y-m-d H:i:s');
        return $this->update($id, $data);
    }
    
    /**
     * Get outlets by region
     */
    public function findByRegion($region) {
        return $this->findWhere('region = :region', [':region' => $region]);
    }
    
    /**
     * Get outlets by status
     */
    public function findByStatus($status) {
        return $this->findWhere('status = :status', [':status' => $status]);
    }
    
    /**
     * Get outlets with user information
     */
    public function getOutletsWithUsers() {
        $sql = "SELECT o.*, u.full_name as user_name, u.email as user_email 
                FROM {$this->table} o 
                LEFT JOIN users u ON o.user_id = u.id 
                ORDER BY o.name";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }
    
    /**
     * Search outlets
     */
    public function searchOutlets($search) {
        // Search feature removed
    }
}