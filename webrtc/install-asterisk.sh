#!/bin/bash
# Asterisk WebRTC Setup Script for Ubuntu Server
# Run this on phone.sakana.hair server

set -e

echo "================================================"
echo "Asterisk WebRTC Installation Script"
echo "Server: phone.sakana.hair"
echo "================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Step 1: System Update
print_status "Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install dependencies
print_status "Installing required dependencies..."
apt install -y \
    build-essential \
    wget \
    curl \
    libssl-dev \
    libncurses5-dev \
    libjansson-dev \
    libxml2-dev \
    uuid-dev \
    sqlite3 \
    libsqlite3-dev \
    pkg-config \
    libedit-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libgsm1-dev \
    libcurl4-openssl-dev \
    libnewt-dev \
    libiksemel-dev \
    libvorbis-dev \
    libasound2-dev \
    libogg-dev \
    libresample1-dev \
    libneon27-dev \
    libsrtp2-dev \
    libspandsp-dev \
    liblua5.2-dev \
    autoconf \
    automake \
    libtool \
    git \
    subversion \
    unixodbc-dev \
    libmysqlclient-dev \
    libpq-dev

# Step 3: Download and extract Asterisk
print_status "Downloading Asterisk 20 LTS..."
cd /usr/src
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
tar -xzvf asterisk-20-current.tar.gz
cd asterisk-20.*

# Step 4: Configure Asterisk with bundled pjproject
print_status "Configuring Asterisk with WebRTC support..."
./configure --with-pjproject-bundled --with-jansson-bundled --with-ssl --with-srtp

# Step 5: Select modules via menuselect
print_status "Configuring modules for WebRTC..."
make menuselect.makeopts

# Enable required modules for WebRTC
menuselect/menuselect \
    --enable res_http_websocket \
    --enable res_pjsip_transport_websocket \
    --enable codec_opus \
    --enable res_srtp \
    --enable res_crypto \
    --enable res_pjsip \
    --enable res_pjsip_session \
    --enable res_pjsip_sdp_rtp \
    --enable res_pjsip_dtls_connection \
    --enable res_rtp_asterisk \
    menuselect.makeopts

# Step 6: Compile and install
print_status "Compiling Asterisk (this may take a while)..."
make -j$(nproc)

print_status "Installing Asterisk..."
make install

# Step 7: Install sample configs and init scripts
print_status "Installing sample configurations..."
make samples
make config
ldconfig

# Step 8: Create asterisk user
print_status "Creating asterisk user..."
groupadd -r asterisk
useradd -r -g asterisk -d /var/lib/asterisk -s /sbin/nologin -c "Asterisk PBX" asterisk

# Step 9: Set permissions
print_status "Setting permissions..."
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/lib/asterisk
chown -R asterisk:asterisk /var/log/asterisk
chown -R asterisk:asterisk /var/spool/asterisk
chown -R asterisk:asterisk /run/asterisk
chown -R asterisk:asterisk /var/run/asterisk

# Step 10: Create keys directory
print_status "Creating SSL keys directory..."
mkdir -p /etc/asterisk/keys
chown -R asterisk:asterisk /etc/asterisk/keys

# Step 11: Install Let's Encrypt
print_status "Installing Certbot for SSL certificates..."
apt install -y certbot

# Step 12: Reminder for SSL certificate
print_warning "==================================================="
print_warning "IMPORTANT: SSL Certificate Setup Required!"
print_warning "==================================================="
print_warning "Run the following command to obtain SSL certificate:"
print_warning ""
print_warning "sudo certbot certonly --standalone -d phone.sakana.hair"
print_warning ""
print_warning "Then copy certificates to Asterisk:"
print_warning "sudo cp /etc/letsencrypt/live/phone.sakana.hair/fullchain.pem /etc/asterisk/keys/"
print_warning "sudo cp /etc/letsencrypt/live/phone.sakana.hair/privkey.pem /etc/asterisk/keys/"
print_warning "sudo chown -R asterisk:asterisk /etc/asterisk/keys/"
print_warning "==================================================="

print_status "Asterisk installation completed!"
print_status "Next steps:"
print_status "1. Obtain SSL certificate (see above)"
print_status "2. Configure pjsip.conf and http.conf"
print_status "3. Open firewall ports: 8088, 8089, 10000-20000/udp"
print_status "4. Start Asterisk: systemctl start asterisk"