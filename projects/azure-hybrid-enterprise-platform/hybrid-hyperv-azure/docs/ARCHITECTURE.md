# Hybrid architecture case study

## Context

A 400-person company runs line-of-business VMs on two Hyper-V hosts. They need:

- The same usernames in Office 365 / Entra ID
- Staff access to file shares and RDP jump hosts from home
- A cloud copy of file data
- A documented failover of critical VMs to Azure
- One place to see patches, inventory, and security alerts

They are **not** moving every VM to Azure on day one.

## Building blocks

1. **Identity.** One AD DS forest. Entra Connect with Password Hash Sync (simpler) or PTA (no hashes in the cloud). Hybrid join for Windows endpoints.
2. **Remote access.** Community OpenVPN (TCP 443) on a dedicated Linux VM in a DMZ VLAN that can reach the LAN. Split tunnel advertises only `10.1.0.0/16`. MFA via Entra Conditional Access in front of the VPN is out of scope for community OpenVPN; put the VPN VM behind a jump or add SSO later. For Azure workloads, use the P2S lab instead.
3. **Azure landing.** Small hub VNet, Recovery Services vault, Storage account for Files, Log Analytics, Key Vault. Optional S2S from the firewall to the hub.
4. **Arc.** Every supported Windows/Linux guest (and the Hyper-V hosts if they are Windows Server) is Arc-enabled. Policy assigns Azure Monitor agent.
5. **Files.** See the DFS lab. Azure Files is the cloud endpoint; DFS-N keeps `\\contoso\shares`.
6. **Backup / DR.** MARS or Azure Backup via Arc for the file servers. ASR for selected Hyper-V VMs (domain controllers are a special case — prefer a second on-prem DC plus Entra, do not fail over the only DC blindly).

## What Terraform deploys

See `terraform/`. It does **not** install Hyper-V, Entra Connect, or OpenVPN. Those are runbooks because they need the real forest and certificates.

## What this is not

- Not a CAF full-enterprise landing zone (see `azure-landing-zone-lab`)
- Not a production OpenVPN access server with paid support
- Not a license for skipping change control
