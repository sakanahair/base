#!/bin/bash

# サーバー側デプロイスクリプト
# Ubuntu/ConoHa VPSで実行
# Usage: ./script/deploy-server.sh

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# プロジェクトルート
PROJECT_ROOT="/var/www/sakana"
NEXT_DIR="$PROJECT_ROOT/next"
FLUTTER_DIR="$PROJECT_ROOT/flutter"

echo -e "${BLUE}🚀 サーバー側デプロイを開始します...${NC}"

# 1. Mutagen同期を強制フラッシュ（サーバー側の変更を確実に反映）
echo -e "${YELLOW}🔄 Mutagen同期をフラッシュ中...${NC}"
if command -v mutagen &> /dev/null; then
    mutagen sync flush sakana 2>/dev/null || true
fi

# 2. Next.jsビルド
echo -e "${BLUE}📦 Next.jsをビルド中...${NC}"
cd "$NEXT_DIR"

# 依存関係をインストール（TypeScriptも含む）
echo "依存関係をインストール中..."
npm install

# ビルド実行
echo "Next.jsをビルド中..."
npm run build

# standaloneビルドに必要なファイルをコピー
echo -e "${YELLOW}📂 standaloneファイルをコピー中...${NC}"
rm -rf .next/standalone/public .next/standalone/.next/static
cp -r public .next/standalone/
cp -r .next/static .next/standalone/.next/

# 3. Flutter Webビルド（Flutterがインストールされている場合）
if command -v flutter &> /dev/null && [ -d "$FLUTTER_DIR" ]; then
    echo -e "${BLUE}📱 Flutter Webをビルド中...${NC}"
    cd "$FLUTTER_DIR"
    
    # Flutter依存関係を取得
    flutter pub get
    
    # Flutter Webをビルド
    flutter build web --release --base-href /app/
    
    # Flutter WebファイルをNext.jsのpublicフォルダにコピー
    echo -e "${YELLOW}📂 Flutter WebをNext.jsに統合中...${NC}"
    rm -rf "$NEXT_DIR/public/app"
    mkdir -p "$NEXT_DIR/public/app"
    cp -r "$FLUTTER_DIR/build/web/"* "$NEXT_DIR/public/app/"
    
    # standalone用にもコピー
    rm -rf "$NEXT_DIR/.next/standalone/public/app"
    cp -r "$NEXT_DIR/public/app" "$NEXT_DIR/.next/standalone/public/"
else
    echo -e "${YELLOW}⚠️  Flutterがインストールされていないため、Flutter Webビルドをスキップ${NC}"
fi

# 4. PM2でNext.jsを再起動
echo -e "${BLUE}🔄 PM2でアプリケーションを再起動中...${NC}"
cd "$NEXT_DIR"

if pm2 list | grep -q sakana-next; then
    pm2 restart sakana-next
    echo -e "${GREEN}✅ アプリケーションを再起動しました${NC}"
else
    pm2 start .next/standalone/server.js --name sakana-next
    pm2 save
    pm2 startup systemd -u root --hp /root
    echo -e "${GREEN}✅ アプリケーションを新規起動しました${NC}"
fi

# 5. Nginxをリロード
echo -e "${BLUE}🔄 Nginxをリロード中...${NC}"
nginx -t && systemctl reload nginx

# 6. ステータス確認
echo -e "${GREEN}✨ サーバー側デプロイが完了しました！${NC}"
echo ""
echo -e "${BLUE}📊 アプリケーションステータス:${NC}"
pm2 status sakana-next

echo ""
echo -e "${BLUE}🌐 アクセスURL:${NC}"
echo "  - メインサイト: https://dev.sakana.hair/"
echo "  - Flutter App: https://dev.sakana.hair/app/"
echo "  - Terminal: https://dev.sakana.hair/terminal/"
echo ""
echo -e "${YELLOW}📝 ログ確認: pm2 logs sakana-next${NC}"
echo -e "${YELLOW}🔄 Mutagen同期状態: mutagen sync list${NC}"