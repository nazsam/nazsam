# Azure Arc

## Scope

Onboard Hyper-V **guests** first (Windows Server 2016+ / supported Linux). Hosts can be onboarded if they run a supported OS.

## Onboard a Windows guest

```powershell
# Run scripts/arc/install-arc-agent.ps1 on the guest after you create a service principal.
```

Terraform can create the Arc onboarding SP. The guest needs outbound 443 to Arc endpoints.

## What you enable after the agent is connected

- Azure Update Manager
- Defender for Cloud (Arc servers)
- Azure Monitor agent via data collection rule
- Azure Policy guest configuration (optional)
- File Sync and Backup remain their own agents; Arc does not replace them

## Validation

```bash
az connectedmachine list -g rg-hybrid-lab -o table
```

The machine should show `status: Connected`.
