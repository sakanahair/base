#!/bin/bash

#==============================================================================
# Asterisk WebRTC Setup Installer
# Version: 1.0.0
# Date: 2025-08-12
# Description: Automated installer for Asterisk WebRTC configuration
# Author: System Administrator
#==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
ASTERISK_CONFIG_DIR="/etc/asterisk"
BACKUP_DIR="/etc/asterisk/backup_$(date +%Y%m%d_%H%M%S)"
SSL_DIR="/etc/asterisk/keys"
DOMAIN=""
ADMIN_EMAIL=""
ENDPOINTS=()
PASSWORDS=()

# Log file
LOG_FILE="/var/log/asterisk-webrtc-install.log"

#==============================================================================
# Functions
#==============================================================================

# Logger function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log "INFO: $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/debian_version ]]; then
        print_error "This script requires Debian/Ubuntu"
        exit 1
    fi
    
    # Check if Asterisk is installed
    if ! command -v asterisk &> /dev/null; then
        print_error "Asterisk is not installed"
        echo "Please install Asterisk first using: apt-get install asterisk"
        exit 1
    fi
    
    # Check Asterisk version
    ASTERISK_VERSION=$(asterisk -V | grep -oP '\d+\.\d+' | head -1)
    print_info "Asterisk version: $ASTERISK_VERSION"
    
    # Check for required tools
    local tools=("openssl" "sed" "grep" "awk")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "$tool is not installed"
            exit 1
        fi
    done
    
    print_success "All requirements met"
}

# Backup existing configuration
backup_config() {
    print_info "Creating backup of existing configuration..."
    
    if [[ -d "$ASTERISK_CONFIG_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$ASTERISK_CONFIG_DIR"/*.conf "$BACKUP_DIR/" 2>/dev/null || true
        
        if [[ -d "$SSL_DIR" ]]; then
            cp -r "$SSL_DIR" "$BACKUP_DIR/" 2>/dev/null || true
        fi
        
        print_success "Backup created at: $BACKUP_DIR"
    else
        print_warning "No existing configuration found to backup"
    fi
}

# Restore configuration from backup
restore_config() {
    print_warning "Restoring configuration from backup..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        cp -r "$BACKUP_DIR"/*.conf "$ASTERISK_CONFIG_DIR/" 2>/dev/null || true
        
        if [[ -d "$BACKUP_DIR/keys" ]]; then
            cp -r "$BACKUP_DIR/keys" "$ASTERISK_CONFIG_DIR/" 2>/dev/null || true
        fi
        
        systemctl reload asterisk
        print_success "Configuration restored from: $BACKUP_DIR"
    else
        print_error "No backup found at: $BACKUP_DIR"
        exit 1
    fi
}

# Get user input
get_user_input() {
    echo ""
    echo "==================================="
    echo "  Asterisk WebRTC Configuration"
    echo "==================================="
    echo ""
    
    # Get domain
    read -p "Enter your domain (e.g., phone.example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain is required"
        exit 1
    fi
    
    # Get admin email for Let's Encrypt
    read -p "Enter admin email for SSL certificate (optional): " ADMIN_EMAIL
    
    # Get number of endpoints
    read -p "How many WebRTC endpoints to create? (default: 3): " NUM_ENDPOINTS
    NUM_ENDPOINTS=${NUM_ENDPOINTS:-3}
    
    # Get endpoint details
    for i in $(seq 1 "$NUM_ENDPOINTS"); do
        local default_ext=$((999 + i))
        read -p "Enter extension for endpoint $i (default: $default_ext): " ext
        ext=${ext:-$default_ext}
        ENDPOINTS+=("$ext")
        
        read -sp "Enter password for extension $ext (default: webrtc_pass_$ext): " pass
        echo ""
        pass=${pass:-"webrtc_pass_$ext"}
        PASSWORDS+=("$pass")
    done
    
    # Confirm settings
    echo ""
    echo "Configuration Summary:"
    echo "====================="
    echo "Domain: $DOMAIN"
    echo "SSL Email: ${ADMIN_EMAIL:-Not provided}"
    echo "Endpoints: ${ENDPOINTS[*]}"
    echo ""
    read -p "Proceed with installation? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi
}

# Generate SSL certificates
setup_ssl() {
    print_info "Setting up SSL certificates..."
    
    mkdir -p "$SSL_DIR"
    cd "$SSL_DIR"
    
    # Check if certificates already exist
    if [[ -f "asterisk.crt" ]] && [[ -f "asterisk.key" ]]; then
        print_warning "SSL certificates already exist"
        read -p "Regenerate certificates? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Generate self-signed certificate
    print_info "Generating self-signed certificate..."
    openssl req -new -x509 -days 365 -nodes -out asterisk.crt -keyout asterisk.key \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" 2>/dev/null
    
    # Set permissions
    chmod 600 asterisk.key
    chmod 644 asterisk.crt
    chown asterisk:asterisk asterisk.key asterisk.crt
    
    print_success "SSL certificates generated"
}

# Configure HTTP/WebSocket
configure_http() {
    print_info "Configuring HTTP/WebSocket..."
    
    cat > "$ASTERISK_CONFIG_DIR/http.conf" <<EOF
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=$SSL_DIR/asterisk.crt
tlsprivatekey=$SSL_DIR/asterisk.key
EOF
    
    print_success "HTTP/WebSocket configured"
}

# Configure RTP
configure_rtp() {
    print_info "Configuring RTP..."
    
    cat > "$ASTERISK_CONFIG_DIR/rtp.conf" <<EOF
[general]
rtpstart=10000
rtpend=20000
icesupport=yes
stunaddr=stun.l.google.com:19302

[ice_host_candidates]
; Add your server's public IP here if behind NAT
; <local_ip> => <public_ip>
EOF
    
    print_success "RTP configured"
}

# Configure PJSIP
configure_pjsip() {
    print_info "Configuring PJSIP..."
    
    # Start PJSIP configuration
    cat > "$ASTERISK_CONFIG_DIR/pjsip.conf" <<'EOF'
;==============================================================================
; Asterisk WebRTC PJSIP Configuration
; Generated by install-asterisk-webrtc.sh
;==============================================================================

;==============================================================================
; Global Settings
;==============================================================================
[global]
type=global
endpoint_identifier_order=auth_username,username,ip,anonymous
debug=no

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
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
external_media_address=
external_signaling_address=

[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:8089
EOF
    
    # Add SSL certificate paths
    echo "cert_file=$SSL_DIR/asterisk.crt" >> "$ASTERISK_CONFIG_DIR/pjsip.conf"
    echo "priv_key_file=$SSL_DIR/asterisk.key" >> "$ASTERISK_CONFIG_DIR/pjsip.conf"
    
    cat >> "$ASTERISK_CONFIG_DIR/pjsip.conf" <<'EOF'
method=tlsv1_2
cipher=DEFAULT
verify_client=no
verify_server=no
allow_reload=yes

;==============================================================================
; WebRTC Template
;==============================================================================
[webrtc-template](!)
type=endpoint
transport=transport-wss
context=from-internal
disallow=all
allow=opus,ulaw,alaw,g722
use_avpf=yes
media_encryption=dtls
dtls_verify=fingerprint
dtls_setup=actpass
dtls_auto_generate_cert=yes
ice_support=yes
media_use_received_transport=yes
rtcp_mux=yes
webrtc=yes
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes
direct_media=no
dtmf_mode=rfc4733
trust_id_inbound=yes
send_rpid=yes
send_pai=yes
rtp_timeout=60
rtp_hold_timeout=600
language=en
timers=yes
timers_sess_expires=1800

;==============================================================================
; WebRTC Endpoints
;==============================================================================
EOF
    
    # Add endpoints
    for i in "${!ENDPOINTS[@]}"; do
        local ext="${ENDPOINTS[$i]}"
        local pass="${PASSWORDS[$i]}"
        
        cat >> "$ASTERISK_CONFIG_DIR/pjsip.conf" <<EOF

; Extension $ext
[$ext](webrtc-template)
type=endpoint
auth=$ext-auth
aors=$ext
callerid="WebRTC User $ext" <$ext>

[$ext]
type=aor
max_contacts=5
remove_existing=no
qualify_frequency=30
default_expiration=3600
maximum_expiration=7200
minimum_expiration=60

[$ext-auth]
type=auth
auth_type=userpass
username=$ext
password=$pass
realm=asterisk
EOF
    done
    
    print_success "PJSIP configured with ${#ENDPOINTS[@]} endpoints"
}

# Configure Dialplan
configure_dialplan() {
    print_info "Configuring Dialplan..."
    
    # Check if extensions.conf exists
    if [[ ! -f "$ASTERISK_CONFIG_DIR/extensions.conf" ]]; then
        # Create basic extensions.conf
        cat > "$ASTERISK_CONFIG_DIR/extensions.conf" <<'EOF'
[general]
static=yes
writeprotect=no
clearglobalvars=no

[globals]
EOF
    fi
    
    # Check if from-internal context exists
    if ! grep -q "\[from-internal\]" "$ASTERISK_CONFIG_DIR/extensions.conf"; then
        cat >> "$ASTERISK_CONFIG_DIR/extensions.conf" <<'EOF'

[from-internal]
; Internal extension dialing
exten => _X.,1,NoOp(Calling extension ${EXTEN})
 same => n,Set(DIALSTATUS=)
 same => n,Dial(PJSIP/${EXTEN},30)
 same => n,GotoIf($["${DIALSTATUS}" = "BUSY"]?busy)
 same => n,GotoIf($["${DIALSTATUS}" = "NOANSWER"]?noanswer)
 same => n,GotoIf($["${DIALSTATUS}" = "CHANUNAVAIL"]?unavailable)
 same => n,Hangup()
 same => n(busy),Busy()
 same => n(noanswer),Hangup()
 same => n(unavailable),Playback(ss-noservice)
 same => n,Hangup()

; Echo test
exten => 9999,1,Answer()
 same => n,Playback(demo-echotest)
 same => n,Echo()
 same => n,Hangup()

; Conference room
exten => 8888,1,Answer()
 same => n,ConfBridge(1)
 same => n,Hangup()

; Voicemail
exten => *98,1,VoiceMailMain()
 same => n,Hangup()
EOF
    fi
    
    print_success "Dialplan configured"
}

# Configure firewall
configure_firewall() {
    print_info "Configuring firewall rules..."
    
    # Check if ufw is installed
    if command -v ufw &> /dev/null; then
        print_info "Configuring UFW firewall..."
        
        # Add rules
        ufw allow 8088/tcp comment 'Asterisk HTTP' 2>/dev/null || true
        ufw allow 8089/tcp comment 'Asterisk WebSocket Secure' 2>/dev/null || true
        ufw allow 10000:20000/udp comment 'Asterisk RTP' 2>/dev/null || true
        ufw allow 5060/udp comment 'Asterisk SIP' 2>/dev/null || true
        
        print_success "UFW rules added"
    elif command -v iptables &> /dev/null; then
        print_info "Configuring iptables..."
        
        # Add rules
        iptables -A INPUT -p tcp --dport 8088 -j ACCEPT -m comment --comment "Asterisk HTTP" 2>/dev/null || true
        iptables -A INPUT -p tcp --dport 8089 -j ACCEPT -m comment --comment "Asterisk WSS" 2>/dev/null || true
        iptables -A INPUT -p udp --dport 10000:20000 -j ACCEPT -m comment --comment "Asterisk RTP" 2>/dev/null || true
        iptables -A INPUT -p udp --dport 5060 -j ACCEPT -m comment --comment "Asterisk SIP" 2>/dev/null || true
        
        # Save rules
        if command -v iptables-save &> /dev/null; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        
        print_success "iptables rules added"
    else
        print_warning "No firewall detected. Please manually open ports: 8088, 8089, 5060, 10000-20000"
    fi
}

# Test configuration
test_configuration() {
    print_info "Testing configuration..."
    
    # Reload Asterisk
    systemctl reload asterisk || asterisk -rx "core reload"
    
    sleep 2
    
    # Test PJSIP
    if asterisk -rx "pjsip show endpoints" | grep -q "${ENDPOINTS[0]}"; then
        print_success "PJSIP endpoints created successfully"
    else
        print_error "PJSIP endpoints not found"
        return 1
    fi
    
    # Test WebSocket
    if asterisk -rx "http show status" | grep -q "Enabled and Bound"; then
        print_success "WebSocket server is running"
    else
        print_error "WebSocket server is not running"
        return 1
    fi
    
    # Test dialplan
    if asterisk -rx "dialplan show from-internal" | grep -q "from-internal"; then
        print_success "Dialplan configured correctly"
    else
        print_error "Dialplan context not found"
        return 1
    fi
    
    return 0
}

# Generate client configuration
generate_client_config() {
    print_info "Generating client configuration..."
    
    local config_file="/var/www/html/webrtc-config.js"
    mkdir -p /var/www/html
    
    cat > "$config_file" <<EOF
// Asterisk WebRTC Client Configuration
// Generated by install-asterisk-webrtc.sh

const WEBRTC_CONFIG = {
    server: 'wss://$DOMAIN:8089/ws',
    domain: '$DOMAIN',
    endpoints: [
EOF
    
    for i in "${!ENDPOINTS[@]}"; do
        local ext="${ENDPOINTS[$i]}"
        local pass="${PASSWORDS[$i]}"
        cat >> "$config_file" <<EOF
        {
            extension: '$ext',
            password: '$pass',
            uri: 'sip:$ext@$DOMAIN'
        },
EOF
    done
    
    cat >> "$config_file" <<EOF
    ],
    stunServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
    ],
    options: {
        session_timers: false,
        register: true,
        register_expires: 600
    }
};

// Example JsSIP configuration
function createUA(extension, password) {
    return new JsSIP.UA({
        sockets: [new JsSIP.WebSocketInterface(WEBRTC_CONFIG.server)],
        uri: 'sip:' + extension + '@' + WEBRTC_CONFIG.domain,
        password: password,
        register: WEBRTC_CONFIG.options.register,
        register_expires: WEBRTC_CONFIG.options.register_expires,
        session_timers: WEBRTC_CONFIG.options.session_timers
    });
}
EOF
    
    print_success "Client configuration generated at: $config_file"
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================="
    echo "  Installation Complete!"
    echo "=============================================="
    echo ""
    echo "Domain: $DOMAIN"
    echo "WebSocket URL: wss://$DOMAIN:8089/ws"
    echo ""
    echo "Endpoints created:"
    for i in "${!ENDPOINTS[@]}"; do
        echo "  - Extension: ${ENDPOINTS[$i]}, Password: ${PASSWORDS[$i]}"
    done
    echo ""
    echo "Test numbers:"
    echo "  - 9999: Echo test"
    echo "  - 8888: Conference room"
    echo "  - *98: Voicemail"
    echo ""
    echo "Configuration files:"
    echo "  - $ASTERISK_CONFIG_DIR/pjsip.conf"
    echo "  - $ASTERISK_CONFIG_DIR/extensions.conf"
    echo "  - $ASTERISK_CONFIG_DIR/http.conf"
    echo "  - $ASTERISK_CONFIG_DIR/rtp.conf"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo "To test:"
    echo "  asterisk -rx 'pjsip show endpoints'"
    echo "  asterisk -rx 'pjsip show contacts'"
    echo ""
    echo "Client config: /var/www/html/webrtc-config.js"
    echo ""
    print_warning "Note: If using self-signed certificates, users must accept them in browser first:"
    echo "  https://$DOMAIN:8089/"
    echo ""
}

# Cleanup on error
cleanup_on_error() {
    print_error "Installation failed!"
    read -p "Restore from backup? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_config
    fi
    exit 1
}

# Trap errors
trap cleanup_on_error ERR

#==============================================================================
# Main Installation Process
#==============================================================================

main() {
    clear
    echo "=============================================="
    echo "  Asterisk WebRTC Installer v1.0.0"
    echo "=============================================="
    echo ""
    
    # Create log file
    touch "$LOG_FILE"
    
    # Check prerequisites
    check_root
    check_requirements
    
    # Get user input
    get_user_input
    
    # Backup existing configuration
    backup_config
    
    # Perform installation
    setup_ssl
    configure_http
    configure_rtp
    configure_pjsip
    configure_dialplan
    configure_firewall
    
    # Test configuration
    if test_configuration; then
        generate_client_config
        print_summary
        print_success "Installation completed successfully!"
    else
        print_error "Configuration test failed"
        cleanup_on_error
    fi
}

# Run main function
main "$@"