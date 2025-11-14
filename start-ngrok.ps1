# Script de chay ngrok cho CLI Proxy API
# Usage: .\start-ngrok.ps1

param(
    [int]$Port = 8317,
    [string]$AuthToken = ""
)

Write-Host "=== Starting ngrok tunnel ===" -ForegroundColor Cyan
Write-Host ""

# Kiem tra CLI Proxy API co dang chay khong
Write-Host "Kiem tra CLI Proxy API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$Port/v1/models" `
        -Headers @{"Authorization" = "Bearer your-api-key-1"} `
        -Method GET `
        -ErrorAction SilentlyContinue `
        -TimeoutSec 2
    
    Write-Host "CLI Proxy API dang chay tai port $Port" -ForegroundColor Green
} catch {
    Write-Host "Canh bao: Khong the ket noi den CLI Proxy API tai localhost:$Port" -ForegroundColor Yellow
    Write-Host "Dam bao CLI Proxy API dang chay truoc khi tiep tuc" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "Tiep tuc? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Cau hinh authtoken neu co
if ($AuthToken) {
    Write-Host ""
    Write-Host "Cau hinh authtoken..." -ForegroundColor Yellow
    ngrok config add-authtoken $AuthToken
    Write-Host "Authtoken da duoc cau hinh" -ForegroundColor Green
}

Write-Host ""
Write-Host "Bat dau ngrok tunnel..." -ForegroundColor Yellow
Write-Host "Port: $Port" -ForegroundColor Gray
Write-Host ""
Write-Host "Dang cho ngrok khoi dong..." -ForegroundColor Gray

# Start ngrok trong background
$ngrokJob = Start-Job -ScriptBlock {
    param($port)
    & ngrok http $port
} -ArgumentList $Port

Start-Sleep -Seconds 5

# Lay URL tu ngrok API
Write-Host ""
Write-Host "Lay thong tin tunnel..." -ForegroundColor Yellow
try {
    Start-Sleep -Seconds 2
    $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -ErrorAction Stop
    
    if ($tunnels.tunnels.Count -gt 0) {
        $publicUrl = $tunnels.tunnels[0].public_url
        Write-Host ""
        Write-Host "=== NGROK TUNNEL DA SAN SANG ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Public URL: $publicUrl" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Buoc tiep theo:" -ForegroundColor Yellow
        Write-Host "1. Cap nhat Base URL trong New API (langhit.com):" -ForegroundColor Gray
        Write-Host "   $publicUrl" -ForegroundColor White
        Write-Host ""
        Write-Host "2. Test API:" -ForegroundColor Gray
        Write-Host "   curl $publicUrl/v1/models -H 'Authorization: Bearer your-api-key-1'" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Xem ngrok dashboard: http://localhost:4040" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Luu y:" -ForegroundColor Yellow
        Write-Host "- URL se thay doi moi lan restart ngrok (trừ khi co custom domain)" -ForegroundColor Gray
        Write-Host "- Nhan Ctrl+C de dung ngrok" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "Khong tim thay tunnel. Kiem tra http://localhost:4040" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Khong the lay thong tin tunnel tu ngrok API" -ForegroundColor Yellow
    Write-Host "Kiem tra http://localhost:4040 de xem URL" -ForegroundColor Gray
    Write-Host "ngrok dang chay trong background" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Nhan Ctrl+C de dung ngrok..." -ForegroundColor Yellow
Write-Host ""

# Wait for user interrupt
try {
    while ($true) {
        Start-Sleep -Seconds 1
        if (-not (Get-Job -Id $ngrokJob.Id -ErrorAction SilentlyContinue)) {
            break
        }
    }
} catch {
    # User interrupted
}

# Cleanup
Stop-Job -Job $ngrokJob -ErrorAction SilentlyContinue
Remove-Job -Job $ngrokJob -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "ngrok da dung" -ForegroundColor Yellow

