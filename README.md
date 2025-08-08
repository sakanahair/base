# 🐟 SAKANA AI

Flutter × Next.js × ConoHa VPS による統合開発環境

## 🚀 クイックスタート

### ワンライナーインストール（推奨）
```bash
git clone https://github.com/sakanahair/base.git SAKANA_AI && cd SAKANA_AI && ./setup.sh
```

30秒で開発環境が整います！

## 📋 目次

- [概要](#概要)
- [アーキテクチャ](#アーキテクチャ)
- [インストール](#インストール)
- [開発](#開発)
- [デプロイ](#デプロイ)
- [ドキュメント](#ドキュメント)

## 🎯 概要

SAKANA AIは、Flutter WebとNext.jsを統合した次世代の開発環境です。

### 特徴
- **マルチプラットフォーム**: iOS/Android/Web対応
- **リアルタイム同期**: Mutagenによる双方向ファイル同期
- **自動デプロイ**: ワンコマンドでConoHa VPSへデプロイ
- **OS非依存**: Mac/Ubuntu両対応の開発環境

## 🏗 アーキテクチャ

```
┌─────────────────────────────────────────────┐
│             ユーザーアクセス                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│        Cloudflare (CDN/WAF/Cache)           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      ConoHa VPS (dev.sakana.hair)          │
│  ┌─────────────────────────────────────┐   │
│  │     Nginx (Reverse Proxy)           │   │
│  └─────────────────────────────────────┘   │
│            ↓            ↓                   │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   Next.js    │  │ Static Files │       │
│  │   (PM2)      │  │  /morishita  │       │
│  │   Port 3000  │  └──────────────┘       │
│  └──────────────┘                          │
│         ↓                                   │
│  ┌──────────────┐                          │
│  │ Flutter Web  │                          │
│  │   /app/      │                          │
│  └──────────────┘                          │
└─────────────────────────────────────────────┘
                    ↕
        Mutagen (双方向同期)
                    ↕
┌─────────────────────────────────────────────┐
│         ローカル開発環境 (Mac/Ubuntu)        │
└─────────────────────────────────────────────┘
```

## 💻 インストール

### 必要な環境
- macOS 12+ または Ubuntu 20.04+
- Git
- インターネット接続

### 自動セットアップ（推奨）

```bash
# 1. リポジトリをクローン
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI

# 2. セットアップスクリプトを実行
./setup.sh

# 以下が自動でインストールされます：
# ✅ Node.js 20.x
# ✅ Flutter 3.x
# ✅ Mutagen
# ✅ 全ての依存関係
# ✅ SSH設定
# ✅ 環境変数
```

### 手動セットアップ

詳細は[INSTALL.md](./doc/INSTALL.md)を参照してください。

## 🛠 開発

### ローカル開発サーバーの起動

```bash
# すべてをビルドして起動
./script/build.sh
# → 開発サーバーを起動しますか？ (y/n): y

# または個別に起動
cd next && npm run dev
```

### アクセスURL
- メインサイト: http://localhost:3000
- Flutter App: http://localhost:3000/app/
- Morishita: http://localhost:3000/morishita/

## 🚢 デプロイ

### 本番環境へのデプロイ

```bash
# ワンコマンドでデプロイ
./script/deploy.sh
```

このコマンドで以下が実行されます：
1. Flutter Webのビルド
2. Next.jsのビルド (standalone)
3. Mutagenによるサーバー同期
4. PM2でのアプリケーション再起動
5. Nginxの設定更新

### 本番URL
- https://dev.sakana.hair
- https://dev.sakana.hair/app/
- https://dev.sakana.hair/morishita/

## 📁 プロジェクト構造

```
SAKANA_AI/
├── next/               # Next.jsアプリケーション
│   ├── app/           # App Router
│   ├── public/        # 静的ファイル
│   │   ├── app/       # Flutter Webビルド
│   │   └── morishita/ # 森下税理士事務所サイト
│   └── middleware.ts  # パスリライト設定
├── flutter/           # Flutterアプリケーション
├── script/            # 自動化スクリプト
│   ├── setup.sh       # 初期セットアップ
│   ├── build.sh       # ビルドスクリプト
│   ├── deploy.sh      # デプロイスクリプト
│   └── sync-start.sh  # Mutagen同期開始
├── config/            # 設定ファイル
│   └── nginx.conf     # Nginx設定
└── mutagen.yml        # Mutagen同期設定
```

## 🔧 主要な技術スタック

| カテゴリ | 技術 | 用途 |
|---------|------|------|
| フロントエンド | Next.js 15.4 | SSR/SSG, App Router |
| モバイル/Web | Flutter 3.x | クロスプラットフォーム |
| サーバー | ConoHa VPS | Ubuntu 24.04 LTS |
| Webサーバー | Nginx | リバースプロキシ |
| プロセス管理 | PM2 | Node.js管理 |
| ファイル同期 | Mutagen | 双方向同期 |
| SSL | Let's Encrypt | HTTPS証明書 |
| CDN | Cloudflare | 配信最適化 |

## 📚 ドキュメント

- [INSTALL.md](./doc/INSTALL.md) - 詳細なインストールガイド
- [README_SETUP.md](./doc/README_SETUP.md) - セットアップ手順
- [README_CONOHA.md](./doc/README_CONOHA.md) - ConoHa VPS設定
- [CLAUDE.md](./doc/CLAUDE.md) - 開発経緯と設計決定

## 🆘 トラブルシューティング

### よくある問題

#### Mutagen同期が遅い
```bash
mutagen sync reset sakana
mutagen sync flush sakana
```

#### PM2でアプリが起動しない
```bash
ssh root@dev.sakana
cd /var/www/sakana/next
npm install
pm2 delete sakana-next
pm2 start .next/standalone/server.js --name sakana-next
pm2 save
```

#### 権限エラー
```bash
ssh root@dev.sakana
chown -R www-data:www-data /var/www/sakana
chmod -R 755 /var/www/sakana
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/AmazingFeature`)
3. 変更をコミット (`git commit -m 'Add some AmazingFeature'`)
4. ブランチにプッシュ (`git push origin feature/AmazingFeature`)
5. プルリクエストを作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 📞 サポート

質問や問題がある場合は、[Issues](https://github.com/sakanahair/base/issues)でお知らせください。

---

Built with ❤️ by SAKANA AI Team