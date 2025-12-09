-- Show all tables in database
SHOW TABLES;

-- Get table info
SELECT TABLE_NAME, TABLE_TYPE, ENGINE, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'tnd_db'
ORDER BY TABLE_NAME;

-- Describe each training-related table
SHOW COLUMNS FROM training_categories;
SHOW COLUMNS FROM training_items;
