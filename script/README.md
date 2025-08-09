# スクリプト一覧

## 主要スクリプト

### setup.sh
- **用途**: 初期セットアップ（Mac/Ubuntu両対応）
- **実行**: `./script/setup.sh`
- **機能**: Node.js、Flutter、Mutagen のインストール

### setup-complete.sh
- **用途**: 完全セットアップ（プロジェクトファイル作成込み）
- **実行**: `./script/setup-complete.sh`
- **機能**: 必要なファイルがない場合も自動作成

### build.sh
- **用途**: Flutter + Next.js のビルド
- **実行**: `./script/build.sh`
- **機能**: 両方のプロジェクトをビルドして統合

### deploy.sh
- **用途**: Mac から本番サーバーへデプロイ
- **実行**: `./script/deploy.sh`
- **機能**: ビルド → Mutagen同期 → サーバー再起動

### deploy-server.sh
- **用途**: サーバー側でのデプロイ
- **実行**: `./script/deploy-server.sh`
- **機能**: サーバー上でビルド＆再起動

### dev.sh
- **用途**: 開発サーバー起動
- **実行**: `./script/dev.sh`
- **機能**: Next.js開発サーバーを起動

### cmdgit.sh
- **用途**: Git コミット＆プッシュ
- **実行**: `./script/cmdgit.sh "コミットメッセージ"`
- **機能**: 自動的にコミット＆プッシュ

## 同期スクリプト

### sync-start.sh
- **用途**: Mutagen同期を開始
- **実行**: `./script/sync-start.sh`

### sync-stop.sh
- **用途**: Mutagen同期を停止
- **実行**: `./script/sync-stop.sh`

## 補助スクリプト

### install-mutagen-direct.sh
- **用途**: Xcodeなしで Mutagen をインストール
- **実行**: `./script/install-mutagen-direct.sh`
- **機能**: GitHub から直接ダウンロード