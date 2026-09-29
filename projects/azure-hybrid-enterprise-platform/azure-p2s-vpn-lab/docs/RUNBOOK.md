# P2S runbook

## Connect

1. Portal → VPN gateway → Point-to-site configuration → Download VPN client.
2. Import `AzureVPN/azurevpnconfig.xml` into Azure VPN Client.
3. Sign in with Entra ID. MFA is enforced by Conditional Access, not by the gateway SKU.
4. `ipconfig` (Windows) should show an adapter in `172.16.201.0/24`.
5. Confirm split tunnel: `Get-NetRoute` still has a `0.0.0.0/0` on the physical NIC. Azure prefixes only should point at the VPN adapter.

## Jumpbox-only access

```text
ssh azadmin@<jumpbox_private_ip>     # must work
ssh azadmin@<spoke_linux_private_ip> # must time out from the VPN client
```

From the jumpbox, the spoke SSH/RDP must work.

## Logs

Log Analytics queries:

```kusto
AzureDiagnostics
| where ResourceType == "VIRTUALNETWORKGATEWAYS"
| where TimeGenerated > ago(1h)

AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where TimeGenerated > ago(1h)

NTANetAnalytics
| where TimeGenerated > ago(1h)
| take 50
```

## Tear down

```bash
terraform destroy
```

Gateway delete takes a long time. Do not cancel it.
