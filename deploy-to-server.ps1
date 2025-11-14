# Script de upload va deploy CLI Proxy API len server langhit.com
# Usage: .\deploy-to-server.ps1 -ServerIP "123.45.67.89" -Username "root"

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [string]$Username = "root",
    [string]$ServerPath = "/opt/cli-proxy-api",
    [int]$Port = 22,
    [switch]$UseDocker = $true
)

Write-Host "=== Deploy CLI Proxy API to Server ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Server: $Username@$ServerIP" -ForegroundColor Yellow
Write-Host "Path: $ServerPath" -ForegroundColor Yellow
Write-Host ""

# Kiem tra SSH
Write-Host "Kiem tra SSH connection..." -ForegroundColor Yellow
try {
    $sshTest = ssh -o ConnectTimeout=5 -o BatchMode=yes "$Username@$ServerIP" "echo 'OK'" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Can ket noi SSH. Vui long:" -ForegroundColor Yellow
        Write-Host "1. Kiem tra IP va username" -ForegroundColor Gray
        Write-Host "2. Setup SSH key hoac nhap password" -ForegroundColor Gray
        exit 1
    }
    Write-Host "SSH connection OK" -ForegroundColor Green
} catch {
    Write-Host "Loi ket noi SSH" -ForegroundColor Red
    exit 1
}

# Tao thu muc tren server
Write-Host ""
Write-Host "Tao thu muc tren server..." -ForegroundColor Yellow
ssh "$Username@$ServerIP" "mkdir -p $ServerPath"

# Upload files
Write-Host ""
Write-Host "Dang upload files..." -ForegroundColor Yellow
$localPath = "D:\ai-cli-proxy-api-main\ai-cli-proxy-api-main"

# Upload bang SCP
Write-Host "Uploading files via SCP..." -ForegroundColor Gray
scp -r "$localPath\*" "$Username@$ServerIP`:$ServerPath/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Upload thanh cong!" -ForegroundColor Green
} else {
    Write-Host "Loi khi upload. Thu cach khac..." -ForegroundColor Yellow
    Write-Host "Vui long upload thu cong hoac dung git clone" -ForegroundColor Gray
}

# Setup tren server
Write-Host ""
Write-Host "Dang setup tren server..." -ForegroundColor Yellow

$setupScript = @"
cd $ServerPath

# Kiem tra Docker
if command -v docker &> /dev/null; then
    echo "Docker da duoc cai dat"
    
    # Chay voi Docker
    docker-compose down 2>/dev/null
    docker-compose up -d --build
    
    echo "CLI Proxy API da duoc chay voi Docker"
    docker-compose ps
else
    echo "Docker chua duoc cai dat"
    echo "Cai dat Docker hoac chay truc tiep:"
    echo "  ./CLIProxyAPI"
fi

# Kiem tra port
netstat -tlnp | grep 8317 || echo "Port 8317 chua mo"
"@

ssh "$Username@$ServerIP" $setupScript

Write-Host ""
Write-Host "=== THANH CONG ===" -ForegroundColor Green
Write-Host ""
Write-Host "CLI Proxy API da duoc deploy len server!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Server IP: $ServerIP" -ForegroundColor Yellow
Write-Host "Port: 8317" -ForegroundColor Yellow
Write-Host ""
Write-Host "Buoc tiep theo:" -ForegroundColor Cyan
Write-Host "1. Cap nhat Base URL trong New API:" -ForegroundColor Gray
Write-Host "   http://$ServerIP:8317" -ForegroundColor White
Write-Host "   hoac" -ForegroundColor Gray
Write-Host "   http://localhost:8317 (neu cung server)" -ForegroundColor White
Write-Host ""
Write-Host "2. Test API:" -ForegroundColor Gray
Write-Host "   curl http://$ServerIP:8317/v1/models -H 'Authorization: Bearer your-api-key-1'" -ForegroundColor White
Write-Host ""

