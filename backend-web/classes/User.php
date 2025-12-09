<?php
/**
 * User Model
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/BaseModel.php';

class User extends BaseModel {
    protected $table = 'users';
    
    public function __construct() {
        parent::__construct();
    }
    
    /**
     * Authenticate user
     */
    public function authenticate($email, $password) {
        $sql = "SELECT u.*, d.name as division_name 
                FROM {$this->table} u 
                LEFT JOIN divisions d ON u.division_id = d.id 
                WHERE u.email = :email";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        if ($user && password_verify($password, $user['password'])) {
            // Remove password from returned data
            unset($user['password']);
            return $user;
        }
        
        return false;
    }
    
    /**
     * Find user by ID with division info
     */
    public function findById($id) {
        $sql = "SELECT u.*, d.name as division_name 
                FROM {$this->table} u 
                LEFT JOIN divisions d ON u.division_id = d.id 
                WHERE u.id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        if ($user) {
            // Remove password from returned data
            unset($user['password']);
            return $user;
        }
        
        return false;
    }
    
    /**
     * Create user with hashed password
     */
    public function createUser($data) {
        if (isset($data['password'])) {
            $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
        }
        
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->create($data);
    }
    
    /**
     * Update user password
     */
    public function updatePassword($userId, $newPassword) {
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        return $this->update($userId, [
            'password' => $hashedPassword,
            'updated_at' => date('Y-m-d H:i:s')
        ]);
    }
    
    /**
     * Verify user password
     */
    public function verifyPassword($userId, $password) {
        $sql = "SELECT password FROM {$this->table} WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $userId);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        if ($user) {
            return password_verify($password, $user['password']);
        }
        
        return false;
    }
    
    /**
     * Find user by email
     */
    public function findByEmail($email) {
        $sql = "SELECT * FROM {$this->table} WHERE email = :email";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        return $stmt->fetch();
    }
    
    /**
     * Get users by role
     */
    public function findByRole($role) {
        return $this->findWhere('role = :role', [':role' => $role]);
    }
    
    /**
     * Update user data (without password)
     */
    public function updateUser($id, $data) {
        // Remove password from data if present
        unset($data['password']);
        $data['updated_at'] = date('Y-m-d H:i:s');
        
        return $this->update($id, $data);
    }
}