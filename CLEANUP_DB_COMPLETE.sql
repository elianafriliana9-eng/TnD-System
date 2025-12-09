-- Check current state
SELECT 'Categories' as type, COUNT(*) as count FROM training_categories
UNION
SELECT 'Training Items' as type, COUNT(*) as count FROM training_items;

SELECT id, name FROM training_categories ORDER BY id;

SELECT 'training_items' as table_name, ti.id, ti.category_id, ti.question,
       IF(tc.id IS NULL, 'ORPHANED', 'OK') as status
FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
ORDER BY ti.category_id;

-- Cleanup - Delete orphaned items
DELETE FROM training_items WHERE category_id NOT IN (SELECT id FROM training_categories);

-- Verify
SELECT 'After Cleanup' as status;
SELECT COUNT(*) as items FROM training_items;

SELECT tc.id, tc.name, 
       (SELECT COUNT(*) FROM training_items WHERE category_id = tc.id) as items_count
FROM training_categories tc
ORDER BY tc.id;
