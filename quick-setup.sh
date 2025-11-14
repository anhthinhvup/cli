#!/bin/bash
# Quick setup script for CLI Proxy API
# Usage: cd /opt/cli && bash quick-setup.sh

cd /opt/cli

echo "=== Quick Setup CLI Proxy API ==="
echo ""

# Create config.yaml
cat > config.yaml << 'EOF'
# Server port
port: 8317

# Management API settings
remote-management:
  allow-remote: true
  secret-key: "my-management-key-2024"
  disable-control-panel: false

# Authentication directory
auth-dir: "~/.cli-proxy-api"

# API keys
api-keys:
  - "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"

# Enable debug logging
debug: false

# Logging to file
logging-to-file: false

# Usage statistics
usage-statistics-enabled: false

# Proxy URL (empty for no proxy)
proxy-url: ""

# Request retry
request-retry: 3

# Quota exceeded behavior
quota-exceeded:
  switch-project: true
  switch-preview-model: true

# WebSocket auth
ws-auth: false
EOF

echo "✅ Created config.yaml"
echo ""

# Create directories
mkdir -p auths logs
echo "✅ Created directories"
echo ""

# Run Docker Compose
echo "Starting CLI Proxy API..."
docker-compose down 2>/dev/null || true
docker-compose up -d --build

# Wait and check
sleep 5
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "=== SUCCESS ==="
    echo ""
    echo "CLI Proxy API is running!"
    echo ""
    docker-compose ps
    echo ""
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "URL: http://$SERVER_IP:8317"
    echo "Or: http://localhost:8317 (if same server)"
    echo ""
    echo "To view logs:"
    echo "  docker-compose logs -f"
    echo ""
    echo "To test API:"
    echo "  curl http://localhost:8317/v1/models -H 'Authorization: Bearer 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'"
    echo ""
else
    echo ""
    echo "❌ Error: CLI Proxy API failed to start"
    echo "Check logs:"
    echo "  docker-compose logs"
    exit 1
fi

