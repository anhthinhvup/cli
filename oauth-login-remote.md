# Hướng dẫn Login OAuth từ xa (Server không có browser)

## Vấn đề

Khi chạy `docker exec -it cli-proxy-api ./CLIProxyAPI --codex-login` trên server, script sẽ hiển thị OAuth URL nhưng server không có browser để mở.

## Giải pháp: Login từ máy local

### Bước 1: Chạy OAuth login trên server

```bash
docker exec -it cli-proxy-api ./CLIProxyAPI --codex-login
```

Bạn sẽ thấy output như:
```
Visit the following URL to continue authentication:
https://auth.openai.com/oauth/authorize?client_id=...&state=...

Waiting for Codex authentication callback...
```

### Bước 2: Copy OAuth URL

Copy toàn bộ URL từ output (bắt đầu từ `https://auth.openai.com/...`)

### Bước 3: Mở URL trên máy local

1. Paste URL vào browser trên máy local
2. Đăng nhập với ChatGPT Plus account
3. Authorize ứng dụng

### Bước 4: Lấy callback URL

Sau khi authorize, browser sẽ redirect đến URL dạng:
```
http://localhost:1455/auth/callback?code=ac_...&state=...
```

**Copy toàn bộ URL này** (bao gồm cả `http://localhost:1455/auth/callback?...`)

### Bước 5: Tạo callback file trên server

Trên server, tạo file callback:

```bash
# Lấy code và state từ callback URL
# Ví dụ: code=ac_ABC123&state=xyz789

cd /opt/cli
cat > auths/.oauth-codex-STATE_HERE.oauth << EOF
{"code":"CODE_HERE","state":"STATE_HERE","error":""}
EOF
```

Thay `STATE_HERE` và `CODE_HERE` bằng giá trị thực từ callback URL.

### Bước 6: Đợi xử lý

Container sẽ tự động phát hiện file và xử lý. Kiểm tra logs:

```bash
docker-compose logs -f cli-proxy-api
```

Bạn sẽ thấy:
```
Codex authentication successful
Saving credentials to /root/.cli-proxy-api/codex-email@example.com.json
```

### Bước 7: Test lại

```bash
curl http://localhost:8317/v1/models -H "Authorization: Bearer YOUR_API_KEY"
```

Bây giờ bạn sẽ thấy các GPT-5.1 models trong danh sách!

## Script tự động (sẽ tạo sau)

Tôi sẽ tạo script để tự động xử lý callback URL.

