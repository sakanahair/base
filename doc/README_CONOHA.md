# 🚀 ConoHa VPS + Firebase + Cloudflare 環境構築ガイド

## 📋 セットアップ手順

### 1. 初回セットアップ

```bash
# サーバー初期設定を実行
./script/setup-server.sh

# Mutagen同期を開始
./script/sync-start.sh

# アプリケーションをデプロイ
./script/deploy.sh
```

### 2. Nginx設定の適用

```bash
# サーバーにSSH接続
ssh root@dev.sakana

# Nginx設定をコピー
cp /var/www/sakana/config/nginx.conf /etc/nginx/sites-available/sakana
ln -s /etc/nginx/sites-available/sakana /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### 3. SSL証明書の取得（Let's Encrypt）

```bash
# サーバー上で実行
certbot --nginx -d sakana.hair -d www.sakana.hair
certbot --nginx -d morishita-tax.jp -d www.morishita-tax.jp
```

## 🔧 開発コマンド

### Mutagen同期管理

```bash
# 同期開始
./script/sync-start.sh

# 同期停止
./script/sync-stop.sh

# 同期状態確認
mutagen sync list

# 同期モニター
mutagen sync monitor sakana
```

### デプロイ

```bash
# 本番デプロイ
./script/deploy.sh

# サーバーログ確認
ssh root@dev.sakana 'pm2 logs sakana-next'

# PM2状態確認
ssh root@dev.sakana 'pm2 status'
```

## 📁 ディレクトリ構造

```
/var/www/sakana/
├── next/          # Next.jsアプリケーション
│   ├── .next/     # ビルド出力
│   ├── public/    # 静的ファイル
│   └── app/       # App Router
├── flutter/       # Flutterプロジェクト
│   └── build/web/ # Flutter Webビルド
├── config/        # 設定ファイル
│   ├── nginx.conf # Nginx設定
│   └── pm2.config.js # PM2設定
├── logs/          # ログファイル
└── scripts/       # サーバー側スクリプト
```

## 🌐 アクセスURL

- **メインサイト**: http://dev.sakana.hair/
- **Flutter App**: http://dev.sakana.hair/app/
- **morishita**: http://dev.sakana.hair/morishita/
- **API**: http://dev.sakana.hair/api/
- **ヘルスチェック**: http://dev.sakana.hair/api/health

## 🔐 環境変数

`.env.local.example`を`.env.local`にコピーして設定：

```bash
cp .env.local.example .env.local
# .env.localを編集してFirebaseやCloudflareの認証情報を設定
```

## 🛠️ トラブルシューティング

### Mutagen同期が遅い

```bash
# 同期をリセット
mutagen sync reset sakana

# 再同期
mutagen sync flush sakana
```

### PM2でアプリが起動しない

```bash
ssh root@dev.sakana
cd /var/www/sakana/next
npm install
pm2 delete sakana-next
pm2 start .next/standalone/server.js --name sakana-next
pm2 save
```

### Nginxエラー

```bash
# 設定をテスト
nginx -t

# エラーログ確認
tail -f /var/www/sakana/logs/error.log
```

## 📊 監視

### PM2モニタリング

```bash
# リアルタイムモニター
ssh root@dev.sakana 'pm2 monit'

# メトリクス確認
ssh root@dev.sakana 'pm2 info sakana-next'
```

### ログ確認

```bash
# アプリケーションログ
ssh root@dev.sakana 'tail -f /var/www/sakana/logs/pm2-out.log'

# Nginxアクセスログ
ssh root@dev.sakana 'tail -f /var/www/sakana/logs/access.log'
```

## 🔄 バックアップと復旧

### バックアップ

```bash
# GitHubへプッシュ
git add -A && git commit -m "Backup" && git push origin master
```

### 復旧（新サーバー）

```bash
# 新サーバーで実行
git clone https://github.com/sakanahair/base.git /var/www/sakana
cd /var/www/sakana
./script/setup-server.sh
```

## 📝 注意事項

1. **Mutagen同期**：大きなファイルの変更時は同期に時間がかかる場合があります
2. **PM2**：サーバー再起動後も自動で起動するよう設定済み
3. **SSL証明書**：Let's Encryptの証明書は90日ごとに自動更新されます
4. **ファイアウォール**：必要なポート（22, 80, 443, 3000）のみ開放

## 🚀 次のステップ

1. **Firebase設定**：Firebaseプロジェクトを作成し、認証情報を設定
2. **Cloudflare設定**：DNSをCloudflareに移行し、プロキシを有効化
3. **監視設定**：UptimeRobotやNew Relicなどの監視ツールを設定
4. **CI/CD**：GitHub Actionsでの自動デプロイを設定