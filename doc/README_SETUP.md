# 🚀 SAKANA AI - セットアップガイド

## 📋 必要な環境

### macOS
- Node.js 20.x
- Flutter 3.x
- Mutagen

### サーバー（ConoHa VPS）
- Ubuntu 24.04 LTS
- Node.js 20.x
- PM2
- Nginx

## 🔧 初期セットアップ（新しいMac）

### 1. 必要なツールのインストール

```bash
# Homebrewのインストール（まだの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js 20.xのインストール
brew install node@20

# Flutterのインストール
brew install --cask flutter

# Mutagenのインストール
brew install mutagen-io/mutagen/mutagen
```

### 2. プロジェクトのクローン

```bash
# リポジトリをクローン
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI
```

### 3. 依存関係のインストール

```bash
# Next.jsの依存関係
cd next
npm install
cd ..

# Flutterの依存関係
cd flutter
flutter pub get
cd ..

# スクリプトに実行権限を付与
chmod +x script/*.sh
```

### 4. SSH設定

`~/.ssh/config`に以下を追加：

```
Host dev.sakana
    HostName dev.sakana.hair
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 180
    TCPKeepAlive yes
```

### 5. 環境変数の設定

```bash
# 環境変数ファイルをコピー
cp .env.example .env
cp next/.env.local.example next/.env.local

# 必要に応じて.envと.env.localを編集
```

## 🏃 開発開始

### ローカル開発

```bash
# ビルドと開発サーバー起動
./script/build.sh
# → 開発サーバーを起動しますか？ (y/n): y
```

### サーバーへのデプロイ

```bash
# 初回セットアップ（サーバー側）
./script/setup-server.sh

# Mutagen同期開始
./script/sync-start.sh

# デプロイ
./script/deploy.sh
```

## 📁 プロジェクト構造

```
SAKANA_AI/
├── next/           # Next.jsアプリケーション
├── flutter/        # Flutterアプリケーション
├── script/         # 自動化スクリプト
│   ├── build.sh    # ビルドスクリプト（Mac/Linux両対応）
│   ├── deploy.sh   # デプロイスクリプト
│   ├── sync-start.sh # Mutagen同期開始
│   └── setup-server.sh # サーバー初期設定
├── config/         # 設定ファイル
│   └── nginx.conf  # Nginx設定
└── mutagen.yml     # Mutagen設定

```

## 🌐 アクセスURL

- **開発環境**: http://localhost:3000
- **本番環境**: https://dev.sakana.hair
- **Flutter App**: /app/
- **Morishita**: /morishita/

## 🔨 よく使うコマンド

```bash
# ローカルビルド
./script/build.sh

# 開発サーバー起動
cd next && npm run dev

# デプロイ
./script/deploy.sh

# Mutagen同期状態確認
mutagen sync list

# PM2ログ確認（サーバー）
ssh dev.sakana 'pm2 logs sakana-next'
```

## ⚠️ 注意事項

1. **Mutagen同期**: 大きなファイルの変更時は同期に時間がかかる場合があります
2. **ポート**: デフォルトは3000番ポート
3. **SSL証明書**: Let's Encryptの証明書は90日ごとに自動更新

## 🆘 トラブルシューティング

### Mutagen同期が遅い場合
```bash
mutagen sync reset sakana
mutagen sync flush sakana
```

### PM2でアプリが起動しない場合
```bash
ssh dev.sakana
cd /var/www/sakana/next
npm install
pm2 delete sakana-next
pm2 start .next/standalone/server.js --name sakana-next
pm2 save
```

### 権限エラーの場合
```bash
ssh dev.sakana
chown -R www-data:www-data /var/www/sakana
chmod -R 755 /var/www/sakana
```