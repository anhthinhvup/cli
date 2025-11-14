#!/bin/bash
# Setup script that prompts for API key
# Usage: cd /opt/cli && bash setup-with-key.sh

cd /opt/cli

echo "=== Setup CLI Proxy API ==="
echo ""

# Prompt for API key
read -p "Enter your API key: " API_KEY

if [ -z "$API_KEY" ]; then
    echo "Error: API key is required"
    exit 1
fi

# Create config.yaml
cat > config.yaml << EOF
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
  - "$API_KEY"

# Enable debug logging
debug: false

# Logging to file
logging-to-file: false

# Usage statistics
usage-statistics-enabled: false

# Proxy URL
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
    echo "Or: http://localhost:8317"
    echo ""
    echo "To view logs:"
    echo "  docker-compose logs -f"
    echo ""
    echo "To test API:"
    echo "  curl http://localhost:8317/v1/models -H 'Authorization: Bearer $API_KEY'"
    echo ""
else
    echo ""
    echo "❌ Error: CLI Proxy API failed to start"
    echo "Check logs:"
    echo "  docker-compose logs"
    exit 1
fi

