<?php
require_once 'backend-web/config/database.php';

$db = Database::getInstance();
$conn = $db->getConnection();

// Check training_categories
$stmt = $conn->prepare("SELECT COUNT(*) as total FROM training_categories");
$stmt->execute();
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Total training_categories: " . $result['total'] . "\n";

// Check training_checklists
$stmt = $conn->prepare("SELECT COUNT(*) as total FROM training_checklists");
$stmt->execute();
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Total training_checklists: " . $result['total'] . "\n";

// Check training_items
$stmt = $conn->prepare("SELECT COUNT(*) as total FROM training_items");
$stmt->execute();
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Total training_items: " . $result['total'] . "\n";

// Check training_sessions
$stmt = $conn->prepare("SELECT COUNT(*) as total FROM training_sessions");
$stmt->execute();
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Total training_sessions: " . $result['total'] . "\n";

// Check if any session exists
$stmt = $conn->prepare("SELECT id, outlet_id, checklist_id FROM training_sessions LIMIT 1");
$stmt->execute();
$session = $stmt->fetch(PDO::FETCH_ASSOC);
if ($session) {
    echo "\nFirst session:\n";
    echo "  Session ID: " . $session['id'] . "\n";
    echo "  Checklist ID: " . $session['checklist_id'] . "\n";
    
    // Check categories for this checklist
    $stmt = $conn->prepare("SELECT COUNT(*) as total FROM training_categories WHERE checklist_id = ?");
    $stmt->execute([$session['checklist_id']]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "  Categories for checklist: " . $result['total'] . "\n";
}
?>
