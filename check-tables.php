<?php
require_once 'backend-web/config/database.php';

$db = Database::getInstance()->getConnection();

// Get training tables
$tables = $db->query("SHOW TABLES LIKE '%training%'")->fetchAll();
echo "Training tables found:\n";
foreach($tables as $t) {
    echo "- " . $t[0] . "\n";
}

echo "\n";

// Check specific table structure
echo "Checking training_items table:\n";
$result = $db->query("DESC training_items")->fetchAll();
if (!empty($result)) {
    echo "✓ training_items table EXISTS\n";
    echo "Columns: ";
    foreach($result as $col) {
        echo $col['Field'] . ", ";
    }
    echo "\n";
} else {
    echo "✗ training_items table DOES NOT EXIST\n";
}

echo "\nChecking training_points table:\n";
$result = $db->query("DESC training_points")->fetchAll(PDO::FETCH_ASSOC);
if (!empty($result)) {
    echo "✓ training_points table EXISTS\n";
    echo "Columns: ";
    foreach($result as $col) {
        echo $col['Field'] . ", ";
    }
    echo "\n";
} else {
    echo "✗ training_points table DOES NOT EXIST\n";
}

echo "\nData counts:\n";
$count = $db->query("SELECT COUNT(*) FROM training_categories")->fetch()[0];
echo "training_categories: $count records\n";

$count = $db->query("SELECT COUNT(*) FROM training_items")->fetch()[0];
echo "training_items: $count records\n";

$count = $db->query("SELECT COUNT(*) FROM training_checklists")->fetch()[0];
echo "training_checklists: $count records\n";

$count = $db->query("SELECT COUNT(*) FROM training_sessions")->fetch()[0];
echo "training_sessions: $count records\n";

?>
