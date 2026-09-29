#Requires -Modules Az.StorageSync
param(
  [Parameter(Mandatory = $true)][string]$ResourceGroup,
  [Parameter(Mandatory = $true)][string]$StorageSyncName,
  [Parameter(Mandatory = $true)][string]$SyncGroupName,
  [string]$ServerLocalPath = "F:\Shares\Data",
  [int]$VolumeFreeSpacePercent = 20
)

# Cloud tiering is enabled only on F:. DFS-R remains on R:.
New-AzStorageSyncServerEndpoint `
  -ResourceGroupName $ResourceGroup `
  -StorageSyncServiceName $StorageSyncName `
  -SyncGroupName $SyncGroupName `
  -ServerResourceId (Get-AzStorageSyncServer -ResourceGroupName $ResourceGroup -StorageSyncServiceName $StorageSyncName | Where-Object { $_.ServerName -eq $env:COMPUTERNAME }).Id `
  -ServerLocalPath $ServerLocalPath `
  -CloudTiering `
  -VolumeFreeSpacePercent $VolumeFreeSpacePercent

Write-Host "Server endpoint on F: with cloud tiering. Confirm Get-DfsrMembership still points at R:\Dfsr\Data."
