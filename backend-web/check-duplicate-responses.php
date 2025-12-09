<?php
require_once 'config/database.php';
require_once 'classes/Database.php';

$db = Database::getInstance()->getConnection();

echo "=== CHECK DUPLICATE RESPONSES ===\n";
$sql = "SELECT 
    vcr.visit_id,
    vcr.checklist_point_id,
    vcr.response,
    COUNT(*) as count,
    GROUP_CONCAT(vcr.id) as response_ids,
    cp.question
FROM visit_checklist_responses vcr
LEFT JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
GROUP BY vcr.visit_id, vcr.checklist_point_id, vcr.response
HAVING COUNT(*) > 1
ORDER BY vcr.visit_id DESC
LIMIT 10";

$stmt = $db->query($sql);
$duplicates = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($duplicates)) {
    echo "✅ No duplicate responses found\n";
} else {
    echo "⚠️ Found duplicate responses:\n";
    foreach ($duplicates as $dup) {
        echo "  Visit: {$dup['visit_id']}, Item: {$dup['checklist_point_id']}, Response: {$dup['response']}, Count: {$dup['count']}\n";
        echo "    IDs: {$dup['response_ids']}\n";
        echo "    Question: {$dup['question']}\n";
    }
}

echo "\n=== CHECK MULTIPLE RESPONSES FOR SAME ITEM ===\n";
$sql = "SELECT 
    vcr.visit_id,
    vcr.checklist_point_id,
    GROUP_CONCAT(DISTINCT vcr.response ORDER BY vcr.response) as responses,
    COUNT(DISTINCT vcr.response) as response_count,
    GROUP_CONCAT(vcr.id ORDER BY vcr.id) as response_ids,
    cp.question
FROM visit_checklist_responses vcr
LEFT JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
GROUP BY vcr.visit_id, vcr.checklist_point_id
HAVING COUNT(DISTINCT vcr.response) > 1
ORDER BY vcr.visit_id DESC
LIMIT 10";

$stmt = $db->query($sql);
$multiResponses = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($multiResponses)) {
    echo "✅ No items with multiple different responses found\n";
} else {
    echo "⚠️ Found items with MULTIPLE DIFFERENT responses (OK AND NOK for same item!):\n";
    foreach ($multiResponses as $mr) {
        echo "  Visit: {$mr['visit_id']}, Item: {$mr['checklist_point_id']}\n";
        echo "    Responses: {$mr['responses']} (count: {$mr['response_count']})\n";
        echo "    IDs: {$mr['response_ids']}\n";
        echo "    Question: {$mr['question']}\n";
    }
}

echo "\n=== CHECK PHOTOS LINKED TO ITEMS ===\n";
$sql = "SELECT 
    p.visit_id,
    p.item_id,
    p.file_name,
    vcr.response,
    cp.question,
    COUNT(vcr.id) as response_count_for_item
FROM photos p
LEFT JOIN visit_checklist_responses vcr ON p.visit_id = vcr.visit_id AND p.item_id = vcr.checklist_point_id
LEFT JOIN checklist_points cp ON p.item_id = cp.id
GROUP BY p.visit_id, p.item_id, p.file_name, vcr.response, cp.question
ORDER BY p.visit_id DESC, p.item_id
LIMIT 20";

$stmt = $db->query($sql);
$photos = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($photos as $photo) {
    echo "  Visit: {$photo['visit_id']}, Item: {$photo['item_id']}\n";
    echo "    Photo: {$photo['file_name']}\n";
    echo "    Response: {$photo['response']} (count: {$photo['response_count_for_item']})\n";
    echo "    Question: {$photo['question']}\n";
}

?>
