# Script setup Docker network cho CLI Proxy API và New API
# Usage: .\setup-docker-network.ps1

param(
    [string]$NetworkName = "ai-network",
    [string]$CliProxyContainer = "cli-proxy-api",
    [string]$NewApiContainer = "new-api"
)

Write-Host "=== Setup Docker Network for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker first." -ForegroundColor Red
    exit 1
}

# Kiểm tra network đã tồn tại chưa
Write-Host ""
Write-Host "🔍 Checking Docker network: $NetworkName" -ForegroundColor Yellow
$networkExists = docker network ls --filter "name=$NetworkName" --format "{{.Name}}"
if ($networkExists -eq $NetworkName) {
    Write-Host "✅ Network '$NetworkName' already exists" -ForegroundColor Green
} else {
    Write-Host "📦 Creating Docker network: $NetworkName" -ForegroundColor Yellow
    docker network create $NetworkName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Network created" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create network" -ForegroundColor Red
        exit 1
    }
}

# Kiểm tra containers
Write-Host ""
Write-Host "🔍 Checking containers..." -ForegroundColor Yellow

$cliProxyExists = docker ps -a --filter "name=$CliProxyContainer" --format "{{.Names}}"
if ($cliProxyExists -eq $CliProxyContainer) {
    Write-Host "✅ Found container: $CliProxyContainer" -ForegroundColor Green
    
    # Kiểm tra đã kết nối network chưa
    $connected = docker network inspect $NetworkName --format "{{range .Containers}}{{.Name}}{{end}}" | Select-String $CliProxyContainer
    if ($connected) {
        Write-Host "   Already connected to network" -ForegroundColor Gray
    } else {
        Write-Host "📡 Connecting $CliProxyContainer to network..." -ForegroundColor Yellow
        docker network connect $NetworkName $CliProxyContainer
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Connected" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to connect (container might be stopped)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️  Container '$CliProxyContainer' not found" -ForegroundColor Yellow
    Write-Host "   Make sure CLI Proxy API is running" -ForegroundColor Gray
}

$newApiExists = docker ps -a --filter "name=$NewApiContainer" --format "{{.Names}}"
if ($newApiExists -eq $NewApiContainer) {
    Write-Host "✅ Found container: $NewApiContainer" -ForegroundColor Green
    
    # Kiểm tra đã kết nối network chưa
    $connected = docker network inspect $NetworkName --format "{{range .Containers}}{{.Name}}{{end}}" | Select-String $NewApiContainer
    if ($connected) {
        Write-Host "   Already connected to network" -ForegroundColor Gray
    } else {
        Write-Host "📡 Connecting $NewApiContainer to network..." -ForegroundColor Yellow
        docker network connect $NetworkName $NewApiContainer
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Connected" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to connect (container might be stopped)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️  Container '$NewApiContainer' not found" -ForegroundColor Yellow
    Write-Host "   This is OK if New API is not running yet" -ForegroundColor Gray
}

# Hiển thị network info
Write-Host ""
Write-Host "📋 Network Information:" -ForegroundColor Cyan
docker network inspect $NetworkName --format @"
Network: {{.Name}}
ID: {{.Id}}
Driver: {{.Driver}}
Containers:
{{range .Containers}}
  - {{.Name}} ({{.IPv4Address}})
{{end}}
"@

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Update New API Base URL to: http://$CliProxyContainer:8317" -ForegroundColor Gray
Write-Host "   2. Restart containers if needed:" -ForegroundColor Gray
Write-Host "      docker restart $CliProxyContainer" -ForegroundColor White
Write-Host "      docker restart $NewApiContainer" -ForegroundColor White
Write-Host ""
Write-Host "💡 To test connectivity from New API container:" -ForegroundColor Yellow
Write-Host "   docker exec $NewApiContainer curl http://$CliProxyContainer:8317/v1/models" -ForegroundColor White
Write-Host ""

