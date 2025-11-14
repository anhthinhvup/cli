# Script don gian de chay ngrok
# Usage: .\run-ngrok-simple.ps1

param(
    [int]$Port = 8317
)

Write-Host "=== Starting ngrok for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Port: $Port" -ForegroundColor Yellow
Write-Host ""
Write-Host "ngrok se hien thi URL trong terminal nay" -ForegroundColor Gray
Write-Host "Copy URL do va cap nhat vao New API" -ForegroundColor Gray
Write-Host ""
Write-Host "Nhan Ctrl+C de dung ngrok" -ForegroundColor Yellow
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host ""

# Chay ngrok truc tiep
& ngrok http $Port

