@echo off
echo ========================================
echo DELETING ALL TEST AND DEBUG FILES...
echo ========================================
echo.

cd /d "%~dp0"

REM Delete test and debug files in root
del /F test_outlet.php 2>nul
if %errorlevel%==0 (echo [DELETED] test_outlet.php) else (echo [NOT FOUND] test_outlet.php)

del /F test_session.php 2>nul
if %errorlevel%==0 (echo [DELETED] test_session.php) else (echo [NOT FOUND] test_session.php)

del /F test_structure.php 2>nul
if %errorlevel%==0 (echo [DELETED] test_structure.php) else (echo [NOT FOUND] test_structure.php)

del /F simple_debug.php 2>nul
if %errorlevel%==0 (echo [DELETED] simple_debug.php) else (echo [NOT FOUND] simple_debug.php)

del /F debug_outlets.php 2>nul
if %errorlevel%==0 (echo [DELETED] debug_outlets.php) else (echo [NOT FOUND] debug_outlets.php)

del /F check-uploads.php 2>nul
if %errorlevel%==0 (echo [DELETED] check-uploads.php) else (echo [NOT FOUND] check-uploads.php)

del /F fix-admin-password.php 2>nul
if %errorlevel%==0 (echo [DELETED] fix-admin-password.php) else (echo [NOT FOUND] fix-admin-password.php)

del /F pre-deployment-check.php 2>nul
if %errorlevel%==0 (echo [DELETED] pre-deployment-check.php) else (echo [NOT FOUND] pre-deployment-check.php)

del /F pre-deployment-check.sh 2>nul
if %errorlevel%==0 (echo [DELETED] pre-deployment-check.sh) else (echo [NOT FOUND] pre-deployment-check.sh)

del /F cleanup-test-files.bat 2>nul
if %errorlevel%==0 (echo [DELETED] cleanup-test-files.bat) else (echo [NOT FOUND] cleanup-test-files.bat)

del /F DELETE_TEST_FILES_NOW.bat 2>nul
if %errorlevel%==0 (echo [DELETED] DELETE_TEST_FILES_NOW.bat) else (echo [NOT FOUND] DELETE_TEST_FILES_NOW.bat)

REM Delete test files in api directory
cd api
del /F test.php 2>nul
if %errorlevel%==0 (echo [DELETED] api\test.php) else (echo [NOT FOUND] api\test.php)

del /F debug.php 2>nul
if %errorlevel%==0 (echo [DELETED] api\debug.php) else (echo [NOT FOUND] api\debug.php)

del /F session-test.php 2>nul
if %errorlevel%==0 (echo [DELETED] api\session-test.php) else (echo [NOT FOUND] api\session-test.php)

del /F users-test.php 2>nul
if %errorlevel%==0 (echo [DELETED] api\users-test.php) else (echo [NOT FOUND] api\users-test.php)

cd ..

echo.
echo ========================================
echo CLEANUP COMPLETE!
echo ========================================
echo.
echo All test and debug files have been removed.
echo Backend is now cleaner for production deployment.
echo.
echo Next steps:
echo 1. Update .env file with production settings
echo 2. Generate strong JWT secret
echo 3. Configure production CORS origins
echo 4. Review PRODUCTION_CHECKLIST.md
echo.
pause
