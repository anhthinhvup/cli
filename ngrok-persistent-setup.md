# Giải pháp để ngrok chạy liên tục (không mất khi shutdown)

## Vấn đề

Khi bạn shutdown máy tính:
- ❌ ngrok sẽ dừng
- ❌ URL sẽ mất
- ❌ langhit.com không thể truy cập được
- ❌ Khi khởi động lại, URL sẽ thay đổi

## Giải pháp

### Option 1: Chạy ngrok trên Server/VPS (Khuyến nghị)

**Ưu điểm:**
- ✅ Server chạy 24/7
- ✅ URL ổn định
- ✅ Không bị ảnh hưởng khi shutdown máy local

**Cách làm:**
1. Deploy CLI Proxy API lên VPS/Server
2. Chạy ngrok trên server đó
3. URL sẽ luôn hoạt động

### Option 2: Dùng Cloudflare Tunnel (Miễn phí, ổn định hơn)

**Ưu điểm:**
- ✅ Miễn phí
- ✅ Ổn định hơn ngrok
- ✅ Có thể chạy như service tự động

**Cách setup:**
```powershell
# Cài đặt cloudflared
.\setup-cloudflare-tunnel.ps1 -Install

# Tạo named tunnel (URL ổn định)
cloudflared tunnel login
cloudflared tunnel create gpt51-api
cloudflared tunnel run gpt51-api
```

### Option 3: Chạy ngrok như Windows Service (Tự động khởi động)

**Ưu điểm:**
- ✅ Tự động chạy khi khởi động máy
- ✅ Chạy ngầm, không cần mở terminal

**Cách setup:**

#### 3.1: Dùng NSSM (Non-Sucking Service Manager)

```powershell
# Download NSSM
# https://nssm.cc/download

# Tạo service
nssm install ngrok "C:\Users\phamv\ngrok\ngrok.exe" "http 8317"
nssm set ngrok AppDirectory "C:\Users\phamv\ngrok"
nssm set ngrok DisplayName "ngrok Tunnel"
nssm set ngrok Description "ngrok tunnel for CLI Proxy API"
nssm start ngrok
```

#### 3.2: Dùng Task Scheduler (Windows)

1. Mở Task Scheduler
2. Create Basic Task
3. Trigger: "When the computer starts"
4. Action: Start a program
   - Program: `C:\Users\phamv\ngrok\ngrok.exe`
   - Arguments: `http 8317`
   - Start in: `C:\Users\phamv\ngrok`
5. Save

### Option 4: Chạy trên Docker với restart policy

Nếu CLI Proxy API chạy trong Docker:

```yaml
# docker-compose.yml
services:
  ngrok:
    image: ngrok/ngrok:latest
    command: http cli-proxy-api:8317
    restart: unless-stopped
    environment:
      - NGROK_AUTHTOKEN=your-token
    networks:
      - ai-network

networks:
  ai-network:
    external: true
```

### Option 5: Dùng ngrok với static domain (Paid)

Nếu có ngrok account paid:
- Có thể set static domain
- URL không thay đổi
- Vẫn cần server chạy 24/7

## So sánh các giải pháp

| Giải pháp | Chi phí | Ổn định | Khó setup | Phù hợp |
|-----------|---------|---------|-----------|---------|
| **VPS/Server** | ~$5-10/tháng | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Production |
| **Cloudflare Tunnel** | Miễn phí | ⭐⭐⭐⭐ | ⭐⭐ | Production/Dev |
| **Windows Service** | Miễn phí | ⭐⭐⭐ | ⭐⭐⭐⭐ | Development |
| **Docker restart** | Miễn phí | ⭐⭐⭐ | ⭐⭐ | Development |
| **ngrok static** | Paid | ⭐⭐⭐⭐ | ⭐⭐ | Production |

## Khuyến nghị

### Development/Testing:
- Dùng **Windows Service** hoặc **Docker restart**
- Chấp nhận URL thay đổi khi restart

### Production:
- **Option 1**: Deploy lên VPS + ngrok
- **Option 2**: Dùng **Cloudflare Tunnel** (miễn phí, ổn định)

## Script tự động setup Windows Service

Tôi đã tạo script `setup-ngrok-service.ps1` để tự động setup ngrok như Windows service.

