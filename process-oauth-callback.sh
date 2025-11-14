#!/bin/bash
# Script to process OAuth callback from remote browser
# Usage: bash process-oauth-callback.sh "http://localhost:1455/auth/callback?code=...&state=..."

CALLBACK_URL="$1"

if [ -z "$CALLBACK_URL" ]; then
    echo "Usage: bash process-oauth-callback.sh 'CALLBACK_URL'"
    echo ""
    echo "Example:"
    echo "  bash process-oauth-callback.sh 'http://localhost:1455/auth/callback?code=ac_ABC123&state=xyz789'"
    exit 1
fi

# Extract code and state from URL
CODE=$(echo "$CALLBACK_URL" | grep -oP 'code=\K[^&]*')
STATE=$(echo "$CALLBACK_URL" | grep -oP 'state=\K[^&]*')

if [ -z "$CODE" ] || [ -z "$STATE" ]; then
    echo "Error: Could not extract code and state from URL"
    echo "URL format should be: http://localhost:1455/auth/callback?code=...&state=..."
    exit 1
fi

echo "Extracted:"
echo "  Code: $CODE"
echo "  State: $STATE"
echo ""

# Create callback file
CALLBACK_FILE="auths/.oauth-codex-$STATE.oauth"
mkdir -p auths

cat > "$CALLBACK_FILE" << EOF
{"code":"$CODE","state":"$STATE","error":""}
EOF

echo "✅ Created callback file: $CALLBACK_FILE"
echo ""
echo "Waiting for container to process..."
echo "Check logs: docker-compose logs -f cli-proxy-api"
echo ""

# Wait a bit and check if file was processed
sleep 3
if [ ! -f "$CALLBACK_FILE" ]; then
    echo "✅ Callback file was processed (file removed)"
    echo ""
    echo "Check if token was saved:"
    echo "  ls -la auths/codex-*.json"
else
    echo "⚠️  Callback file still exists, may need more time"
    echo "Check logs for errors"
fi

