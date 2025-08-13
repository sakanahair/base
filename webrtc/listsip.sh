#!/bin/bash

#==============================================================================
# SIP Account List and Status Display Script
# Version: 1.0.0
# Date: 2025-08-12
# Description: Display WebRTC-enabled SIP accounts and their status
#==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
ASTERISK_CONFIG_DIR="/etc/asterisk"
PJSIP_CONF="$ASTERISK_CONFIG_DIR/pjsip.conf"

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

print_header() {
    echo -e "${BOLD}$1${NC}"
}

print_cyan() {
    echo -e "${CYAN}$1${NC}"
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

# Get all SIP accounts from pjsip.conf
get_all_accounts() {
    # Extract all numeric endpoint sections
    grep -E "^\[[0-9]+\]$" "$PJSIP_CONF" | sed 's/\[//g;s/\]//g' | sort -n
}

# Get account password
get_account_password() {
    local account="$1"
    grep -A 5 "^\[$account-auth\]" "$PJSIP_CONF" | grep "password=" | cut -d'=' -f2
}

# Get account status from Asterisk
get_account_status() {
    local account="$1"
    local endpoint_info=$(asterisk -rx "pjsip show endpoint $account" 2>/dev/null)
    
    if [[ -z "$endpoint_info" ]]; then
        echo "Not Found"
        return
    fi
    
    # Check contact status
    local contact_info=$(asterisk -rx "pjsip show contacts $account" 2>/dev/null)
    
    if echo "$contact_info" | grep -q "Contact:.*Avail"; then
        echo "Online"
    elif echo "$contact_info" | grep -q "Contact:.*Unknown"; then
        echo "Unknown"
    elif echo "$contact_info" | grep -q "Contact:.*Unavail"; then
        echo "Offline"
    else
        echo "Unregistered"
    fi
}

# Get contact count
get_contact_count() {
    local account="$1"
    local contact_info=$(asterisk -rx "pjsip show contacts $account" 2>/dev/null)
    echo "$contact_info" | grep -c "Contact:" || echo "0"
}

# Get max contacts setting
get_max_contacts() {
    local account="$1"
    grep -A 10 "^\[$account\]" "$PJSIP_CONF" | grep -E "type=aor" -A 10 | grep "max_contacts=" | cut -d'=' -f2 | head -1
}

# Display account groups
display_account_groups() {
    local accounts=("$@")
    local current_group=""
    
    # Group accounts by thousands
    declare -A groups
    for account in "${accounts[@]}"; do
        local group=$((account / 1000))
        groups[$group]+="$account "
    done
    
    # Display each group
    for group in $(printf '%s\n' "${!groups[@]}" | sort -n); do
        local group_accounts=(${groups[$group]})
        local start_range=$((group * 1000))
        local end_range=$(((group + 1) * 1000 - 1))
        
        echo ""
        print_header "📞 ${start_range}xx シリーズ (${#group_accounts[@]} アカウント)"
        echo "=================================="
        
        # Table header
        printf "%-8s %-12s %-8s %-15s %s\n" "番号" "状態" "接続数" "パスワード" "最後の登録"
        echo "------------------------------------------------------------------------"
        
        # Display each account in the group
        for account in $(printf '%s\n' "${group_accounts[@]}" | sort -n); do
            local status=$(get_account_status "$account")
            local contact_count=$(get_contact_count "$account")
            local max_contacts=$(get_max_contacts "$account")
            local password=$(get_account_password "$account")
            
            # Color status
            local colored_status=""
            case "$status" in
                "Online")
                    colored_status="${GREEN}オンライン${NC}"
                    ;;
                "Offline")
                    colored_status="${YELLOW}オフライン${NC}"
                    ;;
                "Unregistered")
                    colored_status="${RED}未登録${NC}"
                    ;;
                "Unknown")
                    colored_status="${CYAN}不明${NC}"
                    ;;
                "Not Found")
                    colored_status="${RED}見つからない${NC}"
                    ;;
                *)
                    colored_status="$status"
                    ;;
            esac
            
            # Format contact count
            local contact_display="$contact_count"
            if [[ -n "$max_contacts" && "$max_contacts" != "0" ]]; then
                contact_display="$contact_count/$max_contacts"
            fi
            
            # Get last registration time (simplified)
            local last_reg="N/A"
            
            printf "%-8s %-20s %-8s %-15s %s\n" "$account" "$colored_status" "$contact_display" "$password" "$last_reg"
        done
    done
}

# Display summary statistics
display_summary() {
    local accounts=("$@")
    local total=${#accounts[@]}
    local online=0
    local offline=0
    local unregistered=0
    local total_contacts=0
    
    print_info "統計情報を計算中..."
    
    for account in "${accounts[@]}"; do
        local status=$(get_account_status "$account")
        local contacts=$(get_contact_count "$account")
        
        case "$status" in
            "Online")
                ((online++))
                ;;
            "Offline")
                ((offline++))
                ;;
            "Unregistered"|"Not Found")
                ((unregistered++))
                ;;
        esac
        
        total_contacts=$((total_contacts + contacts))
    done
    
    echo ""
    print_header "📊 統計サマリー"
    echo "===================="
    echo "総アカウント数: $total"
    echo "  ${GREEN}オンライン: $online${NC}"
    echo "  ${YELLOW}オフライン: $offline${NC}"  
    echo "  ${RED}未登録: $unregistered${NC}"
    echo "総接続数: $total_contacts"
    echo ""
}

# Display help
show_help() {
    echo ""
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -h, --help      このヘルプを表示"
    echo "  -s, --summary   統計サマリーのみ表示"
    echo "  -g, --group     グループ別表示（デフォルト）"
    echo "  -a, --all       全アカウント一覧表示"
    echo "  -r, --range     指定範囲のアカウント表示"
    echo "      --online    オンラインアカウントのみ表示"
    echo "      --offline   オフラインアカウントのみ表示"
    echo ""
    echo "例:"
    echo "  $0                    全アカウントをグループ別に表示"
    echo "  $0 -s                 統計サマリーのみ表示"
    echo "  $0 --online           オンラインアカウントのみ表示"
    echo "  $0 -r 3000 3100      3000-3100の範囲のアカウントを表示"
    echo ""
}

# Filter accounts by status
filter_by_status() {
    local filter="$1"
    shift
    local accounts=("$@")
    local filtered=()
    
    for account in "${accounts[@]}"; do
        local status=$(get_account_status "$account")
        case "$filter" in
            "online")
                if [[ "$status" == "Online" ]]; then
                    filtered+=("$account")
                fi
                ;;
            "offline")
                if [[ "$status" == "Offline" ]]; then
                    filtered+=("$account")
                fi
                ;;
        esac
    done
    
    echo "${filtered[@]}"
}

# Filter accounts by range
filter_by_range() {
    local start="$1"
    local end="$2"
    shift 2
    local accounts=("$@")
    local filtered=()
    
    for account in "${accounts[@]}"; do
        if [[ $account -ge $start && $account -le $end ]]; then
            filtered+=("$account")
        fi
    done
    
    echo "${filtered[@]}"
}

#==============================================================================
# Main Process
#==============================================================================

main() {
    local show_summary_only=false
    local show_group=true
    local show_all=false
    local filter_status=""
    local range_start=""
    local range_end=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--summary)
                show_summary_only=true
                shift
                ;;
            -g|--group)
                show_group=true
                shift
                ;;
            -a|--all)
                show_all=true
                show_group=false
                shift
                ;;
            --online)
                filter_status="online"
                shift
                ;;
            --offline)
                filter_status="offline"
                shift
                ;;
            -r|--range)
                if [[ $# -lt 3 ]]; then
                    print_error "範囲指定には開始番号と終了番号が必要です"
                    exit 1
                fi
                range_start="$2"
                range_end="$3"
                shift 3
                ;;
            *)
                print_error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    clear
    echo "=============================="
    echo "  SIP アカウント一覧"
    echo "=============================="
    echo ""
    
    check_requirements
    
    # Get all accounts
    local all_accounts=($(get_all_accounts))
    
    if [[ ${#all_accounts[@]} -eq 0 ]]; then
        print_warning "SIPアカウントが見つかりませんでした"
        exit 0
    fi
    
    # Apply filters
    local filtered_accounts=("${all_accounts[@]}")
    
    if [[ -n "$filter_status" ]]; then
        filtered_accounts=($(filter_by_status "$filter_status" "${filtered_accounts[@]}"))
        if [[ ${#filtered_accounts[@]} -eq 0 ]]; then
            print_warning "$filter_status アカウントは見つかりませんでした"
            exit 0
        fi
    fi
    
    if [[ -n "$range_start" && -n "$range_end" ]]; then
        filtered_accounts=($(filter_by_range "$range_start" "$range_end" "${filtered_accounts[@]}"))
        if [[ ${#filtered_accounts[@]} -eq 0 ]]; then
            print_warning "範囲 $range_start-$range_end にアカウントは見つかりませんでした"
            exit 0
        fi
    fi
    
    # Display results
    if [[ "$show_summary_only" == true ]]; then
        display_summary "${filtered_accounts[@]}"
    else
        if [[ "$show_group" == true ]]; then
            display_account_groups "${filtered_accounts[@]}"
        else
            # Simple list view
            print_header "📋 アカウント一覧"
            echo "=================="
            for account in $(printf '%s\n' "${filtered_accounts[@]}" | sort -n); do
                local status=$(get_account_status "$account")
                local contact_count=$(get_contact_count "$account")
                local password=$(get_account_password "$account")
                
                case "$status" in
                    "Online")
                        echo -e "$account: ${GREEN}オンライン${NC} (接続: $contact_count) - $password"
                        ;;
                    "Offline")
                        echo -e "$account: ${YELLOW}オフライン${NC} (接続: $contact_count) - $password"
                        ;;
                    *)
                        echo -e "$account: ${RED}$status${NC} (接続: $contact_count) - $password"
                        ;;
                esac
            done
        fi
        
        display_summary "${filtered_accounts[@]}"
    fi
    
    echo ""
    print_info "関連コマンド:"
    print_cyan "  ./createsip.sh      新しいアカウントを作成"
    print_cyan "  ./deletesip.sh      アカウントを削除"
    print_cyan "  asterisk -rx \"pjsip show endpoints\"  詳細情報"
    echo ""
}

# Run main function
main "$@"