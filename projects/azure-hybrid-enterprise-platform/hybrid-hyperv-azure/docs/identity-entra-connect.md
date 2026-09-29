# Entra Connect runbook

Use this as a checklist in a lab forest. Do not treat it as a production identity design.

## Before you start

- A routable UPN suffix (`corp.example` matches the Entra verified domain)
- Global Administrator (or Hybrid Identity Administrator) in Entra ID for the first install
- A member server, not a domain controller, for Entra Connect
- TLS 1.2 on the server

## Install (high level)

1. Download Entra Connect from Microsoft (current installer, not a copied binary in this repo).
2. Express settings are fine for a lab (Password Hash Sync).
3. Staging mode first if you already have a server.
4. Confirm `Get-ADSyncScheduler` shows a cycle.
5. In Entra ID, check a test user `onPremisesSyncEnabled`.

## Hardening

- Restrict who can log on to the Connect server
- Do not browse the internet from that server
- Back up the Entra Connect encryption key using the documented Microsoft procedure
- Disable legacy authentication in Entra ID after hybrid join is healthy

## Validation

```powershell
Start-ADSyncSyncCycle -PolicyType Delta
Get-ADSyncScheduler
```

In Entra admin center: users sourced from Windows Server AD should show **On-premises sync**.
