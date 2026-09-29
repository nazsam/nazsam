# Private Point-to-Site VPN lab

Secure remote access into a private hub-and-spoke network.

- Azure VPN Gateway **VpnGw1AZ** (required for OpenVPN + Entra ID; Basic SKU cannot do this)
- OpenVPN over **TCP 443**
- Microsoft Entra ID sign-in with **MFA via Conditional Access**
- Microsoft-registered Azure VPN Client audience `c632b3df-fb67-4d84-bdcf-b95ad541b5c8`
- Split tunnel (Azure Client default): only VNet prefixes go through the tunnel
- Hub: gateway, Azure Firewall, jumpbox subnet
- Spoke: private Windows + Linux VMs, **no public IPs**
- Jumpbox is the only path into workload VMs
- Jumpbox NSG allows 22/3389 only from the P2S client pool
- Logs: VPN, Firewall, and VNet flow logs → Log Analytics

```text
  Laptop + Azure VPN Client (Entra ID + MFA)
           |  OpenVPN / TCP 443
           v
     VpnGw1AZ  client pool 172.16.201.0/24
           |
     Azure Firewall
           |
     snet-jump  -->  jumpbox (no public IP)
                         |
                         +--> spoke-win  (RDP from jump only)
                         +--> spoke-linux (SSH from jump only)
```

## Cost warning

VpnGw1AZ and Azure Firewall are billed hourly. Destroy the lab when the demo ends.

```bash
cd azure-p2s-vpn-lab/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform destroy
```

## Entra ID / MFA

1. Tenant ID in `terraform.tfvars`
2. Assign users to a group that is allowed to use VPN (Conditional Access)
3. Require MFA for that group. The gateway does not add a second MFA prompt of its own; Conditional Access does.
4. Download the Azure VPN Client (Windows/macOS). Linux Entra ID client retired 31 Aug 2026 — use Windows/macOS for this lab.
5. Download the VPN client profile from the gateway and import `azurevpnconfig.xml`

Do **not** use the retired manually-registered audience `41b23e61-6c1e-4545-b367-cd054e0ed4b4` for new labs.

## Split tunnel

Leave forced tunneling off. Do not advertise `0.0.0.0/1` and `128.0.0.0/1`. Internet browsing stays on the client network; only `10.10.0.0/16` and `10.20.0.0/16` use the VPN.

## Path of a session

1. User connects Azure VPN Client → Entra ID + MFA
2. Client gets an IP from `172.16.201.0/24`
3. User RDP/SSH to the jumpbox private IP
4. From jumpbox, RDP/SSH to spoke VMs
5. Direct VPN-to-spoke is denied by spoke NSGs

See [docs/RUNBOOK.md](docs/RUNBOOK.md).
