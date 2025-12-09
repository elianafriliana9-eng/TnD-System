-- Check all 3 tables structure and data

-- 1. Check training_categories
SELECT 'training_categories' as table_name;
SELECT * FROM training_categories ORDER BY id;
SELECT COUNT(*) as total_categories FROM training_categories;

-- 2. Check training_checklist
SELECT 'training_checklists' as table_name;
SELECT * FROM training_checklist ORDER BY id LIMIT 10;
SELECT COUNT(*) as total_checklist FROM training_checklist;

-- 3. Check training_items
SELECT 'training_items' as table_name;
SELECT ti.id, ti.category_id, ti.question, tc.name as category_name,
       IF(tc.id IS NULL, 'ORPHANED', 'OK') as status
FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
ORDER BY ti.category_id;
SELECT COUNT(*) as total_items FROM training_items;

-- Show relationships
SELECT 'Relationship Check' as info;
SELECT 'Items with non-existent category_id:' as check_type;
SELECT DISTINCT ti.category_id FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
WHERE tc.id IS NULL;

-- Show all data
SELECT 'All Categories with Item Counts' as info;
SELECT tc.id, tc.name, COUNT(ti.id) as item_count
FROM training_categories tc
LEFT JOIN training_items ti ON tc.id = ti.category_id
GROUP BY tc.id, tc.name
ORDER BY tc.id;
