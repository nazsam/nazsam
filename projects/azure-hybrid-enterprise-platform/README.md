# Azure Hybrid Enterprise Platform

Presentation-ready Terraform labs for a mid-size enterprise: landing zone, hybrid Hyper-V identity, DFS + Azure File Sync, and private Point-to-Site access.

These are **learning and demo environments**, not production subscriptions. The default profile is the cheaper learning mode. Tear everything down when you are done.

| Lab | Folder | What you get |
|---|---|---|
| Azure landing zone | [`azure-landing-zone-lab`](azure-landing-zone-lab) | Hub-spoke, VPN/firewall/WAF/NAT toggles, management groups, Key Vault, Storage, SQL, AKS |
| Hybrid Hyper-V + Azure | [`hybrid-hyperv-azure`](hybrid-hyperv-azure) | Identity (Entra Connect), OpenVPN to the LAN, Arc, Terraform cloud, Azure Files, backup/DR, monitoring |
| DFS + Azure File Sync | [`dfs-azure-file-sync`](dfs-azure-file-sync) | Windows Server 2025 file servers, DFS-N, DFS-R on a separate volume, cloud tiering, Backup, ASR |
| Private P2S VPN | [`azure-p2s-vpn-lab`](azure-p2s-vpn-lab) | Entra ID + MFA, OpenVPN/443, jumpbox-only access, split tunnel, Log Analytics |

## Current Azure rules baked in

- New VPN gateways use **VpnGw*AZ** SKUs and **Standard** public IPs. The Basic VPN SKU cannot do OpenVPN or Entra ID.
- Entra ID P2S uses the **Microsoft-registered** Azure VPN Client audience `c632b3df-fb67-4d84-bdcf-b95ad541b5c8`.
- Split tunneling is the Azure VPN Client default. Forced tunnel is opt-in, not used here.
- New NSG flow logs cannot be created. Labs use **virtual network flow logs**.
- Azure File Sync works with DFS Namespaces. Cloud tiering must stay **off** on volumes that also run DFS Replication.

Start with [`azure-landing-zone-lab/README.md`](azure-landing-zone-lab/README.md) if you want the cheapest first deploy.
