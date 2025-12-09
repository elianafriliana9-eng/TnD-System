# Test Delete API Endpoint
$itemId = 1  # Change this to a valid item ID to test

$url = "http://localhost/tnd_system/backend-web/api/training/item-delete.php?id=$itemId"

Write-Host "Testing DELETE endpoint: $url" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $url -Method Delete -UseBasicParsing
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response Body:" -ForegroundColor Green
    Write-Host $response.Content -ForegroundColor White
} catch {
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "Error: $($_)" -ForegroundColor Red
}
