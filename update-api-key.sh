#!/bin/bash
# Script to update API key on server
# Usage: bash update-api-key.sh NEW_API_KEY

NEW_API_KEY="${1:-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}"

if [ -z "$NEW_API_KEY" ]; then
    echo "Usage: bash update-api-key.sh NEW_API_KEY"
    exit 1
fi

CONFIG_FILE="config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.yaml not found"
    exit 1
fi

# Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backed up config.yaml"

# Update API key
# Replace the old key with new one
sed -i "s/- \"sk-proj-[^\"]*\"/- \"$NEW_API_KEY\"/" "$CONFIG_FILE"

echo "✅ Updated API key in config.yaml"
echo ""

# Restart container
echo "Restarting container..."
docker-compose restart

echo ""
echo "✅ Done! Container restarted"
echo ""
echo "To test:"
echo "  curl http://localhost:8317/v1/models -H 'Authorization: Bearer $NEW_API_KEY'"
echo ""

