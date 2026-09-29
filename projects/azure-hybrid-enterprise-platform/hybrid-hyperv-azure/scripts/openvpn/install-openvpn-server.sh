#!/usr/bin/env bash
# Lab-only OpenVPN server sketch for Ubuntu 22.04.
# Generates a local PKI on the box. Do not copy keys into git.
set -euo pipefail

LAN_CIDR="${LAN_CIDR:-10.1.0.0/16}"
VPN_NET="${VPN_NET:-10.8.0.0}"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn easy-rsa

make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch gen-req server nopass
./easyrsa --batch sign-req server server
./easyrsa gen-dh
openvpn --genkey secret /etc/openvpn/easy-rsa/pki/ta.key

install -m 0600 pki/ca.crt /etc/openvpn/server/ca.crt
install -m 0600 pki/issued/server.crt /etc/openvpn/server/server.crt
install -m 0600 pki/private/server.key /etc/openvpn/server/server.key
install -m 0600 pki/dh.pem /etc/openvpn/server/dh.pem
install -m 0600 pki/ta.key /etc/openvpn/server/ta.key

cat >/etc/openvpn/server/server.conf <<EOF
port 443
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server ${VPN_NET} 255.255.255.0
push "route ${LAN_CIDR%/*} 255.255.0.0"
push "dhcp-option DNS 10.1.0.10"
keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun
verb 3
explicit-exit-notify 0
# Split tunnel: do not push redirect-gateway.
EOF

systemctl enable --now openvpn-server@server
echo "OpenVPN is listening on TCP/443. Create client certs with easyrsa; do not commit them."
