#!/bin/bash

# Zoiper用SIPアカウント作成スクリプト

ACCOUNT=$1
PASSWORD=$2

if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <account_number> <password>"
    echo "Example: $0 7000 mypassword"
    exit 1
fi

cat >> /etc/asterisk/pjsip.conf <<EOF

;==============================================================================
; Zoiper/Normal SIP Account $ACCOUNT
;==============================================================================
[${ACCOUNT}]
type=endpoint
transport=transport-udp
context=from-internal
disallow=all
allow=ulaw,alaw,g722,opus
auth=${ACCOUNT}-auth
aors=${ACCOUNT}
callerid="Zoiper User ${ACCOUNT}" <${ACCOUNT}>
direct_media=no
rtp_symmetric=yes
force_rport=yes
rewrite_contact=yes

[${ACCOUNT}]
type=aor
max_contacts=5
remove_existing=yes
default_expiration=3600
maximum_expiration=7200
minimum_expiration=60

[${ACCOUNT}-auth]
type=auth
auth_type=userpass
username=${ACCOUNT}
password=${PASSWORD}
realm=phone.sakana.hair

EOF

echo "Created Zoiper account: $ACCOUNT with password: $PASSWORD"
echo "Reloading PJSIP..."
asterisk -rx "pjsip reload"
echo "Done!"

echo ""
echo "Zoiper Configuration:"
echo "====================="
echo "Domain/Server: phone.sakana.hair or サーバーのIPアドレス"
echo "Port: 5060"
echo "Transport: UDP"
echo "Username: $ACCOUNT"
echo "Password: $PASSWORD"
echo "Auth Username: $ACCOUNT"