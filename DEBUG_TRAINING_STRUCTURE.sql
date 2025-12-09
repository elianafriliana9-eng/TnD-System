-- Temporary: We need to understand the relationship
-- Show checklist_id yang sedang active
SELECT * FROM training_checklists WHERE is_active = 1 LIMIT 1;

-- Show categories untuk checklist yang active
SELECT tc.id, tc.name, tc.checklist_id, COUNT(ti.id) as item_count
FROM training_categories tc
LEFT JOIN training_items ti ON tc.id = ti.category_id
WHERE tc.checklist_id IN (SELECT id FROM training_checklists WHERE is_active = 1)
GROUP BY tc.id
ORDER BY tc.checklist_id, tc.id;
