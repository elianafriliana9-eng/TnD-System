<?php
// export-audits.php

require_once '../config/database.php';
require_once '../classes/Audit.php';
require_once '../utils/Auth.php';

// Start session and check authentication
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
if (!Auth::checkAuth()) {
    header('HTTP/1.1 403 Forbidden');
    echo "Authentication required.";
    exit;
}

try {
    $auditModel = new Audit();
    $audits = $auditModel->getAuditsWithDetails();

    $filename = "audit_report_" . date('Y-m-d') . ".csv";

    // Set headers to force download
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');

    // Create a file pointer connected to the output stream
    $output = fopen('php://output', 'w');

    // Output the column headings
    fputcsv($output, [
        'Audit ID',
        'Outlet Name',
        'Outlet Address',
        'Auditor Name',
        'Score',
        'Status',
        'Audit Date',
        'Notes'
    ]);

    // Loop over the rows, outputting them
    if (!empty($audits)) {
        foreach ($audits as $audit) {
            fputcsv($output, [
                $audit['id'],
                $audit['outlet_name'],
                $audit['outlet_address'],
                $audit['user_name'],
                $audit['score'],
                $audit['status'],
                $audit['audit_date'],
                $audit['notes']
            ]);
        }
    }

    fclose($output);
    exit;

} catch (Exception $e) {
    header('HTTP/1.1 500 Internal Server Error');
    echo "Error generating report: " . $e->getMessage();
    exit;
}
?>