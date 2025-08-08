# Flutter + Next.js マルチプラットフォームアプリ

iOS、Android、Webに対応したFlutterアプリケーションとNext.jsの統合環境です。

## 📁 プロジェクト構成

```
.
├── flutter/           # Flutterアプリケーション
├── next/              # Next.jsアプリケーション  
├── script/            # ビルド・開発用スクリプト
│   ├── build.sh       # ビルド＆自動起動（ポート3900）
│   ├── build-only.sh  # ビルドのみ（サーバー起動なし）
│   ├── serve.sh       # ビルド済みアプリの起動
│   ├── dev.sh         # 開発サーバー起動
│   └── update-flutter.sh # Flutter更新
├── doc/               # ドキュメント
│   └── README.md      # 詳細ドキュメント
└── README.md          # このファイル
```

## 🚀 クイックスタート

### ビルド＆自動起動（ポート3900）
```bash
./script/build.sh
```

### 開発サーバー起動（ポート3000）
```bash
./script/dev.sh
```

### その他のコマンド
```bash
# ビルドのみ（サーバー起動なし）
./script/build-only.sh

# ビルド済みアプリを起動（デフォルト: ポート3900）
./script/serve.sh
./script/serve.sh 8080  # 別のポートで起動

# Flutter更新
./script/update-flutter.sh
```

## 📚 詳細ドキュメント

詳細な使用方法、設定、トラブルシューティングについては [doc/README.md](doc/README.md) を参照してください。

## 🌐 アクセスURL

- **Next.js**: http://localhost:3000
- **Flutter Web**: http://localhost:3000/app/
- **森下税理士事務所**: https://morishita-tax.jp (Vercel自動デプロイ)
- **Git Author**: hideo@sakana.hair