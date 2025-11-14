# Hướng dẫn Setup Reverse Proxy cho CLI Proxy API

## Tổng quan

Reverse proxy giúp expose CLI Proxy API ra ngoài internet với HTTPS, giúp langhit.com có thể truy cập từ xa.

## Option 1: Nginx (Khuyến nghị cho production)

### Bước 1: Cài đặt Nginx

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install nginx
```

**CentOS/RHEL:**
```bash
sudo yum install nginx
# hoặc
sudo dnf install nginx
```

### Bước 2: Copy cấu hình

```bash
# Copy file nginx.conf vào sites-available
sudo cp nginx.conf /etc/nginx/sites-available/cli-proxy-api

# Tạo symlink
sudo ln -s /etc/nginx/sites-available/cli-proxy-api /etc/nginx/sites-enabled/

# Hoặc thêm vào /etc/nginx/nginx.conf trong block http {}
```

### Bước 3: Chỉnh sửa cấu hình

1. **Thay đổi domain:**
```nginx
server_name gpt51-api.yourdomain.com;  # Thay yourdomain.com bằng domain của bạn
```

2. **Nếu CLI Proxy API chạy trong Docker:**
```nginx
upstream cli_proxy_api {
    server cli-proxy-api:8317;  # Dùng container name
    # hoặc
    server 172.17.0.1:8317;  # Dùng Docker bridge IP
}
```

3. **Cấu hình SSL:**

**Option A: Let's Encrypt (Miễn phí, khuyến nghị)**
```bash
# Cài đặt Certbot
sudo apt install certbot python3-certbot-nginx

# Lấy certificate
sudo certbot --nginx -d gpt51-api.yourdomain.com

# Auto-renewal đã được setup tự động
```

**Option B: Self-signed (Chỉ cho testing)**
```bash
# Tạo self-signed certificate
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/key.pem \
  -out /etc/nginx/ssl/cert.pem
```

### Bước 4: Test và reload

```bash
# Test cấu hình
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Hoặc restart
sudo systemctl restart nginx
```

### Bước 5: Kiểm tra

```bash
# Test từ local
curl https://gpt51-api.yourdomain.com/v1/models \
  -H "Authorization: Bearer your-api-key-1"

# Test từ browser
# https://gpt51-api.yourdomain.com/management.html
```

## Option 2: Traefik (Khuyến nghị cho Docker)

### Bước 1: Tạo Docker network

```bash
docker network create traefik-network
```

### Bước 2: Chạy Traefik

```bash
# Sử dụng docker-compose.traefik.yml
docker-compose -f docker-compose.traefik.yml up -d

# Hoặc chạy Traefik riêng
docker-compose -f traefik.yml up -d
```

### Bước 3: Cập nhật CLI Proxy API

Thêm labels vào `docker-compose.yml` của CLI Proxy API:

```yaml
services:
  cli-proxy-api:
    # ... existing config ...
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.cli-proxy-api-secure.rule=Host(`gpt51-api.yourdomain.com`)"
      - "traefik.http.routers.cli-proxy-api-secure.entrypoints=websecure"
      - "traefik.http.routers.cli-proxy-api-secure.tls.certresolver=letsencrypt"
      - "traefik.http.services.cli-proxy-api.loadbalancer.server.port=8317"
```

### Bước 4: Restart containers

```bash
docker-compose down
docker-compose up -d
```

### Bước 5: Kiểm tra

- Traefik Dashboard: http://your-server-ip:8080
- CLI Proxy API: https://gpt51-api.yourdomain.com

## Option 3: Caddy (Đơn giản nhất)

### Bước 1: Cài đặt Caddy

```bash
# Ubuntu/Debian
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### Bước 2: Tạo Caddyfile

```bash
sudo nano /etc/caddy/Caddyfile
```

Nội dung:
```
gpt51-api.yourdomain.com {
    reverse_proxy localhost:8317 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
    
    # WebSocket support
    handle /v1/ws {
        reverse_proxy localhost:8317 {
            header_up Upgrade {http.upgrade}
            header_up Connection {http.connection}
        }
    }
}
```

### Bước 3: Reload Caddy

```bash
sudo systemctl reload caddy
```

Caddy tự động lấy SSL certificate từ Let's Encrypt!

## Cấu hình Firewall

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

## Cập nhật New API (langhit.com)

Sau khi setup reverse proxy, cập nhật Base URL trong New API:

1. Vào **Channels** → Chọn channel GPT-5.1
2. Cập nhật **Base URL**: `https://gpt51-api.yourdomain.com`
3. Save

## Testing

```bash
# Test từ server
curl https://gpt51-api.yourdomain.com/v1/models \
  -H "Authorization: Bearer your-api-key-1"

# Test từ máy khác
curl https://gpt51-api.yourdomain.com/v1/chat/completions \
  -H "Authorization: Bearer your-api-key-1" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5.1",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Troubleshooting

### Lỗi: 502 Bad Gateway

**Nguyên nhân**: Nginx/Traefik không thể kết nối đến CLI Proxy API

**Giải pháp**:
- Kiểm tra CLI Proxy API có đang chạy: `docker ps | grep cli-proxy-api`
- Kiểm tra port: `netstat -tlnp | grep 8317`
- Nếu dùng Docker, đảm bảo cùng network hoặc expose port

### Lỗi: SSL certificate

**Giải pháp**:
- Kiểm tra DNS đã trỏ đúng về server
- Kiểm tra port 80 và 443 đã mở
- Với Let's Encrypt: `sudo certbot certificates`

### Lỗi: Connection timeout

**Giải pháp**:
- Tăng timeout trong Nginx/Traefik config
- Kiểm tra firewall rules
- Kiểm tra network connectivity

## Security Best Practices

1. **Restrict Management Panel:**
```nginx
location /management.html {
    allow 1.2.3.4;  # Your IP
    deny all;
    # ...
}
```

2. **Rate Limiting:**
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

location / {
    limit_req zone=api_limit burst=20;
    # ...
}
```

3. **IP Whitelist (nếu chỉ dùng nội bộ):**
```nginx
location / {
    allow 192.168.1.0/24;  # Internal network
    deny all;
    # ...
}
```

## So sánh các options

| Feature | Nginx | Traefik | Caddy |
|---------|-------|---------|-------|
| Độ khó | Trung bình | Dễ (với Docker) | Rất dễ |
| SSL tự động | Cần Certbot | Tự động | Tự động |
| Docker integration | Manual | Tự động | Manual |
| Performance | Cao | Trung bình | Trung bình |
| Phù hợp | Production | Docker stack | Quick setup |

## Kết luận

- **Production với nhiều services**: Dùng Traefik
- **Production đơn giản**: Dùng Nginx
- **Testing/Development**: Dùng Caddy

Sau khi setup xong, cập nhật Base URL trong New API và test!

