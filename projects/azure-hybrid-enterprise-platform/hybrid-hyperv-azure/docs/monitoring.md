# Monitoring and security

Central workspace is the Log Analytics workspace from Terraform.

| Source | What you collect |
|---|---|
| Arc-connected machines | Heartbeat, updates, security |
| Azure Files | Metrics + diagnostic logs |
| Recovery vault | ASR jobs, backup jobs |
| OpenVPN VM | syslog forwarded with AMA or rsyslog (optional) |
| Entra ID | Sign-in logs (Entra diagnostic settings, tenant-wide) |

Defender for Cloud: enable the Arc servers plan in the lab subscription only if you accept the extra cost.

Kusto starting points:

```kusto
Heartbeat
| where TimeGenerated > ago(1h)
| summarize by Computer

AzureDiagnostics
| where ResourceType == "VAULTS"
```
