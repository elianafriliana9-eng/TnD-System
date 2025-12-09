-- Check table structure and relationships

-- Show training_checklist structure
DESCRIBE training_checklist;

-- Show training_categories structure  
DESCRIBE training_categories;

-- Show training_items structure
DESCRIBE training_items;

-- Check if training_categories has checklist_id foreign key
SELECT COLUMN_NAME, COLUMN_KEY, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME IN ('training_checklist', 'training_categories', 'training_items');

-- Show data relationships
SELECT 'Checklist Data' as section;
SELECT * FROM training_checklist;

SELECT 'Categories with Checklist Info' as section;
SELECT tc.* FROM training_categories tc
LEFT JOIN training_checklist tch ON tc.checklist_id = tch.id
LIMIT 20;

SELECT 'Items with Category Info' as section;
SELECT ti.id, ti.category_id, ti.question, tc.name as category_name
FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
LIMIT 20;
