# Validation checks

On each file server:

```powershell
Get-Volume | Format-Table DriveLetter, FileSystemLabel, SizeRemaining
Get-DfsnRoot
Get-DfsrMembership
Get-SmbShare
```

Expect:

- `F:` label SHARES, `R:` label DFSR
- SMB share `Data` on `F:\Shares\Data`
- DFS-R content path under `R:\Dfsr\Data`
- File Sync server endpoint path `F:\Shares\Data`
- Cloud tiering enabled only on the F: endpoint

From a client:

```text
dir \\contoso\data
echo hello > \\contoso\data\probe.txt
```

In Azure:

```bash
az storage share exists --name corpdata --account-name <st...>
az backup job list --vault-name rsv-dfslab --resource-group rg-dfslab -o table
```

The probe file should appear in the Azure file share after a sync cycle.
