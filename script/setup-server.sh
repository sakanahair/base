#!/bin/bash

# ConoHa VPS初期設定スクリプト
# Usage: ./script/setup-server.sh

set -e

SERVER="root@dev.sakana"

echo "🚀 ConoHa VPSサーバー初期設定を開始します..."

# サーバーに接続して初期設定を実行
ssh $SERVER << 'ENDSSH'

echo "📦 パッケージを更新中..."
apt-get update && apt-get upgrade -y

echo "🔧 必要なツールをインストール中..."
apt-get install -y curl wget git build-essential nginx certbot python3-certbot-nginx

echo "📦 Node.js 20.xをインストール中..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "🔧 PM2をインストール中..."
npm install -g pm2

echo "📁 ディレクトリ構造を作成中..."
mkdir -p /var/www/sakana
mkdir -p /var/www/sakana/next
mkdir -p /var/www/sakana/flutter
mkdir -p /var/www/sakana/logs
mkdir -p /var/www/sakana/scripts

echo "👤 権限を設定中..."
chown -R www-data:www-data /var/www/sakana
chmod -R 755 /var/www/sakana

echo "🔥 ファイアウォールを設定中..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
echo "y" | ufw enable

echo "📝 システム情報..."
node --version
npm --version
nginx -v
pm2 --version

echo "✅ サーバー初期設定が完了しました！"

ENDSSH

echo "✨ ローカルからの設定が完了しました！"
echo ""
echo "次のステップ:"
echo "1. mutagen sync create でファイル同期を開始"
echo "2. ./script/deploy.sh でアプリケーションをデプロイ"
echo "3. Nginx設定を適用"
echo "4. SSL証明書を取得"