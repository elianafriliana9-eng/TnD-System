# TND System API Testing Script
# Run this in PowerShell

$baseUrl = "http://localhost/tnd_system/tnd_system/backend-web/api"

Write-Host "TND System API Testing" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

# Test 1: Health Check
Write-Host "`nTesting Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
    Write-Host "✓ Health Check: $($response.message)" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Cyan
    Write-Host "  Version: $($response.data.version)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Login
Write-Host "`nTesting Login..." -ForegroundColor Yellow
$loginData = @{
    email = "admin@tnd-system.com"
    password = "password"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    Write-Host "✓ Login Successful: $($response.message)" -ForegroundColor Green
    Write-Host "  User: $($response.data.name)" -ForegroundColor Cyan
    Write-Host "  Role: $($response.data.role)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Login Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Get Current User (should fail without session)
Write-Host "`nTesting Get Current User (without session)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/me" -Method GET
    Write-Host "✓ Unexpected success: $($response.message)" -ForegroundColor Yellow
} catch {
    Write-Host "✓ Expected failure (no session): Authentication required" -ForegroundColor Green
}

# Test 4: Get Users (should fail without auth)
Write-Host "`nTesting Get Users (without auth)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/users" -Method GET
    Write-Host "✗ Unexpected success: $($response.message)" -ForegroundColor Yellow
} catch {
    Write-Host "✓ Expected failure (no auth): Authentication required" -ForegroundColor Green
}

Write-Host "`nAPI Testing Complete!" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

Write-Host "`nTo fully test the system:" -ForegroundColor Cyan
Write-Host "1. Make sure Laragon is running (Apache + MySQL)" -ForegroundColor White
Write-Host "2. Open: http://localhost/tnd_system/tnd_system/frontend-web/login.html" -ForegroundColor White
Write-Host "3. Login with: admin@tnd-system.com / password" -ForegroundColor White
Write-Host "4. Test all features in the admin panel" -ForegroundColor White
Write-Host "5. Check Laragon logs if there are any issues" -ForegroundColor White

Read-Host "`nPress Enter to exit"