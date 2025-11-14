# Hướng dẫn Deploy CLI Proxy API chạy 24/7 (không cần máy tính bật)

## Vấn đề

- ❌ Máy tính tắt → ngrok dừng
- ❌ URL mất
- ❌ langhit.com không truy cập được

## Giải pháp: Deploy lên Server/VPS

### Option 1: VPS (Virtual Private Server) - Khuyến nghị

**Chi phí:** ~$5-10/tháng (DigitalOcean, Vultr, Linode, etc.)

**Ưu điểm:**
- ✅ Chạy 24/7
- ✅ URL ổn định
- ✅ Hiệu suất tốt
- ✅ Toàn quyền kiểm soát

**Các nhà cung cấp VPS phổ biến:**
1. **DigitalOcean** - $6/tháng (1GB RAM)
2. **Vultr** - $6/tháng (1GB RAM)
3. **Linode** - $5/tháng (1GB RAM)
4. **Hetzner** - €4/tháng (2GB RAM) - Rẻ nhất
5. **Contabo** - €4/tháng (4GB RAM) - Rẻ nhất EU

### Option 2: Cloud Services Free Tier

**Miễn phí nhưng có giới hạn**

#### 2.1: Railway.app
- ✅ Free tier: $5 credit/tháng
- ✅ Dễ deploy
- ✅ Auto HTTPS
- ⚠️ Sleep sau 30 phút không dùng (free tier)

#### 2.2: Render.com
- ✅ Free tier
- ✅ Auto HTTPS
- ⚠️ Sleep sau 15 phút không dùng

#### 2.3: Fly.io
- ✅ Free tier: 3 VMs
- ✅ Không sleep
- ✅ Auto HTTPS

### Option 3: Cloudflare Tunnel (Miễn phí)

**Cần một server/VPS nhỏ để chạy tunnel**

- ✅ Miễn phí
- ✅ URL ổn định
- ✅ HTTPS tự động
- ⚠️ Vẫn cần server để chạy CLI Proxy API

## Hướng dẫn Deploy lên VPS

### Bước 1: Mua VPS

1. Đăng ký tại một trong các nhà cung cấp trên
2. Tạo VPS (Ubuntu 22.04 LTS)
3. Lưu IP và root password

### Bước 2: Kết nối VPS

```bash
ssh root@YOUR_VPS_IP
```

### Bước 3: Cài đặt Docker

```bash
# Update system
apt update && apt upgrade -y

# Cài Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Cài Docker Compose
apt install docker-compose-plugin -y
```

### Bước 4: Upload code lên VPS

**Cách 1: Git clone**
```bash
cd /opt
git clone https://github.com/your-repo/ai-cli-proxy-api.git
cd ai-cli-proxy-api
```

**Cách 2: SCP từ máy local**
```powershell
# Trên Windows
scp -r D:\ai-cli-proxy-api-main root@YOUR_VPS_IP:/opt/ai-cli-proxy-api
```

### Bước 5: Cấu hình và chạy

```bash
cd /opt/ai-cli-proxy-api

# Tạo config.yaml từ example
cp config.example.yaml config.yaml

# Chỉnh sửa config.yaml
nano config.yaml
# - Set api-keys
# - Set secret-key cho management

# Chạy với Docker
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f
```

### Bước 6: Setup ngrok trên VPS

```bash
# Cài ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Cấu hình authtoken
ngrok config add-authtoken YOUR_TOKEN

# Chạy ngrok như service
sudo systemctl enable ngrok
sudo systemctl start ngrok
```

### Bước 7: Tạo systemd service cho ngrok

```bash
sudo nano /etc/systemd/system/ngrok.service
```

Nội dung:
```ini
[Unit]
Description=ngrok tunnel
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

## Hướng dẫn Deploy lên Railway.app (Miễn phí)

### Bước 1: Tạo tài khoản

1. Đăng ký: https://railway.app
2. Connect GitHub account

### Bước 2: Tạo project mới

1. New Project → Deploy from GitHub repo
2. Chọn repository (hoặc tạo mới)

### Bước 3: Cấu hình

1. Add environment variables:
   - `DEPLOY=production`
   - Các biến khác nếu cần

2. Railway tự động detect Dockerfile và deploy

### Bước 4: Lấy URL

- Railway tự động cung cấp HTTPS URL
- URL dạng: `https://your-app.railway.app`
- Không cần ngrok!

## Hướng dẫn Deploy lên Fly.io (Miễn phí, không sleep)

### Bước 1: Cài đặt Fly CLI

```bash
# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"

# Linux/Mac
curl -L https://fly.io/install.sh | sh
```

### Bước 2: Đăng nhập

```bash
fly auth login
```

### Bước 3: Tạo app

```bash
cd D:\ai-cli-proxy-api-main\ai-cli-proxy-api-main
fly launch
```

### Bước 4: Deploy

```bash
fly deploy
```

### Bước 5: Lấy URL

```bash
fly status
# URL sẽ là: https://your-app.fly.dev
```

## So sánh các options

| Option | Chi phí | Setup | Ổn định | Sleep | Phù hợp |
|--------|---------|-------|---------|-------|---------|
| **VPS** | $5-10/tháng | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | Production |
| **Railway** | Free/$5 | ⭐⭐ | ⭐⭐⭐⭐ | ⚠️ Free | Dev/Prod |
| **Render** | Free | ⭐⭐ | ⭐⭐⭐ | ⚠️ Free | Dev |
| **Fly.io** | Free | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | Dev/Prod |
| **Cloudflare Tunnel** | Free | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | Production |

## Khuyến nghị

### Nếu có ngân sách ($5-10/tháng):
→ **VPS** (DigitalOcean, Vultr) - Tốt nhất

### Nếu muốn miễn phí:
→ **Fly.io** - Không sleep, ổn định
→ **Railway** - Dễ setup, có sleep (free tier)

### Nếu đã có server:
→ **Cloudflare Tunnel** - Miễn phí, ổn định

## Script tự động deploy

Tôi đã tạo script `deploy-to-vps.sh` để tự động deploy lên VPS.

