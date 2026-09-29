# Architecture notes

## Volume split (the important part)

| Volume | Path | Role | Cloud tiering |
|---|---|---|---|
| F: | F:\Shares\Data | SMB + DFS-N target + Azure File Sync | On |
| R: | R:\Dfsr\Data | DFS Replication only | Must stay off |

Microsoft: File Sync and DFS-R may run side by side only if cloud tiering is disabled on DFS-R volumes, and only one server endpoint overlaps a DFS-R location. Splitting volumes makes that easy to prove in a demo.

## Identity

Domain-join FS01/FS02 for a domain DFS namespace (`\\contoso\data`). Workgroup labs fall back to a standalone namespace.

## Monitoring

Storage Sync diagnostic settings go to Log Analytics. Watch `StorageSync*` tables and Azure Backup jobs.

## Related labs

- Hybrid platform story: `../hybrid-hyperv-azure`
- Private admin access: `../azure-p2s-vpn-lab`
