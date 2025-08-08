# 🚀 Vercelデプロイメント＆マルチドメイン設定ガイド

## 📋 概要

このプロジェクトは複数の独立したプロジェクトを、それぞれ独自のドメインでホスティングできるように設計されています。

## 🌐 ドメインマッピング

| ディレクトリ | カスタムドメイン例 | 説明 |
|------------|------------------|------|
| `/public/morishita/` | morishita.yourdomain.com | Morishitaプロジェクト |
| `/public/app/` | app.yourdomain.com | Flutter Webアプリ |
| `/app/terminal/` | terminal.yourdomain.com | Web Terminal |
| `/public/project-a/` | project-a.yourdomain.com | プロジェクトA |
| `/public/client/` | client.yourdomain.com | クライアント用サイト |

## 🛠️ セットアップ手順

### 1. Vercel CLIのインストール

```bash
npm i -g vercel
```

### 2. プロジェクトのビルド

```bash
# 完全ビルド
./script/build-only.sh
```

### 3. Vercelへのデプロイ

```bash
# 初回デプロイ
vercel

# 本番環境へのデプロイ
vercel --prod
```

### 4. カスタムドメインの設定

#### Vercelダッシュボードで：

1. **プロジェクト設定へ移動**
   - https://vercel.com/dashboard
   - プロジェクトを選択
   - Settings → Domains

2. **ドメインを追加**
   ```
   morishita.yourdomain.com
   app.yourdomain.com
   terminal.yourdomain.com
   project-a.yourdomain.com
   client.yourdomain.com
   ```

3. **DNS設定**
   
   お使いのDNSプロバイダーで以下のレコードを追加：
   
   ```
   CNAME morishita → cname.vercel-dns.com
   CNAME app      → cname.vercel-dns.com
   CNAME terminal → cname.vercel-dns.com
   CNAME project-a → cname.vercel-dns.com
   CNAME client   → cname.vercel-dns.com
   ```

## 📁 プロジェクト構造

```
SAKANA_AI/
├── vercel.json          # Vercelリライト設定
├── next/
│   ├── middleware.ts    # ドメインルーティング
│   ├── public/
│   │   ├── morishita/   # 独自ドメインプロジェクト
│   │   ├── app/         # Flutter Web
│   │   ├── project-a/   # その他のプロジェクト
│   │   └── client/      # クライアント用
│   └── app/
│       └── terminal/    # Reactアプリ
```

## 🔧 新しいプロジェクトの追加

### 1. ディレクトリを作成

```bash
mkdir -p next/public/new-project
```

### 2. コンテンツを配置

```bash
# HTMLファイルをコピー
cp -r your-project/* next/public/new-project/
```

### 3. vercel.jsonを更新

```json
{
  "rewrites": [
    // 既存の設定...
    {
      "source": "/:path*",
      "destination": "/new-project/:path*",
      "has": [
        {
          "type": "host",
          "value": "new-project.yourdomain.com"
        }
      ]
    }
  ]
}
```

### 4. middleware.tsを更新

```typescript
const domainMappings: Record<string, string> = {
  // 既存のマッピング...
  'new-project.yourdomain.com': '/new-project',
};
```

### 5. 再デプロイ

```bash
vercel --prod
```

## 🔄 Mutagenとの連携

ローカル開発とサーバー同期：

```bash
# 同期を作成
mutagen sync create \
  --name=project-sync \
  /Users/apple/DEV/SAKANA_AI/next/public/morishita \
  ssh://root@server.com/var/www/morishita

# 同期状態を確認
mutagen sync list

# 同期を一時停止
mutagen sync pause project-sync

# 同期を再開
mutagen sync resume project-sync
```

## 🌟 高度な設定

### 環境変数

`.env.local`を作成：

```env
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX
```

### アクセス制御

特定のドメインに認証を追加：

```typescript
// middleware.ts
if (hostname === 'admin.yourdomain.com') {
  // 認証チェック
  const token = request.cookies.get('auth-token');
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

### パフォーマンス最適化

```json
// vercel.json
{
  "functions": {
    "app/api/*.ts": {
      "maxDuration": 10
    }
  },
  "regions": ["hnd1", "sfo1"]
}
```

## 📊 分析とモニタリング

### Google Analytics設定

各ドメインごとに異なるGAトラッキングID：

```javascript
// ドメインごとのGA設定
const gaIds = {
  'morishita.yourdomain.com': 'G-XXXXXX1',
  'app.yourdomain.com': 'G-XXXXXX2',
  'client.yourdomain.com': 'G-XXXXXX3',
};
```

## 🚨 トラブルシューティング

### ドメインが正しく動作しない

1. DNS伝播を待つ（最大48時間）
2. Vercelダッシュボードでドメイン状態を確認
3. `vercel.json`の設定を確認

### ビルドエラー

```bash
# キャッシュをクリア
rm -rf .next
npm run clean
vercel --prod --force
```

### 404エラー

- `public/`ディレクトリ内にファイルが存在するか確認
- パスの大文字小文字を確認
- `middleware.ts`のマッピングを確認

## 📚 参考リンク

- [Vercel Documentation](https://vercel.com/docs)
- [Next.js Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware)
- [Custom Domains on Vercel](https://vercel.com/docs/concepts/projects/domains)
- [Mutagen Documentation](https://mutagen.io/documentation)