# Script setup Cloudflare Tunnel cho CLI Proxy API
# Usage: .\setup-cloudflare-tunnel.ps1

param(
    [int]$Port = 8317,
    [string]$TunnelName = "gpt51-api",
    [switch]$Install = $false,
    [switch]$QuickTunnel = $false
)

Write-Host "=== Setup Cloudflare Tunnel for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra cloudflared đã cài đặt chưa
$cloudflaredInstalled = $false
try {
    $version = cloudflared --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $cloudflaredInstalled = $true
        Write-Host "✅ cloudflared is installed: $version" -ForegroundColor Green
    }
} catch {
    $cloudflaredInstalled = $false
}

if (-not $cloudflaredInstalled) {
    if ($Install) {
        Write-Host "📦 Installing cloudflared..." -ForegroundColor Yellow
        
        # Windows: Download và extract
        $downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
        $installPath = "$env:ProgramFiles\cloudflared\cloudflared.exe"
        $installDir = Split-Path $installPath
        
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        
        Write-Host "Downloading cloudflared..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installPath
        
        # Add to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
            $env:Path += ";$installDir"
        }
        
        Write-Host "✅ cloudflared installed to $installPath" -ForegroundColor Green
    } else {
        Write-Host "❌ cloudflared is not installed" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 To install:" -ForegroundColor Yellow
        Write-Host "   .\setup-cloudflare-tunnel.ps1 -Install" -ForegroundColor White
        Write-Host "   Or download from: https://github.com/cloudflare/cloudflared/releases" -ForegroundColor Gray
        exit 1
    }
}

# Quick tunnel mode
if ($QuickTunnel) {
    Write-Host ""
    Write-Host "🚀 Starting Cloudflare quick tunnel..." -ForegroundColor Yellow
    Write-Host "   Port: $Port" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This will give you a temporary URL" -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    cloudflared tunnel --url "http://localhost:$Port"
    exit 0
}

# Named tunnel mode
Write-Host ""
Write-Host "📝 Setting up named tunnel: $TunnelName" -ForegroundColor Yellow
Write-Host ""

# Kiểm tra đã login chưa
Write-Host "🔍 Checking Cloudflare login..." -ForegroundColor Yellow
try {
    $tunnels = cloudflared tunnel list 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Not logged in to Cloudflare" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please login first:" -ForegroundColor Yellow
        Write-Host "   cloudflared tunnel login" -ForegroundColor White
        Write-Host ""
        Write-Host "This will open a browser for authentication" -ForegroundColor Gray
        exit 1
    }
    Write-Host "✅ Logged in to Cloudflare" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Error checking login status" -ForegroundColor Yellow
    Write-Host "   Run: cloudflared tunnel login" -ForegroundColor Gray
    exit 1
}

# Kiểm tra tunnel đã tồn tại chưa
$tunnelExists = $false
try {
    $existingTunnels = cloudflared tunnel list 2>&1 | Out-String
    if ($existingTunnels -match $TunnelName) {
        $tunnelExists = $true
        Write-Host "✅ Tunnel '$TunnelName' already exists" -ForegroundColor Green
    }
} catch {
    # Ignore
}

if (-not $tunnelExists) {
    Write-Host ""
    Write-Host "📦 Creating tunnel: $TunnelName" -ForegroundColor Yellow
    cloudflared tunnel create $TunnelName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Tunnel created" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create tunnel" -ForegroundColor Red
        exit 1
    }
}

# Tạo config file
Write-Host ""
Write-Host "📝 Creating tunnel config..." -ForegroundColor Yellow

$configDir = "$env:USERPROFILE\.cloudflared"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$configFile = "$configDir\config.yml"
$configContent = @"
tunnel: $TunnelName
credentials-file: $configDir\$TunnelName.json

ingress:
  - hostname: $TunnelName.trycloudflare.com
    service: http://localhost:$Port
  - service: http_status:404
"@

$configContent | Out-File -FilePath $configFile -Encoding UTF8
Write-Host "✅ Config file created: $configFile" -ForegroundColor Green

# Chạy tunnel
Write-Host ""
Write-Host "🚀 Starting Cloudflare tunnel..." -ForegroundColor Yellow
Write-Host "   Tunnel: $TunnelName" -ForegroundColor Gray
Write-Host "   Port: $Port" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

cloudflared tunnel run $TunnelName

