#!/bin/bash

# Flutter開発用スクリプト
# Mac/Ubuntu両対応 - iOS/Android/Web開発サポート

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      Flutter Development Tool          ║${NC}"
echo -e "${CYAN}║        Mac & Ubuntu Support            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# OS判定
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=true
    echo -e "${BLUE}📍 実行環境: macOS${NC}"
    echo -e "${GREEN}✅ 開発可能: iOS / Android / Web${NC}"
else
    IS_MAC=false
    echo -e "${BLUE}📍 実行環境: Linux/Ubuntu${NC}"
    echo -e "${GREEN}✅ 開発可能: Android / Web${NC}"
    echo -e "${YELLOW}⚠️  iOS開発にはMacが必要です${NC}"
fi
echo ""

# Flutterがインストールされているか確認
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutterがインストールされていません${NC}"
    echo -e "${YELLOW}インストールするには: ./setup.sh${NC}"
    exit 1
fi

# Flutterディレクトリに移動
cd "$FLUTTER_DIR"

# Flutterバージョン表示
echo -e "${BLUE}Flutter バージョン:${NC}"
flutter --version | head -n 1
echo ""

# 利用可能なデバイスを確認
echo -e "${BLUE}📱 利用可能なデバイス:${NC}"
flutter devices
echo ""

# アクション選択
echo -e "${CYAN}実行するアクションを選択してください:${NC}"
echo "  1) Web開発サーバー起動 (Chrome/Firefox)"
echo "  2) Android開発 (実機/エミュレータ)"
if [ "$IS_MAC" = true ]; then
    echo "  3) iOS開発 (実機/シミュレータ)"
    echo "  4) すべてのプラットフォームをビルド"
else
    echo "  3) Web + Android をビルド"
fi
echo "  5) Flutter Doctor (環境診断)"
echo "  6) パッケージ更新 (pub get)"
echo "  7) クリーンビルド (flutter clean)"
echo "  0) 終了"
echo ""

read -p "選択 (0-7): " choice

case $choice in
    1)
        echo -e "${GREEN}🌐 Flutter Web開発サーバーを起動します...${NC}"
        echo "ブラウザで http://localhost:5000 にアクセスしてください"
        flutter run -d chrome --web-port 5000
        ;;
    
    2)
        echo -e "${GREEN}📱 Android開発モードを起動します...${NC}"
        
        # Android デバイスの確認
        if flutter devices | grep -q android; then
            flutter run -d android
        else
            echo -e "${YELLOW}⚠️  Androidデバイスが見つかりません${NC}"
            echo "以下を確認してください:"
            echo "  • 実機: USBデバッグが有効か"
            echo "  • エミュレータ: Android Studioで起動しているか"
            
            if [ "$IS_MAC" = false ]; then
                echo ""
                echo -e "${YELLOW}Ubuntu環境でのAndroid開発セットアップ:${NC}"
                echo "  1. Android Studioをインストール"
                echo "  2. Android SDKをセットアップ"
                echo "  3. flutter doctor --android-licenses を実行"
            fi
        fi
        ;;
    
    3)
        if [ "$IS_MAC" = true ]; then
            echo -e "${GREEN}📱 iOS開発モードを起動します...${NC}"
            
            # iOS デバイスの確認
            if flutter devices | grep -q ios; then
                flutter run -d ios
            else
                echo -e "${YELLOW}⚠️  iOSデバイスが見つかりません${NC}"
                echo "以下を確認してください:"
                echo "  • 実機: デバイスが接続され、信頼されているか"
                echo "  • シミュレータ: Xcodeでシミュレータを起動"
                echo ""
                echo "シミュレータを起動するには:"
                echo "  open -a Simulator"
            fi
        else
            # Ubuntu環境でのビルド
            echo -e "${GREEN}🚀 Web + Android をビルドします...${NC}"
            
            # Web ビルド
            echo -e "${BLUE}🌐 Flutter Web をビルド中...${NC}"
            flutter build web --release --base-href /app/
            
            # ビルド成果物をNext.jsにコピー
            echo -e "${YELLOW}📂 Next.jsに統合中...${NC}"
            rm -rf "$ROOT_DIR/next/public/app"
            mkdir -p "$ROOT_DIR/next/public/app"
            cp -r build/web/* "$ROOT_DIR/next/public/app/"
            echo -e "${GREEN}✅ Webビルド完了${NC}"
            
            # Android APK ビルド
            echo ""
            read -p "Android APKもビルドしますか？ (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}📱 Android APK をビルド中...${NC}"
                flutter build apk --release
                echo -e "${GREEN}✅ APK作成完了:${NC}"
                echo "  build/app/outputs/flutter-apk/app-release.apk"
            fi
        fi
        ;;
    
    4)
        if [ "$IS_MAC" = true ]; then
            echo -e "${GREEN}🚀 すべてのプラットフォームをビルドします...${NC}"
            
            # Web ビルド
            echo -e "${BLUE}🌐 Flutter Web をビルド中...${NC}"
            flutter build web --release --base-href /app/
            
            # ビルド成果物をNext.jsにコピー
            echo -e "${YELLOW}📂 Next.jsに統合中...${NC}"
            rm -rf "$ROOT_DIR/next/public/app"
            mkdir -p "$ROOT_DIR/next/public/app"
            cp -r build/web/* "$ROOT_DIR/next/public/app/"
            echo -e "${GREEN}✅ Webビルド完了${NC}"
            
            # iOS ビルド
            echo ""
            echo -e "${BLUE}📱 iOS をビルド中...${NC}"
            flutter build ios --release --no-codesign
            echo -e "${GREEN}✅ iOSビルド完了${NC}"
            echo -e "${YELLOW}   Xcodeで署名して実機にインストールしてください${NC}"
            
            # Android APK ビルド
            echo ""
            echo -e "${BLUE}📱 Android APK をビルド中...${NC}"
            flutter build apk --release
            echo -e "${GREEN}✅ APK作成完了:${NC}"
            echo "  build/app/outputs/flutter-apk/app-release.apk"
            
            # App Bundle ビルド（Google Play用）
            echo ""
            read -p "App Bundle (Google Play用) もビルドしますか？ (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}📦 App Bundle をビルド中...${NC}"
                flutter build appbundle --release
                echo -e "${GREEN}✅ App Bundle作成完了:${NC}"
                echo "  build/app/outputs/bundle/release/app-release.aab"
            fi
        fi
        ;;
    
    5)
        echo -e "${BLUE}🔍 Flutter環境を診断します...${NC}"
        flutter doctor -v
        ;;
    
    6)
        echo -e "${BLUE}📦 パッケージを更新します...${NC}"
        flutter pub get
        echo -e "${GREEN}✅ パッケージ更新完了${NC}"
        ;;
    
    7)
        echo -e "${YELLOW}🧹 クリーンビルドを実行します...${NC}"
        flutter clean
        flutter pub get
        echo -e "${GREEN}✅ クリーンビルド完了${NC}"
        ;;
    
    0)
        echo -e "${CYAN}👋 終了します${NC}"
        exit 0
        ;;
    
    *)
        echo -e "${RED}❌ 無効な選択です${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ 処理が完了しました${NC}"