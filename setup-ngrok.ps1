# Script setup ngrok cho CLI Proxy API
# Usage: .\setup-ngrok.ps1

param(
    [int]$Port = 8317,
    [string]$AuthToken = "",
    [switch]$Install = $false
)

Write-Host "=== Setup ngrok for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra ngrok đã cài đặt chưa
$ngrokInstalled = $false
try {
    $ngrokVersion = ngrok version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ngrokInstalled = $true
        Write-Host "✅ ngrok is installed: $ngrokVersion" -ForegroundColor Green
    }
} catch {
    $ngrokInstalled = $false
}

if (-not $ngrokInstalled) {
    if ($Install) {
        Write-Host "📦 Installing ngrok..." -ForegroundColor Yellow
        
        # Kiểm tra Chocolatey
        $chocoInstalled = $false
        try {
            choco --version | Out-Null
            $chocoInstalled = $true
        } catch {
            $chocoInstalled = $false
        }
        
        if ($chocoInstalled) {
            Write-Host "Installing via Chocolatey..." -ForegroundColor Yellow
            choco install ngrok -y
        } else {
            Write-Host "⚠️  Chocolatey not found. Please install ngrok manually:" -ForegroundColor Yellow
            Write-Host "   1. Download from: https://ngrok.com/download" -ForegroundColor Gray
            Write-Host "   2. Extract and add to PATH" -ForegroundColor Gray
            Write-Host "   3. Run this script again" -ForegroundColor Gray
            exit 1
        }
    } else {
        Write-Host "❌ ngrok is not installed" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 To install:" -ForegroundColor Yellow
        Write-Host "   .\setup-ngrok.ps1 -Install" -ForegroundColor White
        Write-Host "   Or download from: https://ngrok.com/download" -ForegroundColor Gray
        exit 1
    }
}

# Cấu hình authtoken nếu có
if (-not [string]::IsNullOrEmpty($AuthToken)) {
    Write-Host ""
    Write-Host "🔑 Configuring ngrok authtoken..." -ForegroundColor Yellow
    ngrok config add-authtoken $AuthToken
    Write-Host "✅ Authtoken configured" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  No authtoken provided" -ForegroundColor Yellow
    Write-Host "   Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor Gray
    Write-Host "   Then run: ngrok config add-authtoken YOUR_TOKEN" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "Continue without authtoken? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
}

# Kiểm tra port có đang được sử dụng không
Write-Host ""
Write-Host "🔍 Checking if port $Port is accessible..." -ForegroundColor Yellow
try {
    $testResponse = Invoke-WebRequest -Uri "http://localhost:$Port/v1/models" `
        -Headers @{"Authorization" = "Bearer your-api-key-1"} `
        -Method GET `
        -ErrorAction SilentlyContinue
    
    Write-Host "✅ Port $Port is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Cannot connect to localhost:$Port" -ForegroundColor Yellow
    Write-Host "   Make sure CLI Proxy API is running" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Chạy ngrok
Write-Host ""
Write-Host "🚀 Starting ngrok tunnel..." -ForegroundColor Yellow
Write-Host "   Port: $Port" -ForegroundColor Gray
Write-Host "   URL will be displayed below" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Start ngrok in background và capture output
$ngrokProcess = Start-Process -FilePath "ngrok" `
    -ArgumentList "http", $Port `
    -NoNewWindow `
    -PassThru `
    -RedirectStandardOutput "ngrok-output.txt" `
    -RedirectStandardError "ngrok-error.txt"

Start-Sleep -Seconds 3

# Lấy URL từ ngrok API
try {
    $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET
    if ($ngrokApi.tunnels.Count -gt 0) {
        $publicUrl = $ngrokApi.tunnels[0].public_url
        Write-Host "✅ ngrok tunnel is running!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Public URL: $publicUrl" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Yellow
        Write-Host "   1. Update New API Base URL to: $publicUrl" -ForegroundColor Gray
        Write-Host "   2. Test: curl $publicUrl/v1/models -H 'Authorization: Bearer your-api-key-1'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "⚠️  Note: URL will change when you restart ngrok" -ForegroundColor Yellow
        Write-Host "   For permanent URL, upgrade to ngrok paid plan" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press Ctrl+C to stop ngrok" -ForegroundColor Yellow
        
        # Wait for user to stop
        $ngrokProcess.WaitForExit()
    } else {
        Write-Host "⚠️  ngrok started but no tunnel found" -ForegroundColor Yellow
        Write-Host "   Check ngrok-output.txt for details" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Could not get ngrok URL from API" -ForegroundColor Yellow
    Write-Host "   Check http://localhost:4040 for ngrok dashboard" -ForegroundColor Gray
    Write-Host "   ngrok is running in background (PID: $($ngrokProcess.Id))" -ForegroundColor Gray
}

