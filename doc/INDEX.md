# 📚 SAKANA AI ドキュメント

SAKANA AIプロジェクトの技術ドキュメント集です。

## 📖 ドキュメント一覧

### セットアップ・インストール
- **[INSTALL.md](./INSTALL.md)** - 詳細なインストールガイド
  - Mac/Ubuntu両対応の手動・自動インストール手順
  - トラブルシューティング

- **[README_SETUP.md](./README_SETUP.md)** - プロジェクトセットアップ手順
  - 新しいMacでのセットアップ
  - 必要なツールのインストール
  - 開発環境の構築

### インフラ・デプロイ
- **[README_CONOHA.md](./README_CONOHA.md)** - ConoHa VPS環境構築ガイド
  - サーバー初期設定
  - Nginx/PM2設定
  - SSL証明書取得
  - デプロイ手順

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - デプロイメント詳細（旧Vercel版）
  - 旧デプロイ設定の参考資料

### 開発経緯・設計
- **[CLAUDE.md](./CLAUDE.md)** - 開発経緯と設計決定
  - Vercelからの移行理由
  - 技術選定の背景
  - 問題解決の過程
  - 学んだ教訓

- **[README.md](./README.md)** - 初期技術仕様書
  - Flutter + Next.js統合の詳細
  - 開発ワークフロー

## 🗂 ドキュメント構成

```
doc/
├── INDEX.md           # このファイル（ドキュメントインデックス）
├── README.md          # 初期技術仕様書
├── INSTALL.md         # インストールガイド
├── README_SETUP.md    # セットアップ手順
├── README_CONOHA.md   # ConoHa VPS設定
├── CLAUDE.md          # 開発経緯と設計決定
└── DEPLOYMENT.md      # デプロイメント詳細（旧）
```

## 📝 ドキュメント作成ガイドライン

### ファイル命名規則
- 大文字で始まる
- `.md`拡張子を使用
- 内容を表す明確な名前

### 記述スタイル
- 絵文字を活用して見やすく
- コードブロックは言語を指定
- 実際のコマンドはコピペ可能に
- 問題と解決策をセットで記載

### 更新時の注意
- 日付を記録
- 変更理由を明記
- 関連ドキュメントへのリンクを維持

## 🔍 クイックリファレンス

### よく使うコマンド

#### セットアップ
```bash
# 新規インストール
git clone https://github.com/sakanahair/base.git SAKANA_AI
cd SAKANA_AI
./setup.sh
```

#### 開発
```bash
# ビルド＆開発サーバー起動
./script/build.sh

# 開発サーバーのみ
cd next && npm run dev
```

#### デプロイ
```bash
# 本番環境へデプロイ
./script/deploy.sh

# Mutagen同期
mutagen sync list
mutagen sync flush sakana
```

#### トラブルシューティング
```bash
# PM2ログ確認
ssh root@dev.sakana 'pm2 logs sakana-next'

# Nginx設定テスト
ssh root@dev.sakana 'nginx -t'

# 権限修正
ssh root@dev.sakana 'chown -R www-data:www-data /var/www/sakana'
```

## 📊 プロジェクト統計

- **開始日**: 2025年8月
- **主要技術**: Next.js, Flutter, ConoHa VPS, Mutagen
- **ドキュメント数**: 7+
- **自動化スクリプト**: 10+

## 🆘 ヘルプ

ドキュメントに関する質問や改善提案は、[GitHub Issues](https://github.com/sakanahair/base/issues)でお願いします。

---

最終更新: 2025年8月9日