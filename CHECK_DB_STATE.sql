-- Check current database state
SELECT 'Categories' as type, COUNT(*) as count FROM training_categories
UNION
SELECT 'Training Items' as type, COUNT(*) as count FROM training_items
UNION
SELECT 'Training Points' as type, COUNT(*) as count FROM training_points;

-- List all categories
SELECT id, name FROM training_categories ORDER BY id;

-- List all items with their category_id (check if they exist)
SELECT 'training_items' as table_name, ti.id, ti.category_id, ti.question,
       IF(tc.id IS NULL, 'ORPHANED', 'OK') as status
FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
ORDER BY ti.category_id;

-- List all points with their category_id (check if they exist)
SELECT 'training_points' as table_name, tp.id, tp.category_id, tp.question,
       IF(tc.id IS NULL, 'ORPHANED', 'OK') as status
FROM training_points tp
LEFT JOIN training_categories tc ON tp.category_id = tc.id
ORDER BY tp.category_id;

-- Show category_id values that don't exist
SELECT DISTINCT ti.category_id FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
WHERE tc.id IS NULL
UNION
SELECT DISTINCT tp.category_id FROM training_points tp
LEFT JOIN training_categories tc ON tp.category_id = tc.id
WHERE tc.id IS NULL;
