# Hướng dẫn Setup CLI Proxy API không cần Domain

## Tổng quan

Nếu bạn không có domain, có nhiều cách để expose CLI Proxy API cho langhit.com truy cập.

## Option 1: Dùng IP Public trực tiếp (Đơn giản nhất)

### Nếu cả 2 chạy trên cùng server

**Cách 1: Dùng localhost (Khuyến nghị)**
- New API và CLI Proxy API cùng server
- Base URL: `http://localhost:8317` hoặc `http://127.0.0.1:8317`

**Cách 2: Dùng Docker network**
- Nếu cả 2 chạy trong Docker
- Base URL: `http://cli-proxy-api:8317` (dùng container name)

### Nếu khác server

1. **Lấy IP public của server CLI Proxy API:**
```bash
# Trên server CLI Proxy API
curl ifconfig.me
# hoặc
curl ipinfo.io/ip
```

2. **Mở port 8317 trên firewall:**
```bash
# Ubuntu/Debian
sudo ufw allow 8317/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8317/tcp
sudo firewall-cmd --reload
```

3. **Cập nhật New API:**
- Base URL: `http://YOUR_SERVER_IP:8317`
- Ví dụ: `http://123.45.67.89:8317`

⚠️ **Lưu ý**: Không có HTTPS, chỉ dùng HTTP. Không an toàn cho production.

## Option 2: Dùng ngrok (Temporary domain miễn phí)

### Bước 1: Cài đặt ngrok

**Windows:**
```powershell
# Download từ https://ngrok.com/download
# Hoặc dùng Chocolatey
choco install ngrok
```

**Linux:**
```bash
# Download và cài đặt
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Hoặc download trực tiếp
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/
```

### Bước 2: Đăng ký và lấy token

1. Đăng ký tại: https://dashboard.ngrok.com/signup
2. Lấy authtoken từ dashboard
3. Cấu hình:
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### Bước 3: Chạy ngrok

```bash
# Expose port 8317
ngrok http 8317

# Hoặc với custom domain (cần account paid)
ngrok http 8317 --domain=your-custom-domain.ngrok-free.app
```

Bạn sẽ nhận được URL như: `https://abc123.ngrok-free.app`

### Bước 4: Cập nhật New API

- Base URL: `https://abc123.ngrok-free.app`

⚠️ **Lưu ý**: 
- Free plan có giới hạn requests
- URL thay đổi mỗi lần restart (trừ khi dùng custom domain)
- Có thể bị rate limit

### Bước 5: Chạy ngrok như service (Linux)

```bash
# Tạo systemd service
sudo nano /etc/systemd/system/ngrok.service
```

Nội dung:
```ini
[Unit]
Description=ngrok
After=network.target

[Service]
Type=simple
User=your-user
ExecStart=/usr/local/bin/ngrok http 8317 --log=stdout
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable ngrok
sudo systemctl start ngrok
sudo systemctl status ngrok
```

## Option 3: Cloudflare Tunnel (Miễn phí, ổn định hơn)

### Bước 1: Cài đặt cloudflared

**Windows:**
```powershell
# Download từ https://github.com/cloudflare/cloudflared/releases
# Hoặc dùng Chocolatey
choco install cloudflared
```

**Linux:**
```bash
# Ubuntu/Debian
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Hoặc dùng package manager
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
```

### Bước 2: Đăng nhập Cloudflare

```bash
cloudflared tunnel login
```

### Bước 3: Tạo tunnel

```bash
# Tạo tunnel mới
cloudflared tunnel create gpt51-api

# List tunnels
cloudflared tunnel list
```

### Bước 4: Cấu hình tunnel

```bash
# Tạo config file
cloudflared tunnel route dns gpt51-api gpt51-api.yourdomain.com

# Hoặc dùng quick tunnel (không cần domain)
cloudflared tunnel --url http://localhost:8317
```

Bạn sẽ nhận được URL như: `https://gpt51-api-xxxxx.trycloudflare.com`

### Bước 5: Chạy tunnel

```bash
# Quick tunnel (tạm thời)
cloudflared tunnel --url http://localhost:8317

# Named tunnel (vĩnh viễn)
cloudflared tunnel run gpt51-api
```

### Bước 6: Chạy như service

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## Option 4: Dùng Docker Network (Nếu cả 2 chạy trong Docker)

### Bước 1: Tạo Docker network chung

```bash
docker network create ai-network
```

### Bước 2: Kết nối containers

```bash
# Kết nối CLI Proxy API
docker network connect ai-network cli-proxy-api

# Kết nối New API
docker network connect ai-network new-api
```

### Bước 3: Cập nhật New API

- Base URL: `http://cli-proxy-api:8317`

### Bước 4: Cập nhật docker-compose.yml

**CLI Proxy API:**
```yaml
services:
  cli-proxy-api:
    # ... existing config ...
    networks:
      - ai-network

networks:
  ai-network:
    external: true
```

**New API:**
```yaml
services:
  new-api:
    # ... existing config ...
    networks:
      - ai-network

networks:
  ai-network:
    external: true
```

## So sánh các options

| Option | Ưu điểm | Nhược điểm | Phù hợp |
|--------|---------|------------|---------|
| **IP Public** | Đơn giản, không cần setup | Không có HTTPS, không an toàn | Testing, internal network |
| **ngrok** | Dễ setup, có HTTPS | URL thay đổi, rate limit | Development, testing |
| **Cloudflare Tunnel** | Miễn phí, ổn định, HTTPS | Cần setup | Production, development |
| **Docker Network** | Nhanh, không expose ra ngoài | Chỉ dùng khi cùng server | Local development |

## Khuyến nghị

1. **Development/Testing**: Dùng **Docker Network** hoặc **ngrok**
2. **Production (cùng server)**: Dùng **Docker Network**
3. **Production (khác server)**: Dùng **Cloudflare Tunnel** hoặc mua domain + Nginx

## Script tự động

Tôi đã tạo script `setup-ngrok.ps1` và `setup-cloudflare.ps1` để tự động setup.

## Troubleshooting

### Lỗi: Connection refused

**Giải pháp**:
- Kiểm tra firewall: `sudo ufw status`
- Kiểm tra port: `netstat -tlnp | grep 8317`
- Kiểm tra Docker network: `docker network inspect ai-network`

### Lỗi: ngrok rate limit

**Giải pháp**:
- Upgrade lên paid plan
- Hoặc dùng Cloudflare Tunnel

### Lỗi: Cloudflare tunnel không kết nối

**Giải pháp**:
- Kiểm tra tunnel đã login: `cloudflared tunnel list`
- Kiểm tra config: `~/.cloudflared/config.yml`
- Restart service: `sudo systemctl restart cloudflared`

