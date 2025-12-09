-- CLEANUP SCRIPT: Remove orphaned items and fix category ID mismatches

-- Step 1: See what we have before cleanup
SELECT 'BEFORE CLEANUP' as status;
SELECT COUNT(*) as orphaned_items_count FROM training_items ti
LEFT JOIN training_categories tc ON ti.category_id = tc.id
WHERE tc.id IS NULL;

SELECT COUNT(*) as orphaned_points_count FROM training_points tp
LEFT JOIN training_categories tc ON tp.category_id = tc.id
WHERE tc.id IS NULL;

-- Step 2: Delete orphaned items from training_items table
DELETE FROM training_items WHERE category_id NOT IN (SELECT id FROM training_categories);

-- Step 3: Delete orphaned items from training_points table
DELETE FROM training_points WHERE category_id NOT IN (SELECT id FROM training_categories);

-- Step 4: Verify cleanup
SELECT 'AFTER CLEANUP' as status;
SELECT COUNT(*) as remaining_items FROM training_items;
SELECT COUNT(*) as remaining_points FROM training_points;

-- Step 5: Show remaining items by category
SELECT tc.id, tc.name, 
       (SELECT COUNT(*) FROM training_items WHERE category_id = tc.id) as items_count,
       (SELECT COUNT(*) FROM training_points WHERE category_id = tc.id) as points_count
FROM training_categories tc
ORDER BY tc.id;
