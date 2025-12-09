# Delete all test and debug files
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DELETING ALL TEST AND DEBUG FILES..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$filesToDelete = @(
    "test_outlet.php",
    "test_session.php", 
    "test_structure.php",
    "simple_debug.php",
    "debug_outlets.php",
    "check-uploads.php",
    "fix-admin-password.php",
    "pre-deployment-check.php",
    "pre-deployment-check.sh",
    "cleanup-test-files.bat",
    "DELETE_TEST_FILES_NOW.bat",
    "api\test.php",
    "api\debug.php",
    "api\session-test.php",
    "api\users-test.php"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "[DELETED] $file" -ForegroundColor Green
    } else {
        Write-Host "[NOT FOUND] $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All test and debug files have been removed."
Write-Host "Backend is now cleaner for production deployment."
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update .env file with production settings"
Write-Host "2. Generate strong JWT secret"
Write-Host "3. Configure production CORS origins"
Write-Host "4. Review PRODUCTION_CHECKLIST.md"
Write-Host ""
