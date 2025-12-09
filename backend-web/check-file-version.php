<?php
/**
 * Check which version of files are on production
 */

header('Content-Type: application/json');

$files = [
    'classes/Visit.php' => __DIR__ . '/classes/Visit.php',
    'api/visit-photo-upload.php' => __DIR__ . '/api/visit-photo-upload.php',
];

$result = [];

foreach ($files as $name => $path) {
    if (file_exists($path)) {
        $content = file_get_contents($path);
        
        // Check for key indicators
        $indicators = [
            'uses_photos_table' => strpos($content, 'INSERT INTO photos') !== false,
            'uses_visit_photos_table' => strpos($content, 'INSERT INTO visit_photos') !== false,
            'uses_item_id' => strpos($content, 'item_id') !== false,
            'uses_checklist_point_id' => strpos($content, 'checklist_point_id') !== false,
            'uses_file_path' => strpos($content, 'file_path') !== false,
            'has_extensive_logging' => strpos($content, 'VISIT PHOTO UPLOAD REQUEST') !== false,
        ];
        
        $result[$name] = [
            'exists' => true,
            'size' => filesize($path),
            'last_modified' => date('Y-m-d H:i:s', filemtime($path)),
            'indicators' => $indicators,
        ];
    } else {
        $result[$name] = [
            'exists' => false,
        ];
    }
}

echo json_encode($result, JSON_PRETTY_PRINT);
?>
