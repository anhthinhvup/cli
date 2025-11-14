# Script setup Traefik cho CLI Proxy API
# Usage: .\setup-traefik.ps1 -Domain "gpt51-api.yourdomain.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [string]$Email = "admin@yourdomain.com",
    [string]$NetworkName = "traefik-network"
)

Write-Host "=== Setup Traefik Reverse Proxy for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 Domain: $Domain" -ForegroundColor Yellow
Write-Host "📧 Email: $Email" -ForegroundColor Yellow
Write-Host ""

# Kiểm tra Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker first." -ForegroundColor Red
    exit 1
}

# Tạo network nếu chưa có
Write-Host ""
Write-Host "🔍 Checking Docker network..." -ForegroundColor Yellow
$networkExists = docker network ls --filter "name=$NetworkName" --format "{{.Name}}"
if ($networkExists -ne $NetworkName) {
    Write-Host "📦 Creating Docker network: $NetworkName" -ForegroundColor Yellow
    docker network create $NetworkName
    Write-Host "✅ Network created" -ForegroundColor Green
} else {
    Write-Host "✅ Network already exists" -ForegroundColor Green
}

# Cập nhật docker-compose.traefik.yml với domain
Write-Host ""
Write-Host "📝 Updating docker-compose.traefik.yml..." -ForegroundColor Yellow

$composeContent = Get-Content "docker-compose.traefik.yml" -Raw
$composeContent = $composeContent -replace "gpt51-api\.yourdomain\.com", $Domain
$composeContent = $composeContent -replace "your-email@example\.com", $Email

$composeContent | Out-File -FilePath "docker-compose.traefik.yml" -Encoding UTF8

Write-Host "✅ Updated docker-compose.traefik.yml" -ForegroundColor Green

# Cập nhật traefik.yml
Write-Host ""
Write-Host "📝 Updating traefik.yml..." -ForegroundColor Yellow

$traefikContent = Get-Content "traefik.yml" -Raw
$traefikContent = $traefikContent -replace "gpt51-api\.yourdomain\.com", $Domain
$traefikContent = $traefikContent -replace "your-email@example\.com", $Email

$traefikContent | Out-File -FilePath "traefik.yml" -Encoding UTF8

Write-Host "✅ Updated traefik.yml" -ForegroundColor Green

# Cập nhật docker-compose.yml chính với Traefik labels
Write-Host ""
Write-Host "📝 Adding Traefik labels to docker-compose.yml..." -ForegroundColor Yellow

$mainCompose = Get-Content "docker-compose.yml" -Raw

# Kiểm tra xem đã có labels chưa
if ($mainCompose -notmatch "traefik\.enable") {
    # Thêm network và labels
    $networkSection = @"

networks:
  traefik-network:
    external: true

"@
    
    $labelsSection = @"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.cli-proxy-api.rule=Host(`$Domain`)"
      - "traefik.http.routers.cli-proxy-api.entrypoints=web"
      - "traefik.http.routers.cli-proxy-api-secure.rule=Host(`$Domain`)"
      - "traefik.http.routers.cli-proxy-api-secure.entrypoints=websecure"
      - "traefik.http.routers.cli-proxy-api-secure.tls.certresolver=letsencrypt"
      - "traefik.http.services.cli-proxy-api.loadbalancer.server.port=8317"
      - "traefik.http.middlewares.cli-proxy-api-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.routers.cli-proxy-api-secure.middlewares=cli-proxy-api-headers"

"@
    
    # Thêm networks vào service
    $mainCompose = $mainCompose -replace "(container_name: cli-proxy-api)", "`$1`n    networks:`n      - traefik-network"
    
    # Thêm labels
    $mainCompose = $mainCompose -replace "(restart: unless-stopped)", "`$1`n$labelsSection"
    
    # Thêm networks section ở cuối
    if ($mainCompose -notmatch "networks:") {
        $mainCompose += $networkSection
    }
    
    # Replace domain placeholder
    $mainCompose = $mainCompose -replace '\$Domain', $Domain
    
    $mainCompose | Out-File -FilePath "docker-compose.yml" -Encoding UTF8
    Write-Host "✅ Added Traefik labels to docker-compose.yml" -ForegroundColor Green
} else {
    Write-Host "⚠️  Traefik labels already exist in docker-compose.yml" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start Traefik:" -ForegroundColor Yellow
Write-Host "   docker-compose -f traefik.yml up -d" -ForegroundColor White
Write-Host ""
Write-Host "2. Restart CLI Proxy API with Traefik:" -ForegroundColor Yellow
Write-Host "   docker-compose down" -ForegroundColor White
Write-Host "   docker-compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "3. Verify DNS points to your server:" -ForegroundColor Yellow
Write-Host "   nslookup $Domain" -ForegroundColor White
Write-Host ""
Write-Host "4. Test:" -ForegroundColor Yellow
Write-Host "   curl https://$Domain/v1/models -H 'Authorization: Bearer your-api-key-1'" -ForegroundColor White
Write-Host ""
Write-Host "5. Access Traefik Dashboard:" -ForegroundColor Yellow
Write-Host "   http://your-server-ip:8080" -ForegroundColor White
Write-Host ""

Write-Host "✅ Setup complete!" -ForegroundColor Green

