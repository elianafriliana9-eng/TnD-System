<?php
$dbHost = 'localhost';
$dbUser = 'root';
$dbPass = '';
$dbName = 'tnd_db';

try {
    $conn = new PDO("mysql:host=$dbHost;dbname=$dbName", $dbUser, $dbPass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get all categories
    $stmt = $conn->query('SELECT id, name FROM training_categories ORDER BY id');
    $cats = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "=== Current Categories ===\n";
    foreach ($cats as $cat) {
        echo "ID: {$cat['id']}, Name: {$cat['name']}\n";
    }
    echo "\n";
    
    // Get max ID
    $stmt = $conn->query('SELECT MAX(id) as max_id FROM training_categories');
    $maxId = $stmt->fetch(PDO::FETCH_ASSOC)['max_id'] ?? 0;
    echo "Max Category ID: $maxId\n";
    
    // Get all items with their category_id
    echo "\n=== Training Items/Points ===\n";
    $stmt = $conn->query('SELECT id, category_id, question FROM training_items ORDER BY category_id');
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!empty($items)) {
        echo "training_items count: " . count($items) . "\n";
        foreach ($items as $item) {
            echo "  Item {$item['id']}: category_id={$item['category_id']}, question={$item['question']}\n";
        }
    } else {
        echo "training_items: empty\n";
    }
    
    $stmt = $conn->query('SELECT id, category_id, question FROM training_points ORDER BY category_id');
    $points = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!empty($points)) {
        echo "training_points count: " . count($points) . "\n";
        foreach ($points as $point) {
            echo "  Point {$point['id']}: category_id={$point['category_id']}, question={$point['question']}\n";
        }
    } else {
        echo "training_points: empty\n";
    }
    
    // Check for orphaned items (category_id not in training_categories)
    echo "\n=== Orphaned Items (category_id not in training_categories) ===\n";
    $stmt = $conn->query('
        SELECT ti.id, ti.category_id, ti.question
        FROM training_items ti
        LEFT JOIN training_categories tc ON ti.category_id = tc.id
        WHERE tc.id IS NULL
    ');
    $orphaned = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!empty($orphaned)) {
        echo "Found " . count($orphaned) . " orphaned items in training_items\n";
        foreach ($orphaned as $item) {
            echo "  Item {$item['id']}: category_id={$item['category_id']}\n";
        }
    } else {
        echo "No orphaned items in training_items\n";
    }
    
    $stmt = $conn->query('
        SELECT tp.id, tp.category_id, tp.question
        FROM training_points tp
        LEFT JOIN training_categories tc ON tp.category_id = tc.id
        WHERE tc.id IS NULL
    ');
    $orphaned = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!empty($orphaned)) {
        echo "Found " . count($orphaned) . " orphaned items in training_points\n";
        foreach ($orphaned as $item) {
            echo "  Point {$item['id']}: category_id={$item['category_id']}\n";
        }
    } else {
        echo "No orphaned items in training_points\n";
    }
    
} catch (Exception $e) {
    echo 'Error: ' . $e->getMessage();
}
?>
