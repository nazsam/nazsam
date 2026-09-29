#Requires -RunAsAdministrator
Get-Disk | Where-Object PartitionStyle -eq "RAW" | Sort-Object Number | ForEach-Object { $_ }

# LUN 0 -> F: shares / File Sync, LUN 1 -> R: DFS-R only
$disks = Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" } | Sort-Object Number
if ($disks.Count -lt 2) { throw "Expected two RAW data disks (LUN 0 shares, LUN 1 DFS-R)." }

Initialize-Disk -Number $disks[0].Number -PartitionStyle GPT
New-Partition -DiskNumber $disks[0].Number -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -NewFileSystemLabel "SHARES" -Confirm:$false

Initialize-Disk -Number $disks[1].Number -PartitionStyle GPT
New-Partition -DiskNumber $disks[1].Number -UseMaximumSize -DriveLetter R | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DFSR" -Confirm:$false

New-Item -ItemType Directory -Force -Path F:\Shares\Data | Out-Null
New-Item -ItemType Directory -Force -Path R:\Dfsr\Data | Out-Null
Write-Host "F: = File Sync + SMB shares. R: = DFS-R only. Do not enable cloud tiering on R:."
