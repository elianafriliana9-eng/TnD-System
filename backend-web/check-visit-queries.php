<?php
/**
 * Extract all SQL queries from Visit.php to find issues
 */

header('Content-Type: text/plain');

$visitFile = __DIR__ . '/classes/Visit.php';

if (!file_exists($visitFile)) {
    die("Visit.php not found!");
}

$content = file_get_contents($visitFile);

echo "=== SEARCHING FOR DATABASE QUERIES IN Visit.php ===\n\n";

// Find all SQL queries
preg_match_all('/sql\s*=\s*["\'](.+?)["\']/is', $content, $matches);

if (!empty($matches[1])) {
    foreach ($matches[1] as $index => $query) {
        echo "Query #" . ($index + 1) . ":\n";
        echo str_repeat("-", 80) . "\n";
        echo $query . "\n";
        echo str_repeat("-", 80) . "\n\n";
        
        // Check for problematic patterns
        if (stripos($query, 'visit_photos') !== false) {
            echo "⚠️  WARNING: Uses 'visit_photos' table!\n\n";
        }
        if (stripos($query, 'checklist_point_id') !== false) {
            echo "⚠️  WARNING: Uses 'checklist_point_id' column!\n\n";
        }
        if (stripos($query, 'photos') !== false && stripos($query, 'visit_photos') === false) {
            echo "✅ GOOD: Uses 'photos' table\n\n";
        }
        if (stripos($query, 'item_id') !== false) {
            echo "✅ GOOD: Uses 'item_id' column\n\n";
        }
    }
} else {
    echo "No SQL queries found!\n";
}

echo "\n=== CHECKING FOR SPECIFIC PATTERNS ===\n\n";

$patterns = [
    'visit_photos' => 'Uses old table name',
    'checklist_point_id' => 'Uses old column name',
    'photos p' => 'Uses new table name with alias',
    'item_id' => 'Uses new column name',
    'file_path' => 'Uses new column name',
];

foreach ($patterns as $pattern => $description) {
    $count = substr_count(strtolower($content), strtolower($pattern));
    echo "$description ($pattern): $count occurrences\n";
}
?>
