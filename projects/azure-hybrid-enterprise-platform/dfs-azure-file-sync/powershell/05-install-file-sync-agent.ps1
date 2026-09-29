#Requires -RunAsAdministrator
# Installs the current Azure File Sync agent. Download URL follows Microsoft's published aka.ms link.
$msi = "$env:TEMP\StorageSyncAgent.msi"
$urls = @(
  "https://aka.ms/afs/agent/WindowsServer2025",
  "https://aka.ms/storagesyncagent"
)
$downloaded = $false
foreach ($url in $urls) {
  try {
    Invoke-WebRequest -Uri $url -OutFile $msi -MaximumRedirection 10
    $downloaded = $true
    break
  } catch {
    Write-Warning "Could not download from $url"
  }
}
if (-not $downloaded) {
  throw "Download the Storage Sync Agent MSI from https://learn.microsoft.com/azure/storage/file-sync/file-sync-deployment-guide and place it at $msi"
}
Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
Write-Host "Agent installed. Register this server in the Storage Sync Service next (portal or Register-AzStorageSyncServer)."
