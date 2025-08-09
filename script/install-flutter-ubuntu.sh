#!/bin/bash

# ============================================
# Flutter Ubuntu インストールスクリプト
# 複数のインストール方法をサポート
# ============================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════╗"
echo "║     Flutter Ubuntu Setup Script          ║"
echo "║         Complete Installation             ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Ubuntuバージョン確認
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "${BLUE}📍 Ubuntu バージョン: $VERSION${NC}"
else
    echo -e "${RED}❌ Ubuntuが検出されませんでした${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}インストール方法を選択してください:${NC}"
echo ""
echo "  1) 🚀 Snap版 (推奨・簡単)"
echo "     - 最も簡単なインストール方法"
echo "     - 自動更新サポート"
echo "     - Android/Web開発可能"
echo ""
echo "  2) 📦 Git版 (カスタマイズ可能)"
echo "     - 最新のmaster/betaチャンネル利用可能"
echo "     - 手動更新が必要"
echo "     - より細かい制御が可能"
echo ""
echo "  3) 📥 手動ダウンロード版"
echo "     - 特定バージョンを選択可能"
echo "     - オフラインインストール可能"
echo ""
echo "  4) 🔧 既存インストールの修復"
echo "     - パス設定の修正"
echo "     - 依存関係の再インストール"
echo ""
echo "  0) 終了"
echo ""

read -p "選択 (0-4): " install_method

# 共通の依存関係インストール関数
install_dependencies() {
    echo -e "${YELLOW}📦 必要なパッケージをインストール中...${NC}"
    sudo apt-get update
    
    # 基本パッケージ
    sudo apt-get install -y \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa
    
    # 32ビットライブラリ（Android開発用）
    echo -e "${YELLOW}📱 Android開発用ライブラリをインストール中...${NC}"
    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install -y \
        libc6:i386 \
        libncurses5:i386 \
        libstdc++6:i386 \
        lib32z1 \
        libbz2-1.0:i386
    
    # 開発ツール
    echo -e "${YELLOW}🛠️ 開発ツールをインストール中...${NC}"
    sudo apt-get install -y \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev
}

# Snap版インストール
install_flutter_snap() {
    echo -e "${GREEN}🚀 Snap版Flutterをインストールします${NC}"
    
    # snapdがインストールされているか確認
    if ! command -v snap &> /dev/null; then
        echo -e "${YELLOW}Snapをインストール中...${NC}"
        sudo apt-get install -y snapd
    fi
    
    # Flutter Snapをインストール
    sudo snap install flutter --classic
    
    # パスを設定
    echo -e "${YELLOW}パスを設定中...${NC}"
    if ! grep -q "/snap/bin" ~/.bashrc; then
        echo 'export PATH="$PATH:/snap/bin"' >> ~/.bashrc
    fi
    export PATH="$PATH:/snap/bin"
    
    echo -e "${GREEN}✅ Snap版Flutterインストール完了！${NC}"
    
    # Flutter doctorを実行
    echo -e "${BLUE}Flutter環境を確認中...${NC}"
    flutter doctor
}

# Git版インストール
install_flutter_git() {
    echo -e "${GREEN}📦 Git版Flutterをインストールします${NC}"
    
    # インストール先を選択
    echo -e "${CYAN}インストール先を選択してください:${NC}"
    echo "  1) ~/flutter (ユーザーディレクトリ)"
    echo "  2) /opt/flutter (システム全体)"
    echo "  3) カスタムパス"
    read -p "選択 (1-3): " location_choice
    
    case $location_choice in
        1)
            FLUTTER_PATH="$HOME/flutter"
            ;;
        2)
            FLUTTER_PATH="/opt/flutter"
            ;;
        3)
            read -p "インストールパスを入力: " FLUTTER_PATH
            ;;
        *)
            FLUTTER_PATH="$HOME/flutter"
            ;;
    esac
    
    # チャンネル選択
    echo -e "${CYAN}Flutterチャンネルを選択してください:${NC}"
    echo "  1) stable (安定版・推奨)"
    echo "  2) beta (ベータ版)"
    echo "  3) master (開発版)"
    read -p "選択 (1-3): " channel_choice
    
    case $channel_choice in
        1) CHANNEL="stable" ;;
        2) CHANNEL="beta" ;;
        3) CHANNEL="master" ;;
        *) CHANNEL="stable" ;;
    esac
    
    # 既存のインストールを確認
    if [ -d "$FLUTTER_PATH" ]; then
        echo -e "${YELLOW}⚠️ $FLUTTER_PATH は既に存在します${NC}"
        read -p "削除して再インストールしますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo rm -rf "$FLUTTER_PATH"
        else
            echo -e "${RED}インストールを中止しました${NC}"
            return
        fi
    fi
    
    # Gitからクローン
    echo -e "${YELLOW}Flutterをダウンロード中...${NC}"
    if [[ "$FLUTTER_PATH" == "/opt/flutter" ]]; then
        sudo git clone https://github.com/flutter/flutter.git -b $CHANNEL "$FLUTTER_PATH"
        sudo chown -R $USER:$USER "$FLUTTER_PATH"
    else
        git clone https://github.com/flutter/flutter.git -b $CHANNEL "$FLUTTER_PATH"
    fi
    
    # パス設定
    echo -e "${YELLOW}パスを設定中...${NC}"
    if ! grep -q "$FLUTTER_PATH/bin" ~/.bashrc; then
        echo "export PATH=\"\$PATH:$FLUTTER_PATH/bin\"" >> ~/.bashrc
    fi
    export PATH="$PATH:$FLUTTER_PATH/bin"
    
    # Flutter初期設定
    echo -e "${YELLOW}Flutter初期設定中...${NC}"
    flutter config --no-analytics
    flutter precache --web --linux
    
    echo -e "${GREEN}✅ Git版Flutterインストール完了！${NC}"
    
    # Flutter doctorを実行
    echo -e "${BLUE}Flutter環境を確認中...${NC}"
    flutter doctor
}

# 手動ダウンロード版インストール
install_flutter_manual() {
    echo -e "${GREEN}📥 手動ダウンロード版Flutterをインストールします${NC}"
    
    # 最新バージョンを取得
    echo -e "${YELLOW}利用可能なバージョンを確認中...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/flutter/flutter/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    echo -e "${CYAN}Flutterバージョン: $LATEST_VERSION${NC}"
    echo "このバージョンをインストールしますか？"
    echo "  1) はい"
    echo "  2) 別のバージョンを指定"
    read -p "選択 (1-2): " version_choice
    
    if [ "$version_choice" == "2" ]; then
        read -p "バージョンを入力 (例: 3.16.0): " FLUTTER_VERSION
    else
        FLUTTER_VERSION=${LATEST_VERSION#v}  # Remove 'v' prefix if present
    fi
    
    # ダウンロードURL生成
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    
    # インストール先
    INSTALL_DIR="/opt"
    FLUTTER_PATH="$INSTALL_DIR/flutter"
    
    # ダウンロード
    echo -e "${YELLOW}Flutterをダウンロード中...${NC}"
    cd /tmp
    wget -O flutter.tar.xz "$FLUTTER_URL" || {
        echo -e "${RED}ダウンロードに失敗しました${NC}"
        echo "URLを確認してください: $FLUTTER_URL"
        exit 1
    }
    
    # 展開
    echo -e "${YELLOW}ファイルを展開中...${NC}"
    sudo tar -xf flutter.tar.xz -C "$INSTALL_DIR"
    sudo chown -R $USER:$USER "$FLUTTER_PATH"
    rm flutter.tar.xz
    
    # パス設定
    echo -e "${YELLOW}パスを設定中...${NC}"
    if ! grep -q "$FLUTTER_PATH/bin" ~/.bashrc; then
        echo "export PATH=\"\$PATH:$FLUTTER_PATH/bin\"" >> ~/.bashrc
    fi
    export PATH="$PATH:$FLUTTER_PATH/bin"
    
    echo -e "${GREEN}✅ Flutter $FLUTTER_VERSION インストール完了！${NC}"
    
    # Flutter doctorを実行
    echo -e "${BLUE}Flutter環境を確認中...${NC}"
    flutter doctor
}

# 既存インストールの修復
repair_flutter() {
    echo -e "${CYAN}🔧 既存のFlutterインストールを修復します${NC}"
    
    # Flutterのパスを探す
    echo -e "${YELLOW}Flutterインストールを検索中...${NC}"
    
    FLUTTER_PATHS=(
        "$HOME/flutter"
        "/opt/flutter"
        "/usr/local/flutter"
        "$HOME/development/flutter"
        "/snap/flutter"
    )
    
    FOUND_FLUTTER=""
    for path in "${FLUTTER_PATHS[@]}"; do
        if [ -f "$path/bin/flutter" ]; then
            echo -e "${GREEN}✅ Flutterが見つかりました: $path${NC}"
            FOUND_FLUTTER="$path"
            break
        fi
    done
    
    if [ -z "$FOUND_FLUTTER" ]; then
        echo -e "${RED}❌ Flutterが見つかりませんでした${NC}"
        echo "新規インストールを実行してください"
        exit 1
    fi
    
    # パス設定を修復
    echo -e "${YELLOW}パス設定を修復中...${NC}"
    
    # 古いパス設定を削除
    sed -i '/flutter\/bin/d' ~/.bashrc
    
    # 新しいパス設定を追加
    echo "export PATH=\"\$PATH:$FOUND_FLUTTER/bin\"" >> ~/.bashrc
    export PATH="$PATH:$FOUND_FLUTTER/bin"
    
    # Flutter自体をアップデート
    echo -e "${YELLOW}Flutterをアップデート中...${NC}"
    flutter upgrade
    
    # キャッシュをクリア
    echo -e "${YELLOW}キャッシュをクリア中...${NC}"
    flutter clean
    flutter pub cache repair
    
    # 必要なコンポーネントを再インストール
    echo -e "${YELLOW}コンポーネントを再インストール中...${NC}"
    flutter precache --web --linux
    
    echo -e "${GREEN}✅ 修復完了！${NC}"
    
    # Flutter doctorを実行
    echo -e "${BLUE}Flutter環境を確認中...${NC}"
    flutter doctor -v
}

# Chrome/Chromiumインストール
install_browser() {
    echo -e "${CYAN}🌐 Web開発用ブラウザをインストールします${NC}"
    
    if command -v google-chrome &> /dev/null; then
        echo -e "${GREEN}✅ Google Chromeは既にインストールされています${NC}"
    elif command -v chromium-browser &> /dev/null; then
        echo -e "${GREEN}✅ Chromiumは既にインストールされています${NC}"
    else
        echo "ブラウザを選択してください:"
        echo "  1) Chromium (オープンソース)"
        echo "  2) Google Chrome (公式)"
        read -p "選択 (1-2): " browser_choice
        
        if [ "$browser_choice" == "2" ]; then
            echo -e "${YELLOW}Google Chromeをインストール中...${NC}"
            wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
            sudo apt-get update
            sudo apt-get install -y google-chrome-stable
        else
            echo -e "${YELLOW}Chromiumをインストール中...${NC}"
            sudo apt-get install -y chromium-browser
        fi
    fi
}

# Android Studioインストール
install_android_studio() {
    echo -e "${CYAN}📱 Android Studioをインストールしますか？${NC}"
    echo "（Android開発に必要）"
    read -p "インストールする (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Android Studioをインストール中...${NC}"
        
        # Snap版をインストール
        sudo snap install android-studio --classic
        
        echo -e "${GREEN}✅ Android Studioインストール完了！${NC}"
        echo ""
        echo -e "${YELLOW}次の手順:${NC}"
        echo "1. Android Studioを起動: android-studio"
        echo "2. セットアップウィザードを完了"
        echo "3. SDK Managerから必要なSDKをインストール"
        echo "4. flutter doctor --android-licenses を実行"
    fi
}

# VS Code設定
setup_vscode() {
    echo -e "${CYAN}💻 VS Codeの設定を行いますか？${NC}"
    read -p "設定する (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # VS Codeがインストールされているか確認
        if ! command -v code &> /dev/null; then
            echo -e "${YELLOW}VS Codeをインストール中...${NC}"
            sudo snap install code --classic
        fi
        
        echo -e "${YELLOW}Flutter/Dart拡張機能をインストール中...${NC}"
        code --install-extension Dart-Code.flutter
        code --install-extension Dart-Code.dart-code
        
        echo -e "${GREEN}✅ VS Code設定完了！${NC}"
    fi
}

# メイン処理
main() {
    case $install_method in
        1)
            install_dependencies
            install_flutter_snap
            ;;
        2)
            install_dependencies
            install_flutter_git
            ;;
        3)
            install_dependencies
            install_flutter_manual
            ;;
        4)
            repair_flutter
            ;;
        0)
            echo -e "${CYAN}終了します${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}無効な選択です${NC}"
            exit 1
            ;;
    esac
    
    # 追加セットアップ
    echo ""
    echo -e "${CYAN}追加セットアップ${NC}"
    install_browser
    install_android_studio
    setup_vscode
    
    # 最終確認
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ セットアップ完了！                  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "1. ターミナルを再起動するか、以下を実行:"
    echo "   ${YELLOW}source ~/.bashrc${NC}"
    echo ""
    echo "2. Flutter環境を確認:"
    echo "   ${YELLOW}flutter doctor${NC}"
    echo ""
    echo "3. プロジェクトで開発開始:"
    echo "   ${YELLOW}cd flutter${NC}"
    echo "   ${YELLOW}flutter run -d chrome${NC}  # Web開発"
    echo "   ${YELLOW}flutter run -d linux${NC}   # Linuxアプリ"
    echo ""
    
    # ライセンス承認
    echo -e "${YELLOW}Androidライセンスを承認しますか？${NC}"
    read -p "承認する (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        flutter doctor --android-licenses
    fi
}

# スクリプト実行
main