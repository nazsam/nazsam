# Validation checks

Run after apply.

```powershell
$rg = terraform -chdir=terraform output -raw resource_group_platform
az network vnet list -g $rg -o table
az network nat gateway list -g $rg -o table
az keyvault list -g $rg -o table
az monitor log-analytics workspace list -g $rg -o table
```

Expect:

- Three VNets (hub, app, data) when you query both resource groups
- Jump box NSG allows TCP/22 only from `admin_source_prefix`
- Storage accounts reject HTTP (`minimumTlsVersion TLS1_2`)
- Key Vault uses Azure RBAC
- `terraform output` does not print passwords

When firewall is on:

```powershell
az network firewall list -g $rg -o table
az network route-table list --query "[].{name:name, routes:routes[].addressPrefix}" -o json
```

Spoke route tables should show `0.0.0.0/0` to the firewall private IP.
