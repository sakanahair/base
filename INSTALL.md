# 🚀 SAKANA AI - インストールガイド

## 📱 クイックスタート（推奨）

### ワンライナーインストール

Mac/Ubuntuで以下のコマンドを実行するだけで、全ての環境構築が完了します：

```bash
curl -fsSL https://raw.githubusercontent.com/sakanahair/base/master/setup.sh | bash
```

または、リポジトリをクローンしてから実行：

```bash
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI
./setup.sh
```

## 🎯 setup.shが自動で行うこと

### 1. OS検出
- macOS / Ubuntu を自動判別
- OS固有のインストール方法を選択

### 2. 必要なツールのインストール
- **Node.js 20.x**: JavaScript実行環境
- **Flutter**: マルチプラットフォーム開発
- **Mutagen**: ファイル同期ツール
- **Homebrew** (macOSのみ): パッケージマネージャー

### 3. プロジェクトセットアップ
- GitHubからのクローン（オプション）
- npm/Flutter依存関係のインストール
- スクリプトへの実行権限付与

### 4. 環境設定
- SSH設定の追加（dev.sakana）
- 環境変数ファイルの作成（.env, .env.local）
- Mutagen同期の初期設定

## 🖥️ 対応OS

### macOS
- macOS 12 (Monterey) 以降
- Apple Silicon (M1/M2) & Intel対応

### Ubuntu
- Ubuntu 20.04 LTS以降
- Ubuntu 22.04 LTS推奨

## 📋 手動インストール

自動セットアップを使わない場合の手順：

### macOS

```bash
# 1. Homebrewインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 必要なツール
brew install node@20
brew install --cask flutter
brew install mutagen-io/mutagen/mutagen

# 3. プロジェクトクローン
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI

# 4. 依存関係
cd next && npm install && cd ..
cd flutter && flutter pub get && cd ..

# 5. 実行権限
chmod +x script/*.sh
```

### Ubuntu

```bash
# 1. Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Flutter
sudo apt-get update
sudo apt-get install -y git curl unzip xz-utils zip libglu1-mesa
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 3. Mutagen
wget https://github.com/mutagen-io/mutagen/releases/download/v0.17.2/mutagen_linux_amd64_v0.17.2.tar.gz
sudo tar -xzf mutagen_linux_amd64_v0.17.2.tar.gz -C /usr/local/bin/

# 4. プロジェクトクローン
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI

# 5. 依存関係と権限
cd next && npm install && cd ..
cd flutter && flutter pub get && cd ..
chmod +x script/*.sh
```

## 🔧 セットアップ後の確認

インストールが成功したか確認：

```bash
# バージョン確認
node --version  # v20.x.x
flutter --version  # Flutter 3.x.x
mutagen version  # Mutagen v0.x.x

# プロジェクト構造確認
ls -la script/  # スクリプトファイルが表示される
ls -la next/node_modules/  # 依存関係がインストール済み
```

## 🚀 開発開始

セットアップ完了後：

```bash
# 開発サーバー起動
./script/build.sh
# → 開発サーバーを起動しますか？ (y/n): y

# ブラウザでアクセス
open http://localhost:3000
```

## 🆘 トラブルシューティング

### 権限エラーが出る場合

```bash
chmod +x setup.sh
chmod +x script/*.sh
```

### Node.jsのバージョンが古い場合

```bash
# macOS
brew upgrade node@20
brew link --overwrite node@20

# Ubuntu
sudo apt-get remove nodejs
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Flutterが見つからない場合

```bash
# パスを確認
echo $PATH

# パスに追加（bashの場合）
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# パスに追加（zshの場合）
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

## 📞 サポート

問題が解決しない場合は、GitHubのIssuesでお問い合わせください：
https://github.com/sakanahair/base/issues