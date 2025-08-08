# 🚀 morishita-tax.jp デプロイ手順

## ✅ 設定完了内容

1. **vercel.json** - morishita-tax.jp用のリライト設定済み
2. **next/public/morishita/** - 森下税理士事務所のHTMLファイル配置済み

## 📝 デプロイ手順

### 1️⃣ Vercelアカウントの準備
```bash
# Vercel CLIをインストール（未インストールの場合）
npm i -g vercel
```

### 2️⃣ プロジェクトをビルド
```bash
cd /Users/apple/DEV/SAKANA_AI
./script/build-only.sh
```

### 3️⃣ Vercelにデプロイ
```bash
# 初回デプロイ（プロジェクト名などを設定）
vercel

# 本番環境にデプロイ
vercel --prod
```

### 4️⃣ Vercelダッシュボードでドメイン設定

1. **Vercelダッシュボードにアクセス**
   - https://vercel.com/dashboard
   - デプロイしたプロジェクトを選択

2. **Settings → Domains に移動**

3. **ドメインを追加**
   - `morishita-tax.jp` を入力して Add
   - `www.morishita-tax.jp` も追加（オプション）

4. **DNS設定の指示が表示される**
   - Vercelが提供するDNS設定をコピー

### 5️⃣ ドメインプロバイダーでDNS設定

ドメイン管理画面（お名前.com、ムームードメインなど）で：

#### Aレコード（推奨）
```
Type: A
Name: @ (またはルート)
Value: 76.76.21.21
```

#### またはCNAMEレコード
```
Type: CNAME
Name: @ (またはルート) 
Value: cname.vercel-dns.com
```

#### wwwサブドメイン用
```
Type: CNAME
Name: www
Value: cname.vercel-dns.com
```

### 6️⃣ SSL証明書の自動発行を待つ

- Vercelが自動でSSL証明書を発行（数分〜1時間）
- Vercelダッシュボードで緑のチェックマークが表示されたら完了

## ✅ 確認方法

1. **ドメインステータス確認**
   - Vercelダッシュボード → Settings → Domains
   - `morishita-tax.jp` が「Valid Configuration」になっているか確認

2. **アクセステスト**
   ```bash
   # DNSが反映されたか確認
   nslookup morishita-tax.jp
   
   # ブラウザでアクセス
   https://morishita-tax.jp
   https://www.morishita-tax.jp
   ```

## 📁 現在の構成

```
vercel.json
├── morishita-tax.jp → /public/morishita/
└── www.morishita-tax.jp → /public/morishita/

next/public/morishita/
├── index.html          # メインHTML
├── js/                 # JavaScriptファイル
├── theme/              # CSSファイル
├── images/             # 画像ファイル
└── components/         # コンポーネント
```

## ⚠️ 注意事項

1. **DNS反映時間**
   - 通常5分〜48時間かかります
   - 日本のドメインは比較的早く反映されます

2. **キャッシュクリア**
   - ブラウザキャッシュをクリア（Cmd+Shift+R）
   - DNS キャッシュをクリア: `sudo dscacheutil -flushcache`

3. **更新時**
   ```bash
   # コンテンツを更新後
   vercel --prod
   ```

## 🔧 トラブルシューティング

### ドメインが接続されない
- DNS設定が正しいか確認
- Vercelダッシュボードでエラーメッセージを確認
- DNS伝播を待つ（最大48時間）

### 404エラー
- `/public/morishita/index.html`が存在するか確認
- `vercel.json`のリライト設定を確認

### HTTPSエラー
- SSL証明書の発行を待つ
- Vercelダッシュボードで証明書ステータスを確認

## 📞 サポート

問題が解決しない場合：
1. Vercelサポート: https://vercel.com/support
2. ドメインプロバイダーのサポート