#!/bin/bash

# ============================================
# SAKANA AI - 自動セットアップスクリプト
# Mac/Ubuntu両対応
# ============================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════╗"
echo "║         SAKANA AI Setup Script           ║"
echo "║           Mac & Ubuntu Support            ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# OS検出
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${BLUE}📍 検出されたOS: macOS${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" ]]; then
                OS="ubuntu"
                echo -e "${BLUE}📍 検出されたOS: Ubuntu${NC}"
            else
                echo -e "${RED}❌ サポートされていないLinuxディストリビューションです${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${RED}❌ サポートされていないOSです${NC}"
        exit 1
    fi
}

# Homebrewのインストール（Mac用）
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}📦 Homebrewをインストールしています...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Homebrewのパス設定
        if [[ -f /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}✅ Homebrewは既にインストールされています${NC}"
    fi
}

# Node.jsのインストール
install_nodejs() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}📦 Node.js 20.xをインストールしています...${NC}"
        if [[ "$OS" == "macos" ]]; then
            brew install node@20
            brew link node@20
        else
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 20 ]; then
            echo -e "${GREEN}✅ Node.js $(node -v) は既にインストールされています${NC}"
        else
            echo -e "${YELLOW}⚠️ Node.jsのバージョンが古いです。アップグレードしてください${NC}"
        fi
    fi
}

# Flutterのインストール
install_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo -e "${YELLOW}📦 Flutterをインストールしています...${NC}"
        if [[ "$OS" == "macos" ]]; then
            brew install --cask flutter
        else
            # Ubuntu用のFlutterインストール
            sudo apt-get update
            sudo apt-get install -y git curl unzip xz-utils zip libglu1-mesa
            
            # Flutterをダウンロード
            cd ~
            git clone https://github.com/flutter/flutter.git -b stable
            echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
            export PATH="$PATH:$HOME/flutter/bin"
            
            # 元のディレクトリに戻る
            cd - > /dev/null
        fi
    else
        echo -e "${GREEN}✅ Flutter $(flutter --version | head -n 1) は既にインストールされています${NC}"
    fi
}

# Mutagenのインストール
install_mutagen() {
    if ! command -v mutagen &> /dev/null; then
        echo -e "${YELLOW}📦 Mutagenをインストールしています...${NC}"
        if [[ "$OS" == "macos" ]]; then
            brew install mutagen-io/mutagen/mutagen
        else
            # Ubuntu用のMutagenインストール
            MUTAGEN_VERSION="0.17.2"
            wget https://github.com/mutagen-io/mutagen/releases/download/v${MUTAGEN_VERSION}/mutagen_linux_amd64_v${MUTAGEN_VERSION}.tar.gz
            sudo tar -xzf mutagen_linux_amd64_v${MUTAGEN_VERSION}.tar.gz -C /usr/local/bin/
            rm mutagen_linux_amd64_v${MUTAGEN_VERSION}.tar.gz
        fi
    else
        echo -e "${GREEN}✅ Mutagenは既にインストールされています${NC}"
    fi
}

# GitHubからクローン
clone_repository() {
    echo ""
    echo -e "${BLUE}📂 リポジトリのセットアップ${NC}"
    echo "1) 新規クローン (https://github.com/sakanahair/base.git)"
    echo "2) 既存のディレクトリを使用（現在のディレクトリ）"
    read -p "選択してください (1/2): " choice
    
    if [ "$choice" == "1" ]; then
        read -p "クローン先のディレクトリ名 (デフォルト: SAKANA_AI): " dir_name
        dir_name=${dir_name:-SAKANA_AI}
        
        if [ -d "$dir_name" ]; then
            echo -e "${YELLOW}⚠️ ディレクトリ $dir_name は既に存在します${NC}"
            read -p "上書きしますか？ (y/n): " overwrite
            if [[ $overwrite == "y" ]]; then
                rm -rf "$dir_name"
            else
                echo -e "${RED}セットアップを中止しました${NC}"
                exit 1
            fi
        fi
        
        echo -e "${YELLOW}📥 リポジトリをクローンしています...${NC}"
        git clone https://github.com/sakanahair/base.git "$dir_name"
        cd "$dir_name"
    else
        echo -e "${GREEN}現在のディレクトリを使用します${NC}"
    fi
}

# 依存関係のインストール
install_dependencies() {
    echo ""
    echo -e "${BLUE}📦 依存関係をインストールしています...${NC}"
    
    # Next.jsの依存関係
    if [ -d "next" ]; then
        echo -e "${YELLOW}Next.jsの依存関係をインストール中...${NC}"
        cd next
        npm install
        cd ..
    fi
    
    # Flutterの依存関係
    if [ -d "flutter" ] && command -v flutter &> /dev/null; then
        echo -e "${YELLOW}Flutterの依存関係をインストール中...${NC}"
        cd flutter
        flutter pub get
        cd ..
    fi
    
    # スクリプトに実行権限を付与
    if [ -d "script" ]; then
        echo -e "${YELLOW}スクリプトに実行権限を付与中...${NC}"
        chmod +x script/*.sh
    fi
}

# SSH設定
setup_ssh() {
    echo ""
    echo -e "${BLUE}🔐 SSH設定${NC}"
    read -p "SSH設定を追加しますか？ (y/n): " add_ssh
    
    if [[ $add_ssh == "y" ]]; then
        SSH_CONFIG="
Host dev.sakana
    HostName dev.sakana.hair
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 180
    TCPKeepAlive yes"
        
        # SSH設定が既に存在するか確認
        if ! grep -q "Host dev.sakana" ~/.ssh/config 2>/dev/null; then
            echo "$SSH_CONFIG" >> ~/.ssh/config
            echo -e "${GREEN}✅ SSH設定を追加しました${NC}"
        else
            echo -e "${YELLOW}SSH設定は既に存在します${NC}"
        fi
    fi
}

# 環境変数の設定
setup_env() {
    echo ""
    echo -e "${BLUE}🔧 環境変数の設定${NC}"
    
    if [ -f ".env.example" ] && [ ! -f ".env" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ .envファイルを作成しました${NC}"
    fi
    
    if [ -f "next/.env.local.example" ] && [ ! -f "next/.env.local" ]; then
        cp next/.env.local.example next/.env.local
        echo -e "${GREEN}✅ .env.localファイルを作成しました${NC}"
    fi
}

# Mutagen同期の設定
setup_mutagen() {
    echo ""
    echo -e "${BLUE}🔄 Mutagen同期の設定${NC}"
    read -p "Mutagen同期を開始しますか？ (y/n): " start_sync
    
    if [[ $start_sync == "y" ]]; then
        # 既存のセッションを確認
        if mutagen sync list | grep -q sakana 2>/dev/null; then
            echo -e "${YELLOW}既存のMutagenセッションが見つかりました${NC}"
            read -p "リセットしますか？ (y/n): " reset_sync
            if [[ $reset_sync == "y" ]]; then
                mutagen sync terminate sakana
            fi
        fi
        
        if [ -f "script/sync-start.sh" ]; then
            echo -e "${YELLOW}Mutagen同期を開始しています...${NC}"
            ./script/sync-start.sh
        fi
    fi
}

# メイン処理
main() {
    # OS検出
    detect_os
    
    echo ""
    echo -e "${BLUE}🚀 セットアップを開始します${NC}"
    echo "このスクリプトは以下をインストール/設定します："
    echo "  • Node.js 20.x"
    echo "  • Flutter"
    echo "  • Mutagen"
    echo "  • プロジェクトの依存関係"
    echo "  • SSH設定"
    echo "  • 環境変数"
    echo ""
    read -p "続行しますか？ (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}セットアップを中止しました${NC}"
        exit 1
    fi
    
    # macOSの場合はHomebrewをインストール
    if [[ "$OS" == "macos" ]]; then
        install_homebrew
    fi
    
    # 必要なツールのインストール
    install_nodejs
    install_flutter
    install_mutagen
    
    # リポジトリのクローン/選択
    clone_repository
    
    # 依存関係のインストール
    install_dependencies
    
    # SSH設定
    setup_ssh
    
    # 環境変数の設定
    setup_env
    
    # Mutagen同期の設定
    setup_mutagen
    
    # 完了メッセージ
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ セットアップが完了しました！        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "  1. ローカル開発を開始:"
    echo "     ${YELLOW}./script/build.sh${NC}"
    echo ""
    echo "  2. サーバーへデプロイ:"
    echo "     ${YELLOW}./script/deploy.sh${NC}"
    echo ""
    echo "  3. 開発サーバーを起動:"
    echo "     ${YELLOW}cd next && npm run dev${NC}"
    echo ""
    echo -e "${BLUE}📚 詳細なドキュメント:${NC}"
    echo "  • README.md"
    echo "  • README_SETUP.md"
    echo "  • README_CONOHA.md"
    echo ""
}

# スクリプトを実行
main