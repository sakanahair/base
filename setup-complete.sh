#!/bin/bash

# ============================================
# SAKANA AI - 完全自動セットアップスクリプト
# 別のMacでも完璧に動作する版
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
echo "║     SAKANA AI Complete Setup Script      ║"
echo "║         Full Installation                 ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# 作業ディレクトリ
WORK_DIR=$(pwd)
PROJECT_NAME="SAKANA_AI"

# OS検出
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${BLUE}📍 検出されたOS: macOS${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="ubuntu"
        echo -e "${BLUE}📍 検出されたOS: Linux/Ubuntu${NC}"
    else
        echo -e "${RED}❌ サポートされていないOSです${NC}"
        exit 1
    fi
}

# Homebrewのインストール（Mac用）
install_homebrew() {
    if [[ "$OS" == "macos" ]]; then
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
    fi
}

# Node.jsのインストール
install_nodejs() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}📦 Node.js 20.xをインストールしています...${NC}"
        if [[ "$OS" == "macos" ]]; then
            brew install node@20
            brew link node@20 --force --overwrite
        else
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        echo -e "${GREEN}✅ Node.js v${NODE_VERSION} は既にインストールされています${NC}"
    fi
}

# Flutterのインストール
install_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo -e "${YELLOW}📦 Flutterをインストールしています...${NC}"
        if [[ "$OS" == "macos" ]]; then
            brew install --cask flutter || {
                echo -e "${YELLOW}Homebrewでのインストールに失敗しました。直接インストールします...${NC}"
                cd ~
                git clone https://github.com/flutter/flutter.git -b stable
                echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zprofile
                export PATH="$PATH:$HOME/flutter/bin"
                cd "$WORK_DIR"
            }
        else
            # Ubuntu用
            sudo apt-get update
            sudo apt-get install -y git curl unzip xz-utils zip libglu1-mesa
            cd ~
            git clone https://github.com/flutter/flutter.git -b stable
            echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
            export PATH="$PATH:$HOME/flutter/bin"
            cd "$WORK_DIR"
        fi
        
        # Flutter初期設定
        flutter config --no-analytics
        flutter doctor --android-licenses 2>/dev/null || true
    else
        echo -e "${GREEN}✅ Flutter は既にインストールされています${NC}"
    fi
}

# Mutagenのインストール（Mac用、Xcode不要版）
install_mutagen() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v mutagen &> /dev/null; then
            echo -e "${YELLOW}📦 Mutagenをインストールしています...${NC}"
            
            # アーキテクチャを判定
            ARCH=$(uname -m)
            if [[ "$ARCH" == "arm64" ]]; then
                MUTAGEN_ARCH="arm64"
            else
                MUTAGEN_ARCH="amd64"
            fi
            
            # 最新バージョンを取得
            MUTAGEN_VERSION="0.18.1"
            DOWNLOAD_URL="https://github.com/mutagen-io/mutagen/releases/download/v${MUTAGEN_VERSION}/mutagen_darwin_${MUTAGEN_ARCH}_v${MUTAGEN_VERSION}.tar.gz"
            
            # ダウンロードとインストール
            cd /tmp
            curl -fsSL -o mutagen.tar.gz "$DOWNLOAD_URL"
            tar -xzf mutagen.tar.gz
            sudo mv mutagen /usr/local/bin/ 2>/dev/null || mv mutagen /usr/local/bin/
            sudo chmod +x /usr/local/bin/mutagen 2>/dev/null || chmod +x /usr/local/bin/mutagen
            rm -f mutagen.tar.gz
            cd "$WORK_DIR"
            
            echo -e "${GREEN}✅ Mutagenインストール完了${NC}"
        else
            echo -e "${GREEN}✅ Mutagenは既にインストールされています${NC}"
        fi
    fi
}

# プロジェクトのクローンまたは作成
setup_project() {
    echo ""
    echo -e "${BLUE}📂 プロジェクトのセットアップ${NC}"
    
    # GitHubトークンの確認
    if [ -z "$GITHUB_TOKEN" ]; then
        GITHUB_TOKEN="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"
    fi
    
    if [ -d "$PROJECT_NAME" ]; then
        echo -e "${YELLOW}ディレクトリ $PROJECT_NAME は既に存在します${NC}"
        read -p "削除して再作成しますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_NAME"
        else
            cd "$PROJECT_NAME"
            return
        fi
    fi
    
    echo -e "${YELLOW}📥 リポジトリをクローンしています...${NC}"
    git clone "https://${GITHUB_TOKEN}@github.com/sakanahair/base.git" "$PROJECT_NAME" || {
        echo -e "${YELLOW}クローンに失敗しました。新規作成します...${NC}"
        mkdir -p "$PROJECT_NAME"
    }
    
    cd "$PROJECT_NAME"
}

# Next.jsプロジェクトのセットアップ
setup_nextjs() {
    echo -e "${BLUE}⚡ Next.jsプロジェクトをセットアップ中...${NC}"
    
    # nextディレクトリの確認と作成
    if [ ! -d "next" ]; then
        mkdir -p next
    fi
    
    cd next
    
    # package.jsonが存在しない場合は作成
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}package.jsonを作成中...${NC}"
        cat > package.json << 'EOF'
{
  "name": "sakana-next",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "build:all": "bash ../script/build.sh",
    "build:flutter": "cd ../flutter && flutter build web --release --base-href /app/",
    "clean": "rm -rf .next dist node_modules package-lock.json"
  },
  "dependencies": {
    "next": "15.0.3",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "@xterm/xterm": "^5.5.0",
    "@xterm/addon-fit": "^0.10.0",
    "@xterm/addon-web-links": "^0.11.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "eslint": "^8",
    "eslint-config-next": "15.0.3",
    "typescript": "^5",
    "serve": "^14.2.0"
  }
}
EOF
    fi
    
    # tsconfig.jsonの作成
    if [ ! -f "tsconfig.json" ]; then
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
    fi
    
    # next.config.tsの作成
    if [ ! -f "next.config.ts" ]; then
        cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  output: 'standalone',
  reactStrictMode: true,
}

export default nextConfig
EOF
    fi
    
    # appディレクトリの作成
    mkdir -p app
    
    # app/layout.tsxの作成
    if [ ! -f "app/layout.tsx" ]; then
        cat > app/layout.tsx << 'EOF'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'SAKANA AI',
  description: 'SAKANA AI Platform',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  )
}
EOF
    fi
    
    # app/page.tsxの作成
    if [ ! -f "app/page.tsx" ]; then
        cat > app/page.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'

export default function Home() {
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 1000)
    return () => clearTimeout(timer)
  }, [])

  if (isLoading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        fontSize: '24px'
      }}>
        Loading...
      </div>
    )
  }

  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      <h1 style={{ fontSize: '3rem', marginBottom: '2rem' }}>
        SAKANA AI
      </h1>
      <div style={{ display: 'flex', gap: '2rem' }}>
        <a href="/app/" style={{
          padding: '1rem 2rem',
          background: '#0070f3',
          color: 'white',
          textDecoration: 'none',
          borderRadius: '8px'
        }}>
          Flutter App
        </a>
        <a href="/terminal" style={{
          padding: '1rem 2rem',
          background: '#333',
          color: 'white',
          textDecoration: 'none',
          borderRadius: '8px'
        }}>
          Terminal
        </a>
      </div>
    </div>
  )
}
EOF
    fi
    
    # publicディレクトリの作成
    mkdir -p public
    
    # 依存関係のインストール
    echo -e "${YELLOW}依存関係をインストール中...${NC}"
    npm install
    
    cd ..
}

# Flutterプロジェクトのセットアップ
setup_flutter() {
    echo -e "${BLUE}📱 Flutterプロジェクトをセットアップ中...${NC}"
    
    # flutterディレクトリの確認
    if [ ! -d "flutter" ]; then
        echo -e "${YELLOW}Flutterプロジェクトを作成中...${NC}"
        flutter create flutter --platforms=web,ios,android
    fi
    
    cd flutter
    
    # 依存関係の取得
    flutter pub get
    
    # Webビルド（初回）
    echo -e "${YELLOW}Flutter Webをビルド中...${NC}"
    flutter build web --release --base-href /app/
    
    # ビルド結果をNext.jsにコピー
    if [ -d "build/web" ]; then
        rm -rf ../next/public/app
        mkdir -p ../next/public
        cp -r build/web ../next/public/app
        echo -e "${GREEN}✅ Flutter Webビルド完了${NC}"
    fi
    
    cd ..
}

# スクリプトディレクトリのセットアップ
setup_scripts() {
    echo -e "${BLUE}📝 スクリプトをセットアップ中...${NC}"
    
    mkdir -p script
    
    # build.shの作成
    cat > script/build.sh << 'EOFSCRIPT'
#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 ビルドを開始します..."

# Flutter Web ビルド
if [ -d "$ROOT_DIR/flutter" ] && command -v flutter &> /dev/null; then
    echo "📱 Flutter Web をビルドしています..."
    cd "$ROOT_DIR/flutter"
    flutter pub get
    flutter build web --release --base-href /app/
    
    # Next.jsにコピー
    rm -rf "$ROOT_DIR/next/public/app"
    mkdir -p "$ROOT_DIR/next/public"
    cp -r build/web "$ROOT_DIR/next/public/app"
fi

# Next.js ビルド
echo "⚡ Next.js をビルドしています..."
cd "$ROOT_DIR/next"
npm install
npm run build

echo "✅ ビルド完了！"
EOFSCRIPT
    
    chmod +x script/build.sh
    
    # dev.shの作成
    cat > script/dev.sh << 'EOFSCRIPT'
#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 開発サーバーを起動します..."

cd "$ROOT_DIR/next"
npm run dev
EOFSCRIPT
    
    chmod +x script/dev.sh
}

# 環境変数ファイルの作成
setup_env() {
    echo -e "${BLUE}🔧 環境変数を設定中...${NC}"
    
    if [ ! -f ".env.example" ]; then
        cat > .env.example << 'EOF'
# GitHub設定
GITHUB_TOKEN=your_github_personal_access_token_here

# サーバー設定
SERVER_HOST=dev.sakana.hair
SERVER_USER=root

# Node環境
NODE_ENV=development
PORT=3000
EOF
    fi
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        # 既知のトークンを設定
        sed -i.bak 's/your_github_personal_access_token_here/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/' .env
        rm -f .env.bak
    fi
}

# SSH設定（オプション）
setup_ssh() {
    echo ""
    read -p "SSH設定を追加しますか？ (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SSH_CONFIG="
Host dev.sakana
    HostName dev.sakana.hair
    User root
    Port 22"
        
        if ! grep -q "Host dev.sakana" ~/.ssh/config 2>/dev/null; then
            echo "$SSH_CONFIG" >> ~/.ssh/config
            echo -e "${GREEN}✅ SSH設定を追加しました${NC}"
        else
            echo -e "${YELLOW}SSH設定は既に存在します${NC}"
        fi
    fi
}

# メイン処理
main() {
    echo -e "${CYAN}完全セットアップを開始します...${NC}"
    echo ""
    
    # OS検出
    detect_os
    
    # 必要なツールのインストール
    if [[ "$OS" == "macos" ]]; then
        install_homebrew
    fi
    
    install_nodejs
    install_flutter
    
    if [[ "$OS" == "macos" ]]; then
        install_mutagen
    fi
    
    # プロジェクトセットアップ
    setup_project
    setup_nextjs
    
    if command -v flutter &> /dev/null; then
        setup_flutter
    fi
    
    setup_scripts
    setup_env
    setup_ssh
    
    # 完了メッセージ
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ セットアップ完了！                  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo ""
    echo "1. 開発サーバーを起動:"
    echo "   ${YELLOW}cd $PROJECT_NAME${NC}"
    echo "   ${YELLOW}./script/dev.sh${NC}"
    echo ""
    echo "2. ビルド:"
    echo "   ${YELLOW}./script/build.sh${NC}"
    echo ""
    echo "3. アクセス:"
    echo "   ${YELLOW}http://localhost:3000${NC}"
    echo ""
    
    # 自動起動オプション
    read -p "開発サーバーを今すぐ起動しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$WORK_DIR/$PROJECT_NAME"
        ./script/dev.sh
    fi
}

# スクリプト実行
main