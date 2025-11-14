# Script de cai dat ngrok nhu Windows Task (Task Scheduler)
# Usage: .\setup-ngrok-task.ps1

param(
    [int]$Port = 8317,
    [string]$TaskName = "ngrok-tunnel"
)

Write-Host "=== Setup ngrok as Windows Task ===" -ForegroundColor Cyan
Write-Host ""

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

# Kiem tra task da ton tai
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Task '$TaskName' da ton tai" -ForegroundColor Yellow
    $remove = Read-Host "Xoa task cu va tao lai? (y/n)"
    if ($remove -eq "y") {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Da xoa task cu" -ForegroundColor Green
    } else {
        exit 0
    }
}

# Tao task
Write-Host "Dang tao Scheduled Task..." -ForegroundColor Yellow

$action = New-ScheduledTaskAction -Execute $ngrokPath -Argument "http $Port" -WorkingDirectory (Split-Path $ngrokPath -Parent)
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "ngrok tunnel for CLI Proxy API on port $Port" | Out-Null

Write-Host "Task da duoc tao!" -ForegroundColor Green
Write-Host ""

# Test run
Write-Host "Dang test chay task..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 5

$taskStatus = Get-ScheduledTaskInfo -TaskName $TaskName
if ($taskStatus.LastRunTime) {
    Write-Host "Task da chay!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== THANH CONG ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "ngrok se tu dong chay khi khoi dong may" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "De xem URL:" -ForegroundColor Yellow
    Write-Host "   - Mo browser: http://localhost:4040" -ForegroundColor White
    Write-Host ""
    Write-Host "Cac lenh quan ly:" -ForegroundColor Yellow
    Write-Host "   Start:   Start-ScheduledTask -TaskName $TaskName" -ForegroundColor White
    Write-Host "   Stop:    Stop-ScheduledTask -TaskName $TaskName" -ForegroundColor White
    Write-Host "   Status:  Get-ScheduledTaskInfo -TaskName $TaskName" -ForegroundColor White
    Write-Host "   Remove:  Unregister-ScheduledTask -TaskName $TaskName -Confirm:`$false" -ForegroundColor White
} else {
    Write-Host "Loi: Task khong the chay" -ForegroundColor Red
    Write-Host "Kiem tra Task Scheduler" -ForegroundColor Yellow
}

