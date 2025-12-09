@echo off
color 0A
echo ==========================================
echo    TND System - Database Setup (Laragon)
echo ==========================================

echo.
echo Checking Laragon status...
echo Make sure Laragon is running before continuing!
echo.
echo Required Services:
echo - Apache: Running
echo - MySQL: Running
echo.

pause

echo.
echo Checking if Laragon services are accessible...
echo Testing MySQL connection...

powershell -Command "try { $connection = New-Object System.Data.Odbc.OdbcConnection('DRIVER={MySQL ODBC 8.0 Driver};SERVER=127.0.0.1;PORT=3306;UID=root;PWD=;'); $connection.Open(); Write-Host 'MySQL: Connected successfully' -ForegroundColor Green; $connection.Close(); } catch { Write-Host 'MySQL: Connection failed - Make sure Laragon MySQL is running' -ForegroundColor Red }"

echo.
echo Opening Laragon phpMyAdmin...
start http://localhost/phpmyadmin

echo.
echo ==========================================
echo Please follow these steps in phpMyAdmin:
echo ==========================================
echo 1. Click "Import" tab
echo 2. Click "Choose File" button
echo 3. Navigate to your project folder and select:
echo    backend-web/database_schema.sql
echo 4. Click "Go" to import
echo.
echo The database 'tnd_system' will be created automatically
echo with sample data and default admin user.
echo.
echo ==========================================
echo Default Admin Login Credentials:
echo ==========================================
echo Email: admin@tnd-system.com
echo Password: password
echo ==========================================
echo.

pause

echo.
echo Opening TND System Login Page...
start http://localhost/tnd_system/tnd_system/frontend-web/login.html

echo.
echo ==========================================
echo Setup Complete!
echo ==========================================
echo You can now login to the system using the
echo credentials shown above.
echo.
echo Useful URLs:
echo - Admin Panel: http://localhost/tnd_system/tnd_system/frontend-web/
echo - API Endpoint: http://localhost/tnd_system/tnd_system/backend-web/api/
echo - phpMyAdmin: http://localhost/phpmyadmin
echo.

pause