#!/bin/bash

# Cloudflare サブドメイン自動設定
# Usage: ./cloudflare-subdomain.sh [port] [subdomain] [domain]
# Example: ./cloudflare-subdomain.sh 3000 app sakana.hair

PORT=${1:-3000}
SUBDOMAIN=${2:-"app"}
DOMAIN=${3:-"sakana.hair"}
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
TUNNEL_NAME="tunnel-${SUBDOMAIN}-${DOMAIN//\./-}"

echo "🚀 Cloudflare サブドメイン自動設定"
echo "📌 URL: https://${FULL_DOMAIN}"
echo "🔌 ポート: localhost:$PORT"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared がインストールされていません"
    exit 1
fi

# Check if already logged in
if ! cloudflared tunnel list &> /dev/null; then
    echo "🔐 Cloudflareにログインしてください..."
    cloudflared tunnel login
fi

# Always delete existing tunnel and DNS first
echo "🗑️  既存の設定を削除中..."
cloudflared tunnel route dns -f $TUNNEL_NAME $FULL_DOMAIN 2>/dev/null || true
cloudflared tunnel delete -f $TUNNEL_NAME 2>/dev/null || true

# Create new tunnel
echo "🚇 新しいトンネルを作成中: $TUNNEL_NAME"
cloudflared tunnel create $TUNNEL_NAME

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel info -o json $TUNNEL_NAME | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

# Create config file
echo "📝 設定ファイルを作成中..."
cat > ~/.cloudflared/config-${SUBDOMAIN}.yml << EOF
tunnel: $TUNNEL_NAME
credentials-file: $HOME/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: $FULL_DOMAIN
    service: http://localhost:$PORT
  - service: http_status:404
EOF

# Route DNS automatically - サブドメインなら自動で設定可能！
echo "🔧 DNS設定を自動で行います..."
cloudflared tunnel route dns $TUNNEL_NAME $FULL_DOMAIN

echo ""
echo "=========================================="
echo "✅ セットアップ完了！"
echo "=========================================="
echo ""
echo "🌐 URL: https://${FULL_DOMAIN}"
echo ""
echo "🚀 次回からは以下のコマンドで起動:"
echo "   cloudflared tunnel run --config ~/.cloudflared/config-${SUBDOMAIN}.yml"
echo ""
echo "=========================================="
echo ""

# Run tunnel
echo "🚀 トンネルを起動中..."
cloudflared tunnel --config ~/.cloudflared/config-${SUBDOMAIN}.yml run