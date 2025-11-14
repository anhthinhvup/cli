# Script tu dong cai dat ngrok cho Windows
# Usage: .\install-ngrok.ps1

Write-Host "=== Installing ngrok ===" -ForegroundColor Cyan
Write-Host ""

# Tao thu muc ngrok
$ngrokDir = "$env:USERPROFILE\ngrok"
if (-not (Test-Path $ngrokDir)) {
    New-Item -ItemType Directory -Path $ngrokDir -Force | Out-Null
}

# Download ngrok
Write-Host "Downloading ngrok..." -ForegroundColor Yellow
$downloadUrl = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
$zipPath = "$env:TEMP\ngrok.zip"
$exePath = "$ngrokDir\ngrok.exe"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Download complete" -ForegroundColor Green
} catch {
    Write-Host "Failed to download ngrok" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://ngrok.com/download" -ForegroundColor Gray
    Write-Host "2. Download Windows version" -ForegroundColor Gray
    Write-Host "3. Extract to: $ngrokDir" -ForegroundColor Gray
    exit 1
}

# Extract
Write-Host ""
Write-Host "Extracting ngrok..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $zipPath -DestinationPath $ngrokDir -Force
    Write-Host "Extraction complete" -ForegroundColor Green
} catch {
    Write-Host "Failed to extract" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Add to PATH
Write-Host ""
Write-Host "Adding ngrok to PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$ngrokDir*") {
    $newPath = "$currentPath;$ngrokDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path += ";$ngrokDir"
    Write-Host "Added to PATH" -ForegroundColor Green
    Write-Host "Note: You may need to restart PowerShell for PATH changes to take effect" -ForegroundColor Yellow
} else {
    Write-Host "Already in PATH" -ForegroundColor Green
}

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Yellow
try {
    $version = & "$exePath" version
    Write-Host "ngrok installed successfully!" -ForegroundColor Green
    Write-Host "Version: $version" -ForegroundColor Cyan
    Write-Host "Location: $exePath" -ForegroundColor Cyan
} catch {
    Write-Host "Installation complete but verification failed" -ForegroundColor Yellow
    Write-Host "Try running: ngrok version" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor Gray
Write-Host "2. Run: ngrok config add-authtoken YOUR_TOKEN" -ForegroundColor Gray
Write-Host "3. Run: .\setup-ngrok.ps1" -ForegroundColor Gray
Write-Host ""
