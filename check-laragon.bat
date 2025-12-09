@echo off
color 0B
echo =====================================================
echo    TND System - Laragon Environment Check
echo =====================================================

echo.
echo Checking Laragon environment...
echo.

:: Check if we're in the right directory
if not exist "backend-web" (
    echo [ERROR] Please run this script from the TND System root directory!
    echo Expected structure: backend-web/, frontend-web/, tnd_mobile/
    pause
    exit /b 1
)

:: Check Laragon installation
echo [1/5] Checking Laragon installation...
if exist "C:\laragon\laragon.exe" (
    echo     ✓ Laragon found at C:\laragon\
) else (
    echo     ✗ Laragon not found at C:\laragon\
    echo     Please install Laragon from https://laragon.org/
    pause
    exit /b 1
)

:: Check Apache
echo [2/5] Checking Apache service...
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo     ✓ Apache is running
) else (
    echo     ✗ Apache is not running
    echo     Please start Laragon services
)

:: Check MySQL
echo [3/5] Checking MySQL service...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I /N "mysqld.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo     ✓ MySQL is running
) else (
    echo     ✗ MySQL is not running
    echo     Please start Laragon services
)

:: Test web server
echo [4/5] Testing web server...
powershell -Command "try { $response = Invoke-WebRequest 'http://localhost' -UseBasicParsing -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '     ✓ Web server accessible' -ForegroundColor Green } } catch { Write-Host '     ✗ Web server not accessible' -ForegroundColor Red }"

:: Test database connection
echo [5/5] Testing database connection...
powershell -Command "try { $connection = New-Object System.Data.Odbc.OdbcConnection('DRIVER={MySQL ODBC 8.0 Driver};SERVER=127.0.0.1;PORT=3306;UID=root;PWD=;'); $connection.Open(); Write-Host '     ✓ Database connection successful' -ForegroundColor Green; $connection.Close(); } catch { Write-Host '     ✗ Database connection failed' -ForegroundColor Red; Write-Host '     Make sure MySQL ODBC driver is installed' -ForegroundColor Yellow }"

echo.
echo =====================================================
echo Environment Check Complete
echo =====================================================
echo.

echo Current project URLs:
echo - Admin Panel: http://localhost/tnd_system/tnd_system/frontend-web/login.html
echo - API Health: http://localhost/tnd_system/tnd_system/backend-web/api/health
echo - phpMyAdmin: http://localhost/phpmyadmin
echo.

echo If all checks passed, you can proceed with setup-database.bat
echo.

pause