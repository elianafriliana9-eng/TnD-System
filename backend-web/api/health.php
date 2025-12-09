<?php
/**
 * Direct Health Check Test
 */

header('Content-Type: application/json');

$response = [
    'success' => true,
    'message' => 'API is working!',
    'data' => [
        'status' => 'OK',
        'timestamp' => date('Y-m-d H:i:s'),
        'version' => '1.0.0',
        'php_version' => phpversion()
    ]
];

echo json_encode($response, JSON_PRETTY_PRINT);
?>