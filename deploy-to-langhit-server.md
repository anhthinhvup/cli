# Hướng dẫn Deploy CLI Proxy API lên Server Langhit.com

## Tổng quan

Deploy CLI Proxy API lên cùng server với langhit.com, không cần domain riêng.

## Option 1: Dùng IP + Port (Đơn giản nhất)

### Bước 1: Deploy CLI Proxy API lên server

**Trên server langhit.com:**

```bash
# SSH vào server
ssh user@langhit-server-ip

# Tạo thư mục
mkdir -p /opt/cli-proxy-api
cd /opt/cli-proxy-api

# Upload code (từ máy local)
# Hoặc git clone
git clone https://github.com/your-repo/ai-cli-proxy-api.git .
```

### Bước 2: Cấu hình và chạy

```bash
# Copy config
cp config.example.yaml config.yaml

# Chỉnh sửa config
nano config.yaml
# - Set api-keys
# - Set secret-key

# Chạy với Docker
docker-compose up -d

# Hoặc chạy trực tiếp (nếu không dùng Docker)
./CLIProxyAPI
```

### Bước 3: Expose port

CLI Proxy API sẽ chạy trên port 8317. Có thể:
- Dùng trực tiếp: `http://YOUR_SERVER_IP:8317`
- Hoặc dùng reverse proxy (Nginx) để route qua port khác

### Bước 4: Cập nhật New API

Trong langhit.com, thêm channel với:
- **Base URL**: `http://localhost:8317` (nếu cùng server)
- Hoặc: `http://YOUR_SERVER_IP:8317` (nếu khác server)

## Option 2: Dùng Subdomain (Nếu có domain langhit.com)

### Bước 1: Tạo subdomain

Nếu bạn có domain `langhit.com`, tạo subdomain:
- `gpt51-api.langhit.com` → trỏ về server IP

### Bước 2: Setup Nginx reverse proxy

```nginx
# /etc/nginx/sites-available/gpt51-api.langhit.com
server {
    listen 80;
    server_name gpt51-api.langhit.com;
    
    location / {
        proxy_pass http://localhost:8317;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Bước 3: SSL với Let's Encrypt

```bash
sudo certbot --nginx -d gpt51-api.langhit.com
```

### Bước 4: Cập nhật New API

- **Base URL**: `https://gpt51-api.langhit.com`

## Option 3: Dùng ngrok trên Server (Không cần domain)

### Bước 1: Cài ngrok trên server

```bash
# SSH vào server
ssh user@langhit-server-ip

# Cài ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Cấu hình authtoken
ngrok config add-authtoken YOUR_TOKEN
```

### Bước 2: Chạy ngrok như service

```bash
sudo nano /etc/systemd/system/ngrok.service
```

Nội dung:
```ini
[Unit]
Description=ngrok tunnel for CLI Proxy API
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ngrok http 8317 --log=stdout
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable ngrok
sudo systemctl start ngrok
sudo systemctl status ngrok
```

### Bước 3: Lấy URL

```bash
# Xem URL
curl http://localhost:4040/api/tunnels | jq '.tunnels[0].public_url'
```

Hoặc mở: `http://YOUR_SERVER_IP:4040`

### Bước 4: Cập nhật New API

- **Base URL**: URL từ ngrok (ví dụ: `https://abc123.ngrok-free.app`)

## Option 4: Dùng Cloudflare Tunnel (Miễn phí, ổn định)

### Bước 1: Cài cloudflared trên server

```bash
# Download cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Login
cloudflared tunnel login
```

### Bước 2: Tạo tunnel

```bash
cloudflared tunnel create gpt51-api
```

### Bước 3: Cấu hình tunnel

```bash
# Tạo config
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

Nội dung:
```yaml
tunnel: gpt51-api
credentials-file: /root/.cloudflared/gpt51-api.json

ingress:
  - hostname: gpt51-api.langhit.com  # Nếu có domain
    service: http://localhost:8317
  - service: http_status:404
```

Hoặc quick tunnel (không cần domain):
```bash
cloudflared tunnel --url http://localhost:8317
```

### Bước 4: Chạy như service

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### Bước 5: Cập nhật New API

- **Base URL**: URL từ Cloudflare Tunnel

## Option 5: Dùng Docker Network (Nếu cả 2 chạy trong Docker)

### Bước 1: Tạo network chung

```bash
docker network create langhit-network
```

### Bước 2: Chạy CLI Proxy API

```bash
cd /opt/cli-proxy-api
docker-compose up -d
docker network connect langhit-network cli-proxy-api
```

### Bước 3: Chạy New API với network

Trong docker-compose.yml của New API, thêm:
```yaml
networks:
  - langhit-network
```

### Bước 4: Cập nhật New API

- **Base URL**: `http://cli-proxy-api:8317` (dùng container name)

## So sánh các options

| Option | Cần domain | Setup | Ổn định | Phù hợp |
|--------|------------|-------|---------|---------|
| **IP + Port** | ❌ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Đơn giản |
| **Subdomain** | ✅ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Production |
| **ngrok** | ❌ | ⭐⭐⭐ | ⭐⭐⭐ | Dev/Testing |
| **Cloudflare Tunnel** | ❌/✅ | ⭐⭐⭐ | ⭐⭐⭐⭐ | Production |
| **Docker Network** | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Production |

## Khuyến nghị

### Nếu có domain langhit.com:
→ **Option 2** (Subdomain) - Tốt nhất

### Nếu không có domain:
→ **Option 4** (Cloudflare Tunnel) - Miễn phí, ổn định
→ **Option 5** (Docker Network) - Nếu cả 2 chạy Docker

### Nếu đơn giản nhất:
→ **Option 1** (IP + Port) - Dùng trực tiếp IP

## Script tự động deploy

Tôi sẽ tạo script để tự động deploy lên server.

