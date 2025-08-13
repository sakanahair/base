#!/bin/bash

#==============================================================================
# SIP Account Bulk Deleter Script
# Version: 1.0.0
# Date: 2025-08-12
# Description: Delete WebRTC-enabled SIP accounts in bulk
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

# Variables
START_NUMBER=""
END_NUMBER=""
COUNT=""

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

# List existing accounts in range
list_accounts_in_range() {
    local accounts=()
    for ((i=START_NUMBER; i<=END_NUMBER; i++)); do
        if grep -q "^\[$i\]" "$PJSIP_CONF"; then
            accounts+=("$i")
        fi
    done
    echo "${accounts[@]}"
}

# Get user input
get_user_input() {
    echo ""
    echo "====================================="
    echo "  SIP アカウント一括削除"
    echo "====================================="
    echo ""
    
    # Choose deletion method
    echo "削除方法を選択してください:"
    echo "1) 範囲指定 (開始番号と終了番号)"
    echo "2) 数量指定 (開始番号と削除数)"
    echo "3) 個別指定 (カンマ区切りで番号)"
    echo ""
    
    local method=""
    while [[ ! "$method" =~ ^[123]$ ]]; do
        read -p "選択してください (1-3): " method
        if [[ ! "$method" =~ ^[123]$ ]]; then
            print_warning "1, 2, 3のいずれかを入力してください"
        fi
    done
    
    case $method in
        1)
            get_range_input
            ;;
        2)
            get_count_input
            ;;
        3)
            get_individual_input
            ;;
    esac
}

# Get range input (method 1)
get_range_input() {
    # Get start number
    while [[ -z "$START_NUMBER" ]] || [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; do
        read -p "開始番号を入力してください: " START_NUMBER
        if [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; then
            print_warning "数値を入力してください"
            START_NUMBER=""
        fi
    done
    
    # Get end number
    while [[ -z "$END_NUMBER" ]] || [[ ! "$END_NUMBER" =~ ^[0-9]+$ ]] || [[ "$END_NUMBER" -lt "$START_NUMBER" ]]; do
        read -p "終了番号を入力してください ($START_NUMBER 以上): " END_NUMBER
        if [[ ! "$END_NUMBER" =~ ^[0-9]+$ ]]; then
            print_warning "数値を入力してください"
            END_NUMBER=""
        elif [[ "$END_NUMBER" -lt "$START_NUMBER" ]]; then
            print_warning "終了番号は開始番号以上である必要があります"
            END_NUMBER=""
        fi
    done
}

# Get count input (method 2)
get_count_input() {
    # Get start number
    while [[ -z "$START_NUMBER" ]] || [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; do
        read -p "開始番号を入力してください: " START_NUMBER
        if [[ ! "$START_NUMBER" =~ ^[0-9]+$ ]]; then
            print_warning "数値を入力してください"
            START_NUMBER=""
        fi
    done
    
    # Get count
    while [[ -z "$COUNT" ]] || [[ ! "$COUNT" =~ ^[1-9][0-9]*$ ]]; do
        read -p "削除するアカウント数を入力してください: " COUNT
        if [[ ! "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
            print_warning "1以上の数値を入力してください"
            COUNT=""
        fi
    done
    
    END_NUMBER=$((START_NUMBER + COUNT - 1))
}

# Get individual input (method 3)
get_individual_input() {
    local input=""
    while [[ -z "$input" ]]; do
        read -p "削除する番号をカンマ区切りで入力してください (例: 3000,3001,3002): " input
        if [[ -z "$input" ]]; then
            print_warning "番号を入力してください"
        fi
    done
    
    # Parse individual numbers
    IFS=',' read -ra NUMBERS <<< "$input"
    local min_num=${NUMBERS[0]}
    local max_num=${NUMBERS[0]}
    
    for num in "${NUMBERS[@]}"; do
        num=$(echo "$num" | tr -d ' ')  # Remove spaces
        if [[ ! "$num" =~ ^[0-9]+$ ]]; then
            print_error "無効な番号です: $num"
            exit 1
        fi
        if [[ $num -lt $min_num ]]; then
            min_num=$num
        fi
        if [[ $num -gt $max_num ]]; then
            max_num=$num
        fi
    done
    
    START_NUMBER=$min_num
    END_NUMBER=$max_num
    INDIVIDUAL_NUMBERS=("${NUMBERS[@]}")
}

# Confirm deletion
confirm_deletion() {
    # Show accounts to be deleted
    print_info "削除対象のアカウントを確認中..."
    
    if [[ ${#INDIVIDUAL_NUMBERS[@]} -gt 0 ]]; then
        # Individual deletion
        local existing_accounts=()
        for num in "${INDIVIDUAL_NUMBERS[@]}"; do
            num=$(echo "$num" | tr -d ' ')  # Remove spaces
            if grep -q "^\[$num\]" "$PJSIP_CONF"; then
                existing_accounts+=("$num")
            fi
        done
        
        if [[ ${#existing_accounts[@]} -eq 0 ]]; then
            print_warning "指定された番号のアカウントは存在しません"
            exit 0
        fi
        
        echo ""
        echo "削除されるアカウント:"
        printf '%s ' "${existing_accounts[@]}"
        echo ""
        echo "削除数: ${#existing_accounts[@]} 個"
        
    else
        # Range deletion
        local existing_accounts=($(list_accounts_in_range))
        
        if [[ ${#existing_accounts[@]} -eq 0 ]]; then
            print_warning "範囲 $START_NUMBER-$END_NUMBER にアカウントは存在しません"
            exit 0
        fi
        
        echo ""
        echo "削除範囲: $START_NUMBER - $END_NUMBER"
        echo "削除されるアカウント:"
        printf '%s ' "${existing_accounts[@]}"
        echo ""
        echo "削除数: ${#existing_accounts[@]} 個"
    fi
    
    echo ""
    print_warning "この操作は元に戻せません！"
    read -p "本当に削除しますか？ (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "削除処理を中止しました"
        exit 0
    fi
}

# Delete accounts from config
delete_accounts() {
    print_info "アカウントを削除中..."
    
    local temp_pjsip="/tmp/pjsip_temp.conf"
    cp "$PJSIP_CONF" "$temp_pjsip"
    
    # Create array of numbers to delete
    local delete_numbers=()
    if [[ ${#INDIVIDUAL_NUMBERS[@]} -gt 0 ]]; then
        for num in "${INDIVIDUAL_NUMBERS[@]}"; do
            delete_numbers+=("$(echo "$num" | tr -d ' ')")
        done
    else
        for ((i=START_NUMBER; i<=END_NUMBER; i++)); do
            delete_numbers+=("$i")
        done
    fi
    
    local deleted_count=0
    
    # Delete accounts using Python for better performance
    local accounts_list=$(IFS=','; echo "${delete_numbers[*]}")
    
    deleted_count=$(python3 << EOF
import re

# Read the config file
with open("$temp_pjsip", "r") as f:
    content = f.read()

# Parse accounts to delete
accounts = "$accounts_list".split(",")
accounts = [acc.strip() for acc in accounts]

deleted_count = 0
for account in accounts:
    original_content = content
    
    # Remove endpoint section [account]
    pattern = rf'\n\[{account}\]\n.*?(?=\n\[[^\]]+\]|\n*\Z)'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    # Remove auth section [account-auth]
    pattern = rf'\n\[{account}-auth\]\n.*?(?=\n\[[^\]]+\]|\n*\Z)'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    # Remove aor section [account-aor]
    pattern = rf'\n\[{account}-aor\]\n.*?(?=\n\[[^\]]+\]|\n*\Z)'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    if content != original_content:
        deleted_count += 1

# Write back to file
with open("$temp_pjsip", "w") as f:
    f.write(content)

print(deleted_count)
EOF
)
    echo ""
    
    # Replace original file
    if [[ -f "$temp_pjsip" ]]; then
        mv "$temp_pjsip" "$PJSIP_CONF"
        print_success "$deleted_count 個のアカウントを削除しました"
    else
        print_error "一時ファイルの作成に失敗しました"
        exit 1
    fi
}

# Reload Asterisk configuration
reload_asterisk() {
    print_info "Asterisk設定をリロード中..."
    
    if asterisk -rx "pjsip reload" >/dev/null 2>&1; then
        print_success "PJSIP設定リロード完了"
        sleep 2
        
        # Verify accounts were deleted
        local remaining_count=0
        if [[ ${#INDIVIDUAL_NUMBERS[@]} -gt 0 ]]; then
            for num in "${INDIVIDUAL_NUMBERS[@]}"; do
                num=$(echo "$num" | tr -d ' ')
                if asterisk -rx "pjsip show endpoints" | grep -q "^\s*Endpoint:\s*$num"; then
                    ((remaining_count++))
                fi
            done
        else
            remaining_count=$(asterisk -rx "pjsip show endpoints" | grep -E "^\s*Endpoint:\s*($START_NUMBER|$(seq -s '|' $((START_NUMBER+1)) $END_NUMBER))" | wc -l)
        fi
        
        if [[ $remaining_count -eq 0 ]]; then
            print_success "全てのアカウントが正常に削除されました"
        else
            print_warning "まだ $remaining_count 個のアカウントが残っています"
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
    echo "  削除完了"
    echo "=============================="
    echo ""
    if [[ ${#INDIVIDUAL_NUMBERS[@]} -gt 0 ]]; then
        echo "削除されたアカウント:"
        printf '%s ' "${INDIVIDUAL_NUMBERS[@]}"
        echo ""
        echo "削除数: ${#INDIVIDUAL_NUMBERS[@]} 個"
    else
        echo "削除範囲: $START_NUMBER - $END_NUMBER"
        echo "削除数: $((END_NUMBER - START_NUMBER + 1)) 個"
    fi
    echo ""
    echo "確認コマンド:"
    echo "  asterisk -rx \"pjsip show endpoints\""
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
    echo "  SIP アカウント一括削除"
    echo "=============================="
    echo ""
    
    check_root
    check_requirements
    get_user_input
    confirm_deletion
    create_backup
    delete_accounts
    reload_asterisk
    show_summary
    
    print_success "削除処理が完了しました！"
}

# Run main function
main "$@"