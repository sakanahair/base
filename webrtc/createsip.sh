#!/bin/bash

#==============================================================================
# SIP Account Bulk Creator Script
# Version: 1.0.0
# Date: 2025-08-12
# Description: Create WebRTC-enabled SIP accounts in bulk
#==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ASTERISK_CONFIG_DIR="/etc/asterisk"
PJSIP_CONF="$ASTERISK_CONFIG_DIR/pjsip.conf"
BACKUP_DIR="/etc/asterisk/backups"
TEMP_FILE="/tmp/new_sip_accounts.conf"

# Variables
START_NUMBER=""
COUNT=""
PASSWORD=""
END_NUMBER=""

#==============================================================================
# Functions
#==============================================================================

# Print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "このスクリプトはroot権限で実行してください"
        exit 1
    fi
}

# Check requirements
check_requirements() {
    if [[ ! -f "$PJSIP_CONF" ]]; then
        print_error "pjsip.confが見つかりません: $PJSIP_CONF"
        exit 1
    fi
    
    if ! command -v asterisk &> /dev/null; then
        print_error "Asteriskが見つかりません"
        exit 1
    fi
}

# Create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/pjsip.conf.backup.$timestamp"
    
    mkdir -p "$BACKUP_DIR"
    cp "$PJSIP_CONF" "$backup_file"
    print_success "バックアップ作成: $backup_file"
}

# Get user input
get_user_input() {
    echo ""
    echo "====================================="
    echo "  SIP アカウント一括作成"
    echo "====================================="
    echo ""
    
    # Get count
    while [[ -z "$COUNT" ]] || [[ ! "$COUNT" =~ ^[1-9][0-9]*$ ]]; do
        read -p "作成するアカウント数を入力してください (1-1000): " COUNT
        if [[ ! "$COUNT" =~ ^[1-9][0-9]*$ ]] || [[ "$COUNT" -gt 1000 ]]; then
            print_warning "1から1000までの数値を入力してください"
            COUNT=""
        fi
    done
    
    # Get start number
    while [[ -z "$START_NUMBER" ]] || [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; do
        read -p "開始番号を入力してください (例: 3000): " START_NUMBER
        if [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; then
            print_warning "数値を入力してください"
            START_NUMBER=""
        elif [[ "$START_NUMBER" -lt 1000 ]]; then
            print_warning "1000以上の番号を入力してください"
            START_NUMBER=""
        fi
    done
    
    # Calculate end number
    END_NUMBER=$((START_NUMBER + COUNT - 1))
    
    # Get password
    while [[ -z "$PASSWORD" ]]; do
        read -sp "パスワードを入力してください（全アカウント共通）: " PASSWORD
        echo ""
        if [[ ${#PASSWORD} -lt 4 ]]; then
            print_warning "パスワードは4文字以上で入力してください"
            PASSWORD=""
        fi
    done
    
    # Check for conflicts
    print_info "既存アカウントとの重複をチェック中..."
    local conflicts=()
    for ((i=START_NUMBER; i<=END_NUMBER; i++)); do
        if grep -q "^\[$i\]" "$PJSIP_CONF"; then
            conflicts+=("$i")
        fi
        if grep -q "^\[9$i\]" "$PJSIP_CONF"; then
            conflicts+=("9$i")
        fi
    done
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        print_warning "以下の番号は既に存在します:"
        printf '%s ' "${conflicts[@]}"
        echo ""
        read -p "続行しますか？既存のアカウントは上書きされます (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "処理を中止しました"
            exit 0
        fi
    fi
    
    # Confirm
    echo ""
    echo "設定確認:"
    echo "============="
    echo "作成数: $COUNT 個"
    echo "範囲: $START_NUMBER - $END_NUMBER"
    echo "パスワード: $PASSWORD"
    echo ""
    read -p "これらの設定でアカウントを作成しますか？ (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "処理を中止しました"
        exit 0
    fi
}

# Generate SIP accounts
generate_accounts() {
    print_info "SIPアカウント設定を生成中..."
    
    cat > "$TEMP_FILE" <<EOF

;==============================================================================
; Bulk Created SIP Accounts ($START_NUMBER-$END_NUMBER)
; Created: $(date)
; Password: $PASSWORD
; Total: $COUNT accounts
;==============================================================================
EOF
    
    for ((i=START_NUMBER; i<=END_NUMBER; i++)); do
        cat >> "$TEMP_FILE" <<EOF

; Extension $i
[$i]
type=endpoint
transport=transport-wss
context=from-internal
disallow=all
allow=g722,ulaw,alaw,opus
use_avpf=yes
media_encryption=dtls
dtls_verify=fingerprint
dtls_setup=actpass
dtls_auto_generate_cert=yes
ice_support=yes
media_use_received_transport=no
rtcp_mux=yes
webrtc=yes
rtp_timeout=30
rtp_timeout_hold=0
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes
direct_media=no
dtmf_mode=rfc4733
trust_id_inbound=yes
send_rpid=yes
send_pai=yes
rtp_timeout=60
language=en
timers=yes
timers_sess_expires=1800
auth=$i-auth
aors=$i
callerid="WebRTC User $i" <$i>

[$i]
type=aor
max_contacts=5
remove_existing=yes
default_expiration=3600
maximum_expiration=7200
minimum_expiration=60

[$i-auth]
type=auth
auth_type=userpass
username=$i
password=$PASSWORD
realm=phone.sakana.hair

; ===== SIP/Zoiper Account 9$i =====
[9$i]
type=endpoint
transport=transport-udp
context=from-internal
disallow=all
allow=g722,ulaw,alaw,opus
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes
direct_media=no
dtmf_mode=rfc4733
trust_id_inbound=yes
send_rpid=yes
send_pai=yes
rtp_timeout=60
language=en
auth=9$i-auth
aors=9$i
callerid="SIP User 9$i" <9$i>

[9$i]
type=aor
max_contacts=5
remove_existing=yes
default_expiration=3600
maximum_expiration=7200
minimum_expiration=60

[9$i-auth]
type=auth
auth_type=userpass
username=9$i
password=$PASSWORD
realm=phone.sakana.hair
EOF
        
        # Progress indicator
        if [[ $((i % 10)) -eq 0 ]]; then
            echo -n "."
        fi
    done
    echo ""
    
    print_success "設定ファイル生成完了: $TEMP_FILE"
}

# Remove existing accounts from config
remove_existing_accounts() {
    print_info "既存のアカウントを削除中..."
    
    local temp_pjsip="/tmp/pjsip_temp.conf"
    local in_account=false
    local current_account=""
    
    while IFS= read -r line; do
        # Check if line starts an account section
        if [[ $line =~ ^\[([0-9]+)\]$ ]]; then
            local account_num="${BASH_REMATCH[1]}"
            # Check both original number and 9-prefixed number
            if [[ $account_num -ge $START_NUMBER && $account_num -le $END_NUMBER ]]; then
                in_account=true
                current_account="$account_num"
                continue
            elif [[ $account_num =~ ^9([0-9]+)$ ]]; then
                local base_num="${BASH_REMATCH[1]}"
                if [[ $base_num -ge $START_NUMBER && $base_num -le $END_NUMBER ]]; then
                    in_account=true
                    current_account="$account_num"
                    continue
                fi
            else
                in_account=false
            fi
        elif [[ $line =~ ^\[([0-9]+)-auth\]$ ]]; then
            local account_num="${BASH_REMATCH[1]}"
            # Check both original number and 9-prefixed number
            if [[ $account_num -ge $START_NUMBER && $account_num -le $END_NUMBER ]]; then
                in_account=true
                current_account="$account_num"
                continue
            elif [[ $account_num =~ ^9([0-9]+)$ ]]; then
                local base_num="${BASH_REMATCH[1]}"
                if [[ $base_num -ge $START_NUMBER && $base_num -le $END_NUMBER ]]; then
                    in_account=true
                    current_account="$account_num"
                    continue
                fi
            else
                in_account=false
            fi
        elif [[ $line =~ ^\[.*\]$ ]]; then
            in_account=false
        fi
        
        # Skip lines that are part of accounts we're replacing
        if [[ $in_account == false ]]; then
            echo "$line" >> "$temp_pjsip"
        fi
    done < "$PJSIP_CONF"
    
    mv "$temp_pjsip" "$PJSIP_CONF"
}

# Add new accounts to pjsip.conf
add_accounts_to_config() {
    print_info "新しいアカウントを設定ファイルに追加中..."
    
    # Remove any existing accounts in the range first
    remove_existing_accounts
    
    # Append new accounts
    cat "$TEMP_FILE" >> "$PJSIP_CONF"
    rm "$TEMP_FILE"
    
    print_success "設定ファイルに追加完了"
}

# Reload Asterisk configuration
reload_asterisk() {
    print_info "Asterisk設定をリロード中..."
    
    if asterisk -rx "pjsip reload" >/dev/null 2>&1; then
        print_success "PJSIP設定リロード完了"
        sleep 2
        
        # Verify accounts were created
        local created_count=$(asterisk -rx "pjsip show endpoints" | grep -E "^\s*Endpoint:\s*($START_NUMBER|$(seq -s '|' $((START_NUMBER+1)) $END_NUMBER))" | wc -l)
        
        if [[ $created_count -eq $COUNT ]]; then
            print_success "全 $COUNT 個のアカウントが正常に作成されました"
        else
            print_warning "作成されたアカウント数が予期と異なります: $created_count/$COUNT"
        fi
    else
        print_error "Asterisk設定のリロードに失敗しました"
        exit 1
    fi
}

# Display summary
show_summary() {
    echo ""
    echo "=============================="
    echo "  作成完了"
    echo "=============================="
    echo ""
    echo "作成されたアカウント:"
    echo "  WebRTC用: $START_NUMBER - $END_NUMBER"
    echo "  SIP/Zoiper用: 9$START_NUMBER - 9$END_NUMBER"
    echo "  数量: $COUNT 個 × 2種類 = $((COUNT * 2)) 個"
    echo "  パスワード: $PASSWORD"
    echo ""
    echo "WebRTC設定 ($START_NUMBER-$END_NUMBER):"
    echo "  ✓ トランスポート: WSS (ポート8089)"
    echo "  ✓ WebRTC対応: 有効"
    echo "  ✓ コーデック: opus,ulaw,alaw,g722"
    echo ""
    echo "SIP/Zoiper設定 (9$START_NUMBER-9$END_NUMBER):"
    echo "  ✓ トランスポート: UDP (ポート5060)"
    echo "  ✓ 通常SIP: 有効"
    echo "  ✓ コーデック: ulaw,alaw,g722,opus"
    echo ""
    echo "確認コマンド:"
    echo "  asterisk -rx \"pjsip show endpoints\" | grep -E \"^[[:space:]]*Endpoint:[[:space:]]*(9?$START_NUMBER|9?$END_NUMBER)\""
    echo ""
    echo "アカウント一覧表示:"
    echo "  ./listsip.sh"
    echo ""
}

#==============================================================================
# Main Process
#==============================================================================

main() {
    clear
    echo "=============================="
    echo "  SIP アカウント一括作成"
    echo "=============================="
    echo ""
    
    check_root
    check_requirements
    get_user_input
    create_backup
    generate_accounts
    add_accounts_to_config
    reload_asterisk
    show_summary
    
    print_success "処理が完了しました！"
}

# Run main function
main "$@"