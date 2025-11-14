# Script de cau hinh ngrok authtoken
# Usage: .\configure-ngrok-token.ps1

Write-Host "=== Cau hinh ngrok authtoken ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Buoc 1: Dang ky/Dang nhap tai khoan ngrok (mien phi)" -ForegroundColor Yellow
Write-Host "   URL: https://dashboard.ngrok.com/signup" -ForegroundColor White
Write-Host ""

Write-Host "Buoc 2: Lay authtoken" -ForegroundColor Yellow
Write-Host "   Sau khi dang nhap, vao:" -ForegroundColor Gray
Write-Host "   https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor White
Write-Host ""

$openBrowser = Read-Host "Mo browser de dang ky/lay token? (y/n)"
if ($openBrowser -eq "y") {
    Start-Process "https://dashboard.ngrok.com/signup"
    Write-Host ""
    Write-Host "Dang cho ban dang ky va lay token..." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Nhap authtoken cua ban:" -ForegroundColor Cyan
$token = Read-Host "Authtoken"

if ([string]::IsNullOrEmpty($token)) {
    Write-Host ""
    Write-Host "Khong co authtoken. Vui long thu lai sau khi co token." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Dang cau hinh authtoken..." -ForegroundColor Yellow
$result = ngrok config add-authtoken $token 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Authtoken da duoc cau hinh thanh cong!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Bay gio ban co the chay ngrok:" -ForegroundColor Yellow
    Write-Host "   ngrok http 8317" -ForegroundColor White
    Write-Host "   hoac" -ForegroundColor Gray
    Write-Host "   .\run-ngrok-simple.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Loi khi cau hinh authtoken:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui long kiem tra:" -ForegroundColor Yellow
    Write-Host "   - Token co dung khong?" -ForegroundColor Gray
    Write-Host "   - Da dang nhap tai khoan ngrok chua?" -ForegroundColor Gray
}

