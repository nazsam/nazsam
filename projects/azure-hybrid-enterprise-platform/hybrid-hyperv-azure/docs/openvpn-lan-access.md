# OpenVPN access to the internal LAN

This is the on-prem remote-access broker. It is **not** Azure VPN Gateway.

Staff connect with an OpenVPN client to `vpn.corp.example:443`. After connect, they can reach `10.1.0.0/16` (AD, file shares, jump RDP). Internet traffic stays on the home ISP (split tunnel).

## Why TCP 443

Most client networks allow outbound 443. UDP 1194 is cleaner but often blocked.

## Lab VM

- Ubuntu 22.04 on Hyper-V, 2 vCPU, 4 GB
- NIC 1: DMZ
- NIC 2: LAN (or a firewall DNAT to a single LAN NIC)
- No other roles on this VM

## Install sketch

See `scripts/openvpn/install-openvpn-server.sh`. It:

- Installs OpenVPN and Easy-RSA
- Creates a CA and server cert in `/etc/openvpn/pki` (you generate this on the box; nothing is committed)
- Writes `server.conf` with `proto tcp`, `port 443`, `push "route 10.1.0.0 255.255.0.0"`, and **no** `redirect-gateway`

## MFA

Community OpenVPN does not natively do Entra ID. Options for a later iteration: Azure VPN Gateway P2S (see `azure-p2s-vpn-lab`), or an identity-aware proxy in front. Do not paste third-party MFA plugins you have not reviewed.

## Validation

From a client that is **not** on the LAN:

1. Connect the OpenVPN profile
2. `ping` a DC in `10.1.0.0/16`
3. `\\contoso\shares` should resolve via DFS if DNS push is configured
4. Browse a public site and confirm it is **not** using the VPN IP
