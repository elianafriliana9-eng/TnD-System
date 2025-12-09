<?php
/**
 * Fix existing photos with NULL item_id
 * Update item_id based on caption/visit context
 */

require_once __DIR__ . '/config/database.php';

header('Content-Type: text/plain; charset=utf-8');

try {
    $db = Database::getInstance()->getConnection();
    
    echo "=== FIXING PHOTOS WITH NULL ITEM_ID ===\n\n";
    
    // Find photos with NULL item_id
    $stmt = $db->query("
        SELECT id, visit_id, item_id, caption, uploaded_at 
        FROM photos 
        WHERE item_id IS NULL
        ORDER BY visit_id, uploaded_at
    ");
    $nullPhotos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Found " . count($nullPhotos) . " photos with NULL item_id\n\n";
    
    if (empty($nullPhotos)) {
        echo "✅ No photos to fix!\n";
        exit;
    }
    
    $fixed = 0;
    $failed = 0;
    
    foreach ($nullPhotos as $photo) {
        echo "Photo ID {$photo['id']} (visit {$photo['visit_id']}): ";
        
        // Try to find matching response for this visit
        // Get the first NOT OK response for this visit
        $stmt = $db->prepare("
            SELECT checklist_point_id 
            FROM visit_checklist_responses 
            WHERE visit_id = :visit_id 
            AND response = 'NOT OK'
            ORDER BY created_at
            LIMIT 1
        ");
        $stmt->bindParam(':visit_id', $photo['visit_id']);
        $stmt->execute();
        $response = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($response) {
            $itemId = $response['checklist_point_id'];
            
            // Update photo with item_id
            $updateStmt = $db->prepare("
                UPDATE photos 
                SET item_id = :item_id 
                WHERE id = :photo_id
            ");
            $updateStmt->bindParam(':item_id', $itemId);
            $updateStmt->bindParam(':photo_id', $photo['id']);
            
            if ($updateStmt->execute()) {
                echo "✅ Fixed! Set item_id = $itemId\n";
                $fixed++;
            } else {
                echo "❌ Update failed\n";
                $failed++;
            }
        } else {
            echo "⚠️  No matching response found\n";
            $failed++;
        }
    }
    
    echo "\n" . str_repeat("=", 80) . "\n";
    echo "SUMMARY:\n";
    echo "  Fixed: $fixed\n";
    echo "  Failed: $failed\n";
    echo "  Total: " . count($nullPhotos) . "\n";
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
