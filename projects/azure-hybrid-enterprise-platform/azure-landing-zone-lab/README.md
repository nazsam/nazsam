# Azure landing zone lab

Hands-on hub-and-spoke landing zone in Terraform. **`learn` is the default** so you can demo the design without turning on the expensive always-on SKUs.

```text
                    +------------------ hub-vnet 10.10.0.0/16 ------------------+
   Internet         | GatewaySubnet | AzureFirewallSubnet | snet-shared | snet-appgw | snet-jump |
     |              |   VPN Gw*     |   Azure Firewall*   | NAT + KV/SA |  WAF*      | jumpbox   |
     |              +-------+------------------+-----------------------------------------------+
                    |       |                  |
                    |     peering            peering
                    v                  v
            spoke-app 10.20.0.0/16   spoke-data 10.30.0.0/16
            AKS* / app subnet        SQL* / data subnet
```

`*` = off in `learn`, on in `dev`/`prod` according to [docs/COST-AND-PROFILES.md](docs/COST-AND-PROFILES.md).

## What you get

- Hub and spoke virtual networks, peerings, NSGs, and route tables
- NAT Gateway on hub shared subnets (default on)
- Optional Azure Firewall (Basic or Standard) with a forced-tunnel UDR on spokes
- Optional VPN Gateway (`VpnGw1AZ` / `VpnGw2AZ`) for S2S or P2S
- Optional Application Gateway WAF_v2
- Shared services: Key Vault (RBAC), Storage (TLS 1.2, no public blobs), Log Analytics
- Optional management group tree (needs Tenant Root Group rights)
- Optional private SQL and private AKS examples
- Jump box: public IP locked to your IP in `learn`; private-only when VPN is enabled

## Quick start

```bash
cd azure-landing-zone-lab/terraform
cp terraform.tfvars.example terraform.tfvars   # set subscription_id, tenant_id, admin_source_prefix
terraform init
terraform plan -var-file=profiles/learn.tfvars
terraform apply -var-file=profiles/learn.tfvars
```

Switch profiles without rewriting the design:

```bash
terraform apply -var-file=profiles/dev.tfvars
terraform apply -var-file=profiles/prod.tfvars
```

Tear down (VPN and firewall take the longest):

```bash
terraform destroy -var-file=profiles/learn.tfvars
```

Use [docs/DEPLOY-AND-TEARDOWN.md](docs/DEPLOY-AND-TEARDOWN.md) and [docs/VALIDATE.md](docs/VALIDATE.md) so you do not get stuck.

## Secure defaults

- No open `0.0.0.0/0` management ports
- Storage: TLS 1.2, `allow_nested_items_to_be_public = false`
- Key Vault: Azure RBAC, purge protection in `prod`
- SQL and AKS (when enabled) use private connectivity
- Terraform outputs print resource IDs and hostnames, not secret values
- Passwords are generated into Key Vault; `terraform output` shows the secret name only

## Docs

| File | Why |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Address plan, routing, identity |
| [docs/COST-AND-PROFILES.md](docs/COST-AND-PROFILES.md) | What each profile turns on and why |
| [docs/DEPLOY-AND-TEARDOWN.md](docs/DEPLOY-AND-TEARDOWN.md) | Deploy, test, destroy |
| [docs/VALIDATE.md](docs/VALIDATE.md) | Post-apply checks |

For Entra ID Point-to-Site with OpenVPN/443, MFA, and jumpbox-only access, use the dedicated [`../azure-p2s-vpn-lab`](../azure-p2s-vpn-lab) lab. That SKU is never the landing-zone default because it is the main cost driver.
