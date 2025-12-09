-- Create training_signatures table
-- Table untuk menyimpan tanda tangan digital (staff, leader, trainer)

CREATE TABLE IF NOT EXISTS training_signatures (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    signature_type ENUM('staff', 'leader', 'trainer') NOT NULL,
    signer_name VARCHAR(255) NOT NULL,
    signer_position VARCHAR(255),
    signature_data TEXT COMMENT 'Base64 signature image',
    signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES training_sessions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_session_signature (session_id, signature_type),
    INDEX idx_session_id (session_id),
    INDEX idx_signature_type (signature_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
