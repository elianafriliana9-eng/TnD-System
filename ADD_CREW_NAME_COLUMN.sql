-- Add crew_name column to training_sessions table
-- Nama crew yang sedang ditraining (per-person training)

-- Check if column already exists
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'training_sessions'
AND COLUMN_NAME = 'crew_name';

-- Add column only if it doesn't exist
SET @query = IF(@col_exists = 0,
    'ALTER TABLE training_sessions ADD COLUMN crew_name VARCHAR(255) NULL',
    'SELECT "Column crew_name already exists" AS message'
);

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
