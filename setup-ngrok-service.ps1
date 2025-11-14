# Script de cai dat ngrok nhu Windows Service
# Usage: .\setup-ngrok-service.ps1

param(
    [int]$Port = 8317,
    [string]$ServiceName = "ngrok-tunnel"
)

Write-Host "=== Setup ngrok as Windows Service ===" -ForegroundColor Cyan
Write-Host ""

# Kiem tra quyen admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Loi: Script nay can quyen Administrator" -ForegroundColor Red
    Write-Host "Vui long chay PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

# Tim ngrok
$ngrokPath = ""
$possiblePaths = @(
    "$env:USERPROFILE\ngrok\ngrok.exe",
    "$env:ProgramFiles\ngrok\ngrok.exe",
    "C:\ngrok\ngrok.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $ngrokPath = $path
        break
    }
}

if (-not $ngrokPath) {
    # Tim trong PATH
    try {
        $ngrokVersion = ngrok version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ngrokPath = (Get-Command ngrok).Source
        }
    } catch {
        # Not found
    }
}

if (-not $ngrokPath) {
    Write-Host "Khong tim thay ngrok!" -ForegroundColor Red
    Write-Host "Vui long cai dat ngrok truoc:" -ForegroundColor Yellow
    Write-Host "   .\install-ngrok.ps1" -ForegroundColor White
    exit 1
}

Write-Host "Tim thay ngrok: $ngrokPath" -ForegroundColor Green
Write-Host ""

# Kiem tra NSSM
$nssmPath = ""
$nssmPossiblePaths = @(
    "$env:ProgramFiles\nssm\nssm.exe",
    "$env:ProgramFiles(x86)\nssm\nssm.exe",
    "C:\nssm\nssm.exe"
)

foreach ($path in $nssmPossiblePaths) {
    if (Test-Path $path) {
        $nssmPath = $path
        break
    }
}

if (-not $nssmPath) {
    Write-Host "NSSM chua duoc cai dat" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Cach 1: Cai dat NSSM (khuyen nghi)" -ForegroundColor Cyan
    Write-Host "   1. Download: https://nssm.cc/download" -ForegroundColor Gray
    Write-Host "   2. Extract vao: C:\nssm" -ForegroundColor Gray
    Write-Host "   3. Chay lai script nay" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Cach 2: Dung Task Scheduler (khong can NSSM)" -ForegroundColor Cyan
    Write-Host "   Chay: .\setup-ngrok-task.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Tim thay NSSM: $nssmPath" -ForegroundColor Green
Write-Host ""

# Kiem tra service da ton tai chua
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Service '$ServiceName' da ton tai" -ForegroundColor Yellow
    $remove = Read-Host "Xoa service cu va tao lai? (y/n)"
    if ($remove -eq "y") {
        Stop-Service -Name $ServiceName -ErrorAction SilentlyContinue
        & $nssmPath remove $ServiceName confirm
        Write-Host "Da xoa service cu" -ForegroundColor Green
    } else {
        Write-Host "Huy bo" -ForegroundColor Yellow
        exit 0
    }
}

# Tao service
Write-Host "Dang tao Windows Service..." -ForegroundColor Yellow
$ngrokDir = Split-Path $ngrokPath -Parent

& $nssmPath install $ServiceName $ngrokPath "http $Port"
& $nssmPath set $ServiceName AppDirectory $ngrokDir
& $nssmPath set $ServiceName DisplayName "ngrok Tunnel (Port $Port)"
& $nssmPath set $ServiceName Description "ngrok tunnel for CLI Proxy API on port $Port"
& $nssmPath set $ServiceName Start SERVICE_AUTO_START
& $nssmPath set $ServiceName AppStdout "$ngrokDir\ngrok-service.log"
& $nssmPath set $ServiceName AppStderr "$ngrokDir\ngrok-service-error.log"

Write-Host "Service da duoc tao!" -ForegroundColor Green
Write-Host ""

# Start service
Write-Host "Dang khoi dong service..." -ForegroundColor Yellow
Start-Service -Name $ServiceName

Start-Sleep -Seconds 3

$serviceStatus = Get-Service -Name $ServiceName
if ($serviceStatus.Status -eq "Running") {
    Write-Host "Service dang chay!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== THANH CONG ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "ngrok se tu dong chay khi khoi dong may" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "De xem URL:" -ForegroundColor Yellow
    Write-Host "   - Mo browser: http://localhost:4040" -ForegroundColor White
    Write-Host "   - Hoac xem log: $ngrokDir\ngrok-service.log" -ForegroundColor White
    Write-Host ""
    Write-Host "Cac lenh quan ly:" -ForegroundColor Yellow
    Write-Host "   Start:   Start-Service -Name $ServiceName" -ForegroundColor White
    Write-Host "   Stop:    Stop-Service -Name $ServiceName" -ForegroundColor White
    Write-Host "   Status:  Get-Service -Name $ServiceName" -ForegroundColor White
    Write-Host "   Remove:  & '$nssmPath' remove $ServiceName confirm" -ForegroundColor White
} else {
    Write-Host "Loi: Service khong the khoi dong" -ForegroundColor Red
    Write-Host "Kiem tra log: $ngrokDir\ngrok-service-error.log" -ForegroundColor Yellow
}

