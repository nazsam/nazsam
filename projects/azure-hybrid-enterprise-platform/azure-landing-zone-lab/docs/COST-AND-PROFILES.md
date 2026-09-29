# Cost and profiles

Default profile is **`learn`**. Apply `profiles/dev.tfvars` or `profiles/prod.tfvars` only when you need the extra SKUs.

| Capability | learn | dev | prod |
|---|---|---|---|
| Hub-spoke + NSGs + Log Analytics | on | on | on |
| NAT Gateway | on | on | on |
| Azure Firewall | off | Basic | Standard |
| VPN Gateway | off | off | VpnGw2AZ |
| App Gateway WAF_v2 | off | off | on |
| Private SQL | off | Basic DB | S0 |
| AKS | off | off | 2 x D2s_v5, private |
| Jumpbox public IP | locked to your /32 | locked to your /32 | off (VPN only) |
| Key Vault purge protection | off (easy destroy) | off | on |

## Why VPN is off by default

A `VpnGw1AZ` gateway is billed hourly whether you use it or not, and create/destroy takes about 45 minutes. The Basic VPN SKU **cannot** do OpenVPN or Entra ID. For a full P2S demo use `../azure-p2s-vpn-lab`.

## Override one flag without changing profile

```bash
terraform apply -var-file=profiles/learn.tfvars -var enable_firewall=true
```

## Destroy quickly

```bash
terraform destroy -var-file=profiles/learn.tfvars
```

If purge protection is on (`prod`), Key Vault delete is delayed. That is why learn/dev leave purge protection off.
