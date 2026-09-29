# Secure hybrid file services — DFS + Azure File Sync

Windows Server 2025 file sharing where branch users keep `\\contoso\data`, while content syncs to Azure Files for snapshots, Backup, and DR.

```text
  Branch users
       |
       |  UNC \\contoso\data   (DFS Namespace)
       v
  +-----------+  DFS-R on R:  +-----------+
  | FS01      | <-----------> | FS02      |
  | F:\Shares |               | F:\Shares |
  | R:\Dfsr   |               | R:\Dfsr   |
  +-----------+               +-----------+
        |  Azure File Sync on F: only (cloud tiering ON)
        v
  Azure file share  -- snapshots -- Azure Backup vault
                                -- ASR for the VM OS if needed
```

## Rules from current Microsoft guidance

- Azure File Sync **works with DFS Namespaces**. Users do not change UNC paths.
- Azure File Sync is the usual **replacement** for DFS-R. Keep DFS-R only for servers that cannot talk to Azure, or during migration.
- **Cloud tiering must be off on any volume that also has DFS-R replicated folders.** This lab puts DFS-R on `R:` and File Sync + tiering on `F:` so they never share a volume.
- Only one server endpoint may overlap a DFS-R location.
- Windows Server 2025 is a supported File Sync OS.

## What Terraform creates

Lab VMs currently have public IPs **locked to `admin_source_prefix`** so you can RDP without a jump box. For a demo that matches production, drop those public IPs and reach FS01/FS02 only through `azure-p2s-vpn-lab`.
- Data disks: 128 GB `F:` (shares + File Sync), 64 GB `R:` (DFS-R only)
- Storage account + Azure file share
- Storage Sync Service + sync group + cloud endpoint
- Recovery Services vault: file-share backup policy
- Log Analytics
- Key Vault for the local admin secret

Server registration, DFS-N, DFS-R, and the File Sync agent are PowerShell so they run **on the servers** after the VMs exist.

## Deploy

```bash
cd dfs-azure-file-sync/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Then RDP via the jump box from `azure-p2s-vpn-lab` or your landing-zone jump box and run:

1. `powershell/01-initialize-data-disks.ps1`
2. `powershell/02-install-dfs.ps1`
3. `powershell/03-configure-namespace.ps1`
4. `powershell/04-configure-dfsr.ps1`  (R: only)
5. `powershell/05-install-file-sync-agent.ps1`
6. Register the servers in the portal / `Register-AzStorageSyncServer`
7. `powershell/06-new-server-endpoint.ps1`  (F: only, cloud tiering on)

## Recovery

See [runbooks/RECOVERY.md](runbooks/RECOVERY.md) for share restore, server loss, and namespace repair.

## Validation

See [runbooks/VALIDATION.md](runbooks/VALIDATION.md).
