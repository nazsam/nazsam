#Requires -RunAsAdministrator
param(
  [string]$GroupName = "rg-corpdata-dfsr",
  [string]$FolderName = "Data",
  [string]$LocalPath = "R:\Dfsr\Data",
  [Parameter(Mandatory = $true)][string]$PartnerComputer
)

# DFS-R stays on R:. Cloud tiering is never enabled on this volume.
New-DfsReplicationGroup -GroupName $GroupName -ErrorAction SilentlyContinue
Add-DfsrMember -GroupName $GroupName -ComputerName $env:COMPUTERNAME, $PartnerComputer -ErrorAction SilentlyContinue
New-DfsReplicatedFolder -GroupName $GroupName -FolderName $FolderName -ErrorAction SilentlyContinue
Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $env:COMPUTERNAME -ContentPath $LocalPath -PrimaryMember $true
Set-DfsrMembership -GroupName $GroupName -FolderName $FolderName -ComputerName $PartnerComputer -ContentPath $LocalPath
Add-DfsrConnection -GroupName $GroupName -SourceComputerName $env:COMPUTERNAME -DestinationComputerName $PartnerComputer
Write-Host "DFS-R is on R: only. Do not create a File Sync server endpoint on R:."
