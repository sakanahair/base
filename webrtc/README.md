# Asterisk WebRTC Setup Guide

このガイドは、phone.sakana.hairサーバーにAsterisk WebRTC電話システムを構築するための手順書です。

## 📋 必要要件

- Ubuntu Server 20.04 LTS 以上
- ドメイン名: phone.sakana.hair
- SSL証明書（Let's Encrypt）
- 開放ポート:
  - 80/tcp (Let's Encrypt)
  - 443/tcp (Let's Encrypt)
  - 8088/tcp (HTTP WebSocket)
  - 8089/tcp (HTTPS WebSocket)
  - 10000-20000/udp (RTP Media)

## 🚀 クイックスタート

### 1. サーバーにSSH接続

```bash
ssh root@phone.sakana.hair
```

### 2. セットアップスクリプトのアップロード

このディレクトリ内のファイルをサーバーにアップロード:

```bash
# ローカルから実行
scp -r asterisk-setup/ root@phone.sakana.hair:/root/
```

### 3. インストールスクリプトの実行

```bash
cd /root/asterisk-setup
chmod +x *.sh
sudo ./install-asterisk.sh
```

### 4. SSL証明書の取得

```bash
# Asteriskを一時停止（ポート80を使用するため）
sudo systemctl stop asterisk

# 証明書を取得
sudo certbot certonly --standalone -d phone.sakana.hair

# 証明書をコピー
sudo cp /etc/letsencrypt/live/phone.sakana.hair/fullchain.pem /etc/asterisk/keys/
sudo cp /etc/letsencrypt/live/phone.sakana.hair/privkey.pem /etc/asterisk/keys/
sudo chown -R asterisk:asterisk /etc/asterisk/keys/
```

### 5. 設定ファイルの配置

```bash
# バックアップを作成
sudo cp /etc/asterisk/pjsip.conf /etc/asterisk/pjsip.conf.backup
sudo cp /etc/asterisk/http.conf /etc/asterisk/http.conf.backup
sudo cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup
sudo cp /etc/asterisk/rtp.conf /etc/asterisk/rtp.conf.backup

# 新しい設定をコピー
sudo cp pjsip.conf /etc/asterisk/
sudo cp http.conf /etc/asterisk/
sudo cp extensions.conf /etc/asterisk/
sudo cp rtp.conf /etc/asterisk/

# 権限設定
sudo chown -R asterisk:asterisk /etc/asterisk/
```

### 6. ファイアウォールの設定

```bash
sudo ./setup-firewall.sh
```

### 7. Asteriskの起動

```bash
# Asteriskサービスを起動
sudo systemctl start asterisk
sudo systemctl enable asterisk

# ステータス確認
sudo systemctl status asterisk

# ログ確認
sudo asterisk -rvvv
```

## 🔐 セキュリティ設定

### パスワードの変更

`/etc/asterisk/pjsip.conf`を編集して、各ユーザーのパスワードを変更:

```ini
[1000](webrtc-auth-template)
type=auth
username=1000
password=your_secure_password_here  ; ← ここを変更
```

### Fail2banの設定（推奨）

```bash
sudo apt install fail2ban

# Asterisk用の設定を作成
sudo nano /etc/fail2ban/jail.local
```

以下を追加:

```ini
[asterisk]
enabled = true
filter = asterisk
action = iptables-allports[name=ASTERISK]
logpath = /var/log/asterisk/security
maxretry = 3
bantime = 3600
```

## 🧪 動作テスト

### 1. ブラウザテスト

1. `https://www.linekun.dev/phone-test.html`にアクセス
2. 接続情報を入力:
   - 内線番号: 1000
   - パスワード: 設定したパスワード
   - サーバーURL: wss://phone.sakana.hair:8089/ws
3. 「接続」ボタンをクリック

### 2. 内線間通話テスト

1. 2つのブラウザタブまたは別のデバイスで接続
   - タブ1: 内線1000で接続
   - タブ2: 内線1001で接続
2. 一方から他方の内線番号を入力して発信

### 3. エコーテスト

- 内線600に発信すると、自分の声がエコーバックされます

### 4. 音楽保留テスト

- 内線601に発信すると、保留音が流れます

## 📊 モニタリング

### Asterisk CLI

```bash
# CLIに接続
sudo asterisk -rvvv

# 有用なコマンド
pjsip show endpoints        # エンドポイント一覧
pjsip show registrations   # 登録状況
core show channels         # アクティブな通話
pjsip show contacts        # 接続中のWebRTCクライアント
```

### ログ確認

```bash
# リアルタイムログ
tail -f /var/log/asterisk/full

# エラーログのみ
tail -f /var/log/asterisk/messages | grep ERROR

# セキュリティログ
tail -f /var/log/asterisk/security
```

## 🔧 トラブルシューティング

### 接続できない場合

1. **ファイアウォール確認**
   ```bash
   sudo ufw status
   ```

2. **証明書の確認**
   ```bash
   ls -la /etc/asterisk/keys/
   openssl x509 -in /etc/asterisk/keys/fullchain.pem -text -noout
   ```

3. **WebSocketモジュール確認**
   ```bash
   sudo asterisk -rx "module show like websocket"
   ```

### 音声が聞こえない場合

1. **RTPポート確認**
   ```bash
   sudo netstat -unlp | grep asterisk
   ```

2. **STUN設定確認**
   ```bash
   sudo asterisk -rx "pjsip show endpoint 1000"
   ```

### 登録できない場合

1. **認証情報確認**
   ```bash
   sudo asterisk -rx "pjsip show auth 1000"
   ```

2. **エンドポイント設定確認**
   ```bash
   sudo asterisk -rx "pjsip show endpoint 1000"
   ```

## 📝 メンテナンス

### SSL証明書の自動更新

```bash
# Cronジョブを設定
sudo crontab -e
```

以下を追加:

```cron
0 2 * * * certbot renew --post-hook "cp /etc/letsencrypt/live/phone.sakana.hair/*.pem /etc/asterisk/keys/ && chown -R asterisk:asterisk /etc/asterisk/keys/ && systemctl reload asterisk"
```

### バックアップ

```bash
# 設定ファイルのバックアップ
tar -czf asterisk-config-$(date +%Y%m%d).tar.gz /etc/asterisk/

# 音声ファイルのバックアップ（録音がある場合）
tar -czf asterisk-recordings-$(date +%Y%m%d).tar.gz /var/spool/asterisk/
```

## 🚨 セキュリティ推奨事項

1. **強力なパスワードを使用**
   - 各内線に異なるパスワードを設定
   - 最低12文字以上、英数字記号を含む

2. **アクセス制限**
   - 必要に応じてIPアドレス制限を実装
   - VPNの使用を検討

3. **定期的な更新**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

4. **監視**
   - ログを定期的に確認
   - 異常なアクセスパターンを監視

## 📞 クライアント側の実装

### Next.jsアプリケーション

1. `/phone/webrtc`ページにアクセス
2. 接続情報を入力して通話可能

### テストHTML

`https://www.linekun.dev/phone-test.html`で簡単にテスト可能

## 📚 参考資料

- [Asterisk Documentation](https://wiki.asterisk.org/)
- [PJSIP Configuration](https://wiki.asterisk.org/wiki/display/AST/PJSIP+Configuration)
- [WebRTC with Asterisk](https://wiki.asterisk.org/wiki/display/AST/WebRTC+tutorial+using+PJSIP)
- [SIP.js Documentation](https://sipjs.com/)

## ❓ サポート

問題が発生した場合は、以下の情報と共に報告してください:

1. Asteriskのバージョン: `asterisk -V`
2. エラーログ: `/var/log/asterisk/messages`
3. 設定ファイル（パスワードは除く）
4. ブラウザのコンソールログ