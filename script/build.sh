#!/bin/bash

# Flutter + Next.js ビルドスクリプト
# Mac/Linux両対応版

set -e

echo "🚀 ビルドを開始します..."

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"
NEXT_DIR="$ROOT_DIR/next"

# Flutterのパスを確認（システムのFlutterを優先）
# tools/flutterがある場合は削除
if [ -d "$ROOT_DIR/tools/flutter" ] && [ ! -d "$ROOT_DIR/tools/flutter/.git" ]; then
    echo -e "${YELLOW}⚠️  tools/flutterは不完全です。削除します...${NC}"
    rm -rf "$ROOT_DIR/tools/flutter"
fi

# OS判定（Mac/Linux対応）
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    SED_CMD="sed -i ''"
    IS_MAC=true
    echo -e "${YELLOW}📍 実行環境: macOS${NC}"
    echo -e "${GREEN}✅ iOS/Android/Web ビルド可能${NC}"
else
    # Linux/Ubuntu
    SED_CMD="sed -i"
    IS_MAC=false
    echo -e "${YELLOW}📍 実行環境: Linux/Ubuntu${NC}"
    echo -e "${GREEN}✅ Android/Web ビルド可能${NC}"
    echo -e "${YELLOW}⚠️  iOS ビルドはMacでのみ可能${NC}"
fi

# Flutterがインストールされているか確認
if command -v flutter &> /dev/null; then
    HAS_FLUTTER=true
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✅ Flutter が見つかりました${NC}"
    echo -e "${BLUE}   バージョン: ${FLUTTER_VERSION}${NC}"
    
    # 利用可能なデバイスを確認
    echo -e "${BLUE}📱 利用可能なビルドターゲット:${NC}"
    if [ "$IS_MAC" = true ]; then
        echo -e "   • iOS (実機/シミュレータ)"
        echo -e "   • Android (実機/エミュレータ)"
        echo -e "   • Web (Chrome/Edge/Safari)"
    else
        echo -e "   • Android (実機/エミュレータ)"
        echo -e "   • Web (Chrome/Firefox)"
    fi
else
    HAS_FLUTTER=false
    echo -e "${YELLOW}⚠️  Flutter が見つかりません（Next.jsのみビルドします）${NC}"
    echo -e "${YELLOW}   Flutterをインストールするには: ./setup.sh${NC}"
fi

# 1. Flutter Web ビルド（Flutterがある場合のみ）
if [ "$HAS_FLUTTER" = true ] && [ -d "$FLUTTER_DIR" ]; then
    echo -e "${BLUE}📱 Flutter Web をビルドしています...${NC}"
    cd "$FLUTTER_DIR"
    
    # CI環境変数を設定（root権限での実行を許可）
    export CI=true
    
    # Flutter の依存関係を取得
    flutter pub get
    
    # Flutter Web をビルド（base-hrefを/app/に設定）
    echo -e "${BLUE}🌐 Flutter Web をビルド中...${NC}"
    flutter build web --release --base-href /app/
    
    # Androidビルドのオプション表示（Ubuntuでも可能）
    if [ -d "android" ]; then
        echo -e "${YELLOW}📱 Androidアプリもビルドしますか？${NC}"
        echo "   (APKファイルが作成されます)"
        read -p "   ビルドする場合は 'y' を入力: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}📱 Android APK をビルド中...${NC}"
            export CI=true
            flutter build apk --release
            echo -e "${GREEN}✅ APK作成完了: build/app/outputs/flutter-apk/app-release.apk${NC}"
        fi
    fi
    
    # iOSビルドのオプション表示（Macのみ）
    if [ "$IS_MAC" = true ] && [ -d "ios" ]; then
        echo -e "${YELLOW}📱 iOSアプリもビルドしますか？${NC}"
        echo "   (Xcodeでの追加設定が必要な場合があります)"
        read -p "   ビルドする場合は 'y' を入力: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}📱 iOS をビルド中...${NC}"
            export CI=true
            flutter build ios --release --no-codesign
            echo -e "${GREEN}✅ iOSビルド完了${NC}"
            echo -e "${YELLOW}   Xcodeで署名して実機にインストールしてください${NC}"
        fi
    fi
    
    # ビルド成果物を Next.js の public フォルダにコピー
    echo -e "${YELLOW}📂 Flutter ビルドを Next.js に統合しています...${NC}"
    rm -rf "$NEXT_DIR/public/app"
    mkdir -p "$NEXT_DIR/public/app"
    cp -r "$FLUTTER_DIR/build/web/"* "$NEXT_DIR/public/app/"
    
    # index.htmlのbase hrefを修正（念のため、OS別のsedコマンドを使用）
    $SED_CMD 's|<base href="/">|<base href="/app/">|g' "$NEXT_DIR/public/app/index.html" 2>/dev/null || true
else
    if [ "$HAS_FLUTTER" = false ]; then
        echo -e "${YELLOW}ℹ️  Flutter ビルドをスキップしています${NC}"
        echo -e "${YELLOW}   Ubuntuでも Flutter Web/Android 開発が可能です${NC}"
        echo -e "${YELLOW}   インストール: ./setup.sh${NC}"
    fi
fi

# 2. Next.js ビルド
echo -e "${BLUE}⚡ Next.js をビルドしています...${NC}"
cd "$NEXT_DIR"

# Next.js の依存関係を取得
echo "依存関係をインストール中..."
npm install

# Next.js をビルド（standalone SSRモード）
echo "Next.js をビルド中..."
npm run build

echo -e "${GREEN}✅ ビルドが完了しました！${NC}"
echo ""

# 3. 起動オプションの表示
echo -e "${BLUE}🚀 アプリケーションの起動方法：${NC}"
echo ""

if [ "$IS_MAC" = true ]; then
    # Mac環境の場合
    echo "開発環境:"
    echo "  cd $NEXT_DIR && npm run dev"
    echo ""
    echo "Flutter開発（iOS/Android/Web）:"
    echo "  cd $FLUTTER_DIR"
    echo "  flutter run -d chrome    # Web開発"
    echo "  flutter run -d ios       # iOS開発"
    echo "  flutter run -d android   # Android開発"
    echo ""
    echo "本番環境（スタンドアロンモード）:"
    echo "  cd $NEXT_DIR && node .next/standalone/server.js"
    echo ""
    echo "デプロイ:"
    echo "  ./script/deploy.sh"
    echo ""
    
    # 開発サーバーを起動するか確認
    read -p "開発サーバーを起動しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ 開発サーバーを起動します...${NC}"
        echo ""
        echo "🌐 アクセス URL:"
        echo "  http://localhost:3000"
        echo "  http://localhost:3000/app/"
        echo "  http://localhost:3000/morishita/"
        echo ""
        echo "📝 サーバーを停止するには Ctrl+C を押してください"
        echo ""
        npm run dev
    else
        echo -e "${YELLOW}ℹ️  手動でサーバーを起動してください${NC}"
    fi
else
    # Linux/Ubuntu環境の場合
    if [ "$HAS_FLUTTER" = true ]; then
        echo "Flutter開発（Android/Web）:"
        echo "  cd $FLUTTER_DIR"
        echo "  flutter run -d chrome    # Web開発"
        echo "  flutter run -d android   # Android開発"
        echo "  flutter devices          # 利用可能なデバイス確認"
        echo ""
    fi
    
    echo "PM2での起動:"
    echo "  pm2 restart sakana-next"
    echo ""
    echo "または新規起動:"
    echo "  pm2 start .next/standalone/server.js --name sakana-next"
    echo ""
    echo "ログ確認:"
    echo "  pm2 logs sakana-next"
    echo ""
    
    # PM2でアプリケーションを再起動するか確認
    read -p "PM2でアプリケーションを再起動しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ PM2でアプリケーションを再起動します...${NC}"
        if pm2 list | grep -q sakana-next; then
            pm2 restart sakana-next
        else
            pm2 start .next/standalone/server.js --name sakana-next
            pm2 save
        fi
        echo ""
        echo -e "${GREEN}✅ アプリケーションが起動しました！${NC}"
        pm2 status
    else
        echo -e "${YELLOW}ℹ️  手動で起動してください${NC}"
    fi
fi