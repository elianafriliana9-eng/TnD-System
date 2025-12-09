<?php
/**
 * Visit Schedule Model
 */

class VisitSchedule {
    private $db;
    private $table = 'visit_schedules';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create new schedule
     */
    public function create($data) {
        $sql = "INSERT INTO {$this->table} 
                (outlet_id, user_id, template_id, scheduled_date, scheduled_time, recurrence, notes) 
                VALUES 
                (:outlet_id, :user_id, :template_id, :scheduled_date, :scheduled_time, :recurrence, :notes)";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':outlet_id', $data['outlet_id']);
        $stmt->bindParam(':user_id', $data['user_id']);
        $stmt->bindParam(':template_id', $data['template_id']);
        $stmt->bindParam(':scheduled_date', $data['scheduled_date']);
        $stmt->bindParam(':scheduled_time', $data['scheduled_time']);
        $stmt->bindParam(':recurrence', $data['recurrence']);
        $stmt->bindParam(':notes', $data['notes']);
        
        if ($stmt->execute()) {
            return $this->db->lastInsertId();
        }
        return false;
    }

    /**
     * Update schedule
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
     * Get schedules by user
     */
    public function findByUser($userId, $status = null) {
        $sql = "SELECT vs.*, 
                o.name AS outlet_name, o.address AS outlet_location,
                t.name AS template_name
                FROM {$this->table} vs
                LEFT JOIN outlets o ON vs.outlet_id = o.id
                LEFT JOIN checklist_templates t ON vs.template_id = t.id
                WHERE vs.user_id = :user_id";
        
        if ($status) {
            $sql .= " AND vs.status = :status";
        }
        
        $sql .= " ORDER BY vs.scheduled_date ASC, vs.scheduled_time ASC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        if ($status) {
            $stmt->bindParam(':status', $status);
        }
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get schedules by date range
     */
    public function findByDateRange($userId, $startDate, $endDate) {
        $sql = "SELECT vs.*, 
                o.name AS outlet_name, o.address AS outlet_location,
                t.name AS template_name
                FROM {$this->table} vs
                LEFT JOIN outlets o ON vs.outlet_id = o.id
                LEFT JOIN checklist_templates t ON vs.template_id = t.id
                WHERE vs.user_id = :user_id
                AND vs.scheduled_date BETWEEN :start_date AND :end_date
                ORDER BY vs.scheduled_date ASC, vs.scheduled_time ASC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Delete schedule
     */
    public function delete($id) {
        $sql = "DELETE FROM {$this->table} WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        return $stmt->execute();
    }
}
?>
