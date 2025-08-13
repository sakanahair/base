#!/bin/bash
# Firewall configuration for Asterisk WebRTC

echo "Setting up firewall rules for Asterisk WebRTC..."

# Install ufw if not installed
apt install -y ufw

# Allow SSH (important!)
ufw allow 22/tcp

# Allow HTTP and HTTPS for Let's Encrypt
ufw allow 80/tcp
ufw allow 443/tcp

# Allow Asterisk WebSocket ports
ufw allow 8088/tcp  # HTTP WebSocket
ufw allow 8089/tcp  # HTTPS WebSocket (WSS)

# Allow SIP signaling
ufw allow 5060/udp
ufw allow 5060/tcp
ufw allow 5061/tcp  # SIP TLS

# Allow RTP media ports
ufw allow 10000:20000/udp

# Allow STUN/TURN if using TURN server
# ufw allow 3478/udp
# ufw allow 3478/tcp

# Enable firewall
ufw --force enable

# Show status
ufw status verbose

echo "Firewall configuration completed!"
echo ""
echo "Open ports:"
echo "  - 22/tcp    : SSH"
echo "  - 80/tcp    : HTTP (Let's Encrypt)"
echo "  - 443/tcp   : HTTPS (Let's Encrypt)"
echo "  - 5060      : SIP"
echo "  - 5061/tcp  : SIP TLS"
echo "  - 8088/tcp  : WebSocket (HTTP)"
echo "  - 8089/tcp  : WebSocket Secure (HTTPS)"
echo "  - 10000-20000/udp : RTP Media"