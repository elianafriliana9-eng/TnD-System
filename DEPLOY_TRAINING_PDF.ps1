#!/usr/bin/env pwsh
# Training PDF Module - Quick Deployment Guide
# Usage: Copy commands and run in PowerShell

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  TRAINING PDF MODULE - QUICK DEPLOYMENT GUIDE            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 1: Verify Project Structure" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
$projectPath = "c:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter"
if (Test-Path "$projectPath\pubspec.yaml") {
    Write-Host "✓ Flutter project found at: $projectPath" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter project NOT found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "STEP 2: Verify PDF Service Files" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray

$files = @(
    "$projectPath\lib\services\training\training_pdf_service.dart",
    "$projectPath\lib\screens\training\training_session_checklist_screen.dart",
    "c:\laragon\www\tnd_system\tnd_system\backend-web\api\training\session-detail.php"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length / 1KB
        Write-Host "✓ Found: $(Split-Path $file -Leaf) ($([math]::Round($size))KB)" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $(Split-Path $file -Leaf)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "STEP 3: Check for Compilation Errors" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "Run this in VS Code terminal or manually:" -ForegroundColor Gray
Write-Host ""
Write-Host "  cd '$projectPath'" -ForegroundColor Cyan
Write-Host "  flutter analyze" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 4: Build APK (Release)" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "This may take 5-10 minutes:" -ForegroundColor Gray
Write-Host ""
Write-Host "  cd '$projectPath'" -ForegroundColor Cyan
Write-Host "  flutter build apk --release" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 5: Test on Device" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Option A: Install on connected device:" -ForegroundColor Cyan
Write-Host "  cd '$projectPath'" -ForegroundColor Cyan
Write-Host "  flutter install --release" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option B: Manual APK install:" -ForegroundColor Cyan
Write-Host "  APK Location: $projectPath\build\app\outputs\flutter-app.apk" -ForegroundColor Cyan
Write-Host "  Transfer to device and install" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 6: Production Deployment" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Backend Fix (CRITICAL):" -ForegroundColor Cyan
Write-Host "  1. SSH/FTP to production server" -ForegroundColor Gray
Write-Host "  2. Upload new session-detail.php to /api/training/" -ForegroundColor Gray
Write-Host "  3. Test: curl https://yourserver.com/api/training/session-detail.php?session_id=1" -ForegroundColor Gray
Write-Host ""
Write-Host "Mobile App Update:" -ForegroundColor Cyan
Write-Host "  1. Upload APK to Google Play Store" -ForegroundColor Gray
Write-Host "  2. Set app config to production server URL" -ForegroundColor Gray
Write-Host "  3. Release to production" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 7: Post-Deployment Testing" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Verification Checklist:" -ForegroundColor Cyan
Write-Host "  □ Login to production server with mobile app" -ForegroundColor Gray
Write-Host "  □ Navigate to Training Sessions" -ForegroundColor Gray
Write-Host "  □ Select a completed training session" -ForegroundColor Gray
Write-Host "  □ Click 'Export PDF'" -ForegroundColor Gray
Write-Host "  □ Verify PDF shows 3-4 pages with content" -ForegroundColor Gray
Write-Host "  □ Check all category names are present" -ForegroundColor Gray
Write-Host "  □ Verify OK/NOK/N/A items display correctly" -ForegroundColor Gray
Write-Host "  □ Test with multiple sessions" -ForegroundColor Gray
Write-Host ""

Write-Host "TROUBLESHOOTING" -ForegroundColor Yellow
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Issue: 'No pubspec.yaml file found'" -ForegroundColor Red
Write-Host "  Solution: Make sure you're in the Flutter project directory:" -ForegroundColor Gray
Write-Host "    cd 'c:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Issue: 'PDF shows only header'" -ForegroundColor Red
Write-Host "  Solution: Check backend API is returning categories" -ForegroundColor Gray
Write-Host "    1. Verify session-detail.php was uploaded" -ForegroundColor Gray
Write-Host "    2. Check production database has training_points table" -ForegroundColor Gray
Write-Host "    3. View mobile app logs during PDF generation" -ForegroundColor Gray
Write-Host ""
Write-Host "Issue: 'Build takes too long or fails'" -ForegroundColor Red
Write-Host "  Solution: Clear build cache and rebuild" -ForegroundColor Gray
Write-Host "    flutter clean" -ForegroundColor Cyan
Write-Host "    flutter pub get" -ForegroundColor Cyan
Write-Host "    flutter build apk --release" -ForegroundColor Cyan
Write-Host ""

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  All systems ready! Follow steps above to deploy.        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
