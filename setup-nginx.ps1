# Script tự động setup Nginx reverse proxy cho CLI Proxy API
# Usage: .\setup-nginx.ps1 -Domain "gpt51-api.yourdomain.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [string]$Email = "admin@yourdomain.com",
    [string]$NginxConfigPath = "/etc/nginx/sites-available/cli-proxy-api",
    [switch]$UseDocker = $false,
    [string]$DockerContainerName = "cli-proxy-api"
)

Write-Host "=== Setup Nginx Reverse Proxy for CLI Proxy API ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra quyền admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  Script này cần quyền Administrator trên Linux/WSL" -ForegroundColor Yellow
    Write-Host "   Trên Windows, bạn cần chạy Nginx trên WSL hoặc Linux server" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Hướng dẫn:" -ForegroundColor Cyan
    Write-Host "   1. Copy file nginx.conf lên Linux server" -ForegroundColor Gray
    Write-Host "   2. Chỉnh sửa domain trong file" -ForegroundColor Gray
    Write-Host "   3. Chạy các lệnh sau trên Linux:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   sudo cp nginx.conf /etc/nginx/sites-available/cli-proxy-api" -ForegroundColor White
    Write-Host "   sudo ln -s /etc/nginx/sites-available/cli-proxy-api /etc/nginx/sites-enabled/" -ForegroundColor White
    Write-Host "   sudo certbot --nginx -d $Domain" -ForegroundColor White
    Write-Host "   sudo nginx -t && sudo systemctl reload nginx" -ForegroundColor White
    exit 0
}

Write-Host "📝 Domain: $Domain" -ForegroundColor Yellow
Write-Host "📧 Email: $Email" -ForegroundColor Yellow
Write-Host ""

# Tạo nginx config với domain đã chỉnh sửa
$nginxConfig = Get-Content "nginx.conf" -Raw
$nginxConfig = $nginxConfig -replace "gpt51-api\.yourdomain\.com", $Domain

if ($UseDocker) {
    Write-Host "🐳 Using Docker container: $DockerContainerName" -ForegroundColor Yellow
    $nginxConfig = $nginxConfig -replace "server localhost:8317;", "server $DockerContainerName:8317;"
} else {
    Write-Host "💻 Using localhost:8317" -ForegroundColor Yellow
}

# Lưu config đã chỉnh sửa
$tempConfig = "nginx-${Domain}.conf"
$nginxConfig | Out-File -FilePath $tempConfig -Encoding UTF8

Write-Host ""
Write-Host "✅ Đã tạo file cấu hình: $tempConfig" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Các bước tiếp theo trên Linux server:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Copy file lên server:" -ForegroundColor Yellow
Write-Host "   scp $tempConfig user@server:/tmp/nginx.conf" -ForegroundColor White
Write-Host ""
Write-Host "2. SSH vào server và chạy:" -ForegroundColor Yellow
Write-Host "   sudo cp /tmp/nginx.conf $NginxConfigPath" -ForegroundColor White
Write-Host "   sudo ln -s $NginxConfigPath /etc/nginx/sites-enabled/cli-proxy-api" -ForegroundColor White
Write-Host ""
Write-Host "3. Test cấu hình:" -ForegroundColor Yellow
Write-Host "   sudo nginx -t" -ForegroundColor White
Write-Host ""
Write-Host "4. Setup SSL với Let's Encrypt:" -ForegroundColor Yellow
Write-Host "   sudo apt install certbot python3-certbot-nginx" -ForegroundColor White
Write-Host "   sudo certbot --nginx -d $Domain -m $Email" -ForegroundColor White
Write-Host ""
Write-Host "5. Reload Nginx:" -ForegroundColor Yellow
Write-Host "   sudo systemctl reload nginx" -ForegroundColor White
Write-Host ""
Write-Host "6. Test:" -ForegroundColor Yellow
Write-Host "   curl https://$Domain/v1/models -H 'Authorization: Bearer your-api-key-1'" -ForegroundColor White
Write-Host ""

Write-Host "✅ Hoàn thành!" -ForegroundColor Green

