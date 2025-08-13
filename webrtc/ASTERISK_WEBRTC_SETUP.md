# Asterisk WebRTC設定完了レポート

## 概要
Asterisk PBX 20.15.0でWebRTC（JsSIP）クライアントの接続設定を完了しました。
1000、1001、1002の3つのエンドポイントが正常に動作しています。

## 解決した問題と対処法

### 1. 404 Not Found エラー
**問題**: REGISTERリクエストで404エラーが発生し、登録できない
**原因**: 
- AOR（Address of Record）名が複雑（1000-aor形式）
- エンドポイント識別方法の設定が不適切

**解決方法**:
- AOR名をシンプルに変更（1000-aor → 1000）
- グローバル設定で`endpoint_identifier_order`を追加
- `identify_by`設定を削除してデフォルト値を使用

### 2. 488 Not Acceptable Here エラー
**問題**: 通話時にコーデック不一致でエラー
**原因**: WebRTC設定が不完全

**解決方法**:
- `webrtc=yes`を明示的に設定
- ICE/STUN設定を有効化
- 複数コーデック（opus, ulaw, alaw, g722）を許可

### 3. ダイヤルプランエラー
**問題**: 内線番号への発信で404エラー
**原因**: コンテキストが定義されていない

**解決方法**:
- `from-internal`コンテキストを作成
- 内線発信ルール（_10XX）を追加

## 最終設定

### /etc/asterisk/pjsip.conf

```ini
;==============================================================================
; Global Settings
;==============================================================================
[global]
type=global
endpoint_identifier_order=auth_username,username,ip,anonymous

;==============================================================================
; System Settings  
;==============================================================================
[system]
type=system
timer_t1=500
timer_b=32000

;==============================================================================
; Transport Configuration
;==============================================================================
[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:8089
cert_file=/etc/asterisk/keys/asterisk.crt
priv_key_file=/etc/asterisk/keys/asterisk.key
method=tlsv1_2
cipher=DEFAULT
verify_client=no
verify_server=no
allow_reload=yes

;==============================================================================
; WebRTC Users (1000-1002)
;==============================================================================

; User 1000
[1000]
type=endpoint
transport=transport-wss
context=from-internal
disallow=all
allow=opus,ulaw,alaw,g722
use_avpf=yes
media_encryption=dtls
dtls_verify=fingerprint
dtls_setup=actpass
ice_support=yes
media_use_received_transport=yes
rtcp_mux=yes
webrtc=yes
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes
direct_media=no
dtmf_mode=rfc4733
auth=1000-auth
aors=1000
callerid="WebRTC User 1000" <1000>

[1000]
type=aor
max_contacts=5
remove_existing=no
qualify_frequency=30

[1000-auth]
type=auth
auth_type=userpass
username=1000
password=webrtc_pass_1000
realm=asterisk

; User 1001 (同様の設定)
[1001]
type=endpoint
# ... (1000と同じ設定パターン)
auth=1001-auth
aors=1001
callerid="WebRTC User 1001" <1001>

[1001]
type=aor
max_contacts=5
remove_existing=no
qualify_frequency=30

[1001-auth]
type=auth
auth_type=userpass
username=1001
password=webrtc_pass_1001
realm=asterisk

; User 1002 (同様の設定)
[1002]
type=endpoint
# ... (1000と同じ設定パターン)
auth=1002-auth
aors=1002
callerid="WebRTC User 1002" <1002>

[1002]
type=aor
max_contacts=5
remove_existing=no
qualify_frequency=30

[1002-auth]
type=auth
auth_type=userpass
username=1002
password=webrtc_pass_1002
realm=asterisk
```

### /etc/asterisk/extensions.conf

```ini
[from-internal]
; 内線番号への発信（1000-1099）
exten => _10XX,1,NoOp(Calling extension ${EXTEN})
 same => n,Dial(PJSIP/${EXTEN},30)
 same => n,Hangup()

; エコーテスト
exten => 9999,1,Answer()
 same => n,Echo()
 same => n,Hangup()
```

### /etc/asterisk/rtp.conf

```ini
[general]
rtpstart=10000
rtpend=20000
icesupport=yes
stunaddr=stun.l.google.com:19302
```

### /etc/asterisk/http.conf

```ini
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/asterisk/keys/asterisk.crt
tlsprivatekey=/etc/asterisk/keys/asterisk.key
```

## 重要な設定ポイント

### 1. WebRTC必須設定
- `webrtc=yes` - WebRTC機能を有効化
- `use_avpf=yes` - Audio/Video Profile with Feedback
- `media_encryption=dtls` - DTLS暗号化
- `dtls_verify=fingerprint` - フィンガープリント検証
- `ice_support=yes` - ICEサポート
- `rtcp_mux=yes` - RTCP多重化

### 2. 複数デバイス同時接続
- `max_contacts=5` - 最大5台まで同時登録可能
- `remove_existing=no` - 既存登録を削除しない
- 全デバイスで同時着信、最初に応答したデバイスが通話

### 3. エンドポイント識別
- グローバル設定で識別順序を指定
- AOR名はシンプルに（エンドポイント名と同じ）
- `realm=asterisk`を明示的に指定

## 認証情報

| エンドポイント | ユーザー名 | パスワード |
|------------|---------|----------|
| 1000 | 1000 | webrtc_pass_1000 |
| 1001 | 1001 | webrtc_pass_1001 |
| 1002 | 1002 | webrtc_pass_1002 |

## クライアント設定（JsSIP）

```javascript
const ua = new JsSIP.UA({
  sockets: [new JsSIP.WebSocketInterface('wss://phone.sakana.hair:8089/ws')],
  uri: 'sip:1001@phone.sakana.hair',
  password: 'webrtc_pass_1001',
  register: true,
  session_timers: false
});
```

## 動作確認コマンド

```bash
# エンドポイント確認
asterisk -rx "pjsip show endpoints"

# 登録状態確認
asterisk -rx "pjsip show contacts"

# AOR確認
asterisk -rx "pjsip show aors"

# 認証情報確認
asterisk -rx "pjsip show auths"

# ダイヤルプラン確認
asterisk -rx "dialplan show from-internal"

# デバッグログ有効化
asterisk -rx "core set verbose 5"
asterisk -rx "pjsip set logger on"
```

## トラブルシューティング

### 404 Not Found
- AOR名がシンプルか確認（1000-aor ではなく 1000）
- グローバル設定があるか確認
- エンドポイントが正しく作成されているか確認

### 488 Not Acceptable Here
- WebRTC設定が有効か確認（webrtc=yes）
- コーデックが正しく設定されているか確認
- DTLS/ICE設定を確認

### 登録できない
- パスワードが正しいか確認
- WebSocketが8089ポートで動作しているか確認
- SSL証明書が正しく設定されているか確認

## まとめ
Asterisk WebRTCの設定で重要なのは：
1. エンドポイント、AOR、認証の3つの要素を正しく関連付ける
2. AOR名はシンプルに保つ（エンドポイント名と同じが推奨）
3. WebRTC固有の設定を漏れなく行う
4. グローバル設定で識別順序を明示する

これらの設定により、WebRTCクライアントからの接続と内線間通話が正常に動作します。