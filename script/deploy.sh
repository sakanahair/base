#!/bin/bash

# デプロイスクリプト
# Usage: ./script/deploy.sh

set -e

SERVER="root@dev.sakana"
# スクリプトのディレクトリから相対的にプロジェクトルートを決定
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REMOTE_ROOT="/var/www/sakana"

echo "🚀 デプロイを開始します..."

# 1. ローカルでビルド
echo "📦 Next.jsをビルド中..."
cd $PROJECT_ROOT/next
npm install
npm run build

echo "📦 Flutter Webをビルド中..."
cd $PROJECT_ROOT/flutter
flutter build web --release --base-href /app/

# 2. Mutagen同期を実行
echo "🔄 ファイルを同期中..."
if mutagen sync list | grep -q sakana; then
    echo "既存の同期セッションをフラッシュ中..."
    mutagen sync flush sakana
else
    echo "新しい同期セッションを作成中..."
    mutagen sync create \
        $PROJECT_ROOT \
        $SERVER:$REMOTE_ROOT \
        --name=sakana \
        --mode=two-way-resolved \
        --ignore-vcs \
        --ignore="node_modules/" \
        --ignore=".next/" \
        --ignore="dist/" \
        --ignore=".git/"
fi

# 同期が完了するまで待機
echo "同期完了を待っています..."
sleep 5

# 3. サーバー上でNext.jsを起動
echo "🚀 サーバー上でアプリケーションを起動中..."
ssh $SERVER << 'ENDSSH'
cd /var/www/sakana/next

# 依存関係をインストール
echo "依存関係をインストール中..."
npm install --production

# standaloneビルドに必要なファイルをコピー
echo "standaloneビルドに必要なファイルをコピー中..."
rm -rf .next/standalone/public .next/standalone/.next/static
cp -r public .next/standalone/
cp -r .next/static .next/standalone/.next/

# PM2でNext.jsを起動/再起動（standaloneモード）
echo "PM2でアプリケーションを起動中..."
if pm2 list | grep -q sakana-next; then
    pm2 restart sakana-next
else
    pm2 start .next/standalone/server.js --name sakana-next
    pm2 save
    pm2 startup systemd -u root --hp /root
fi

# Flutter Webファイルをコピー
echo "Flutter Webファイルを配置中..."
mkdir -p /var/www/sakana/public/app
cp -r /var/www/sakana/flutter/build/web/* /var/www/sakana/public/app/

# Nginxを再起動
echo "Nginxを再起動中..."
nginx -t && systemctl reload nginx

echo "✅ サーバー上のデプロイが完了しました！"
pm2 status

ENDSSH

echo "✨ デプロイが正常に完了しました！"
echo ""
echo "アクセスURL:"
echo "- メインサイト: http://dev.sakana.hair/"
echo "- Flutter App: http://dev.sakana.hair/app/"
echo "- morishita: http://dev.sakana.hair/morishita/"
echo ""
echo "PM2ログを確認: ssh $SERVER 'pm2 logs sakana-next'"
echo ""

# ローカル開発サーバーも起動するか確認
echo "🔄 ローカル開発サーバーも起動しますか？"
read -p "起動する場合は 'y' を入力: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✅ ローカル開発サーバーを起動します..."
    echo ""
    echo "🌐 ローカルアクセス URL:"
    echo "  http://localhost:3000"
    echo ""
    echo "📝 サーバーを停止するには Ctrl+C を押してください"
    echo ""
    cd $PROJECT_ROOT/next
    npm run dev
fi