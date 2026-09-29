# Recovery steps

## 1. Accidental file delete (most common)

Users keep `\\contoso\data`. Restore from:

1. Azure file share snapshots (portal → File share → Snapshots)
2. Azure Backup restore to the share or to an alternate folder
3. After restore, File Sync will converge. Do not restore the same files onto both FS01 and FS02 at once.

## 2. FS01 is dead, FS02 is healthy

1. DFS Namespace still has the FS02 folder target — users keep the UNC
2. File Sync server endpoint on FS02 continues to upload
3. Rebuild FS01 from Terraform, init disks, install DFS, add it back as a namespace target
4. Recreate the File Sync server endpoint on F: only
5. Recreate DFS-R membership on R: only if you still need DFS-R

## 3. Both servers gone

1. Azure Files still has the full dataset
2. Provision a new Windows Server 2025
3. Install the File Sync agent, register, create a server endpoint with initial download
4. Recreate the DFS namespace target pointing at the new server
5. Cloud tiering can be enabled after the first full download if volume space is tight

## 4. Poison DFS-R + File Sync overlap

If someone created a server endpoint on R: (the DFS-R volume):

1. Disable cloud tiering immediately
2. Remove the overlapping server endpoint
3. Confirm `Get-DfsrMembership` and File Sync paths do not share a volume

## 5. Azure Site Recovery

Use ASR for the **VM** (OS + app config), not as a substitute for File Sync. File data should fail over from Azure Files / Backup. Test failover into an isolated VNet.
