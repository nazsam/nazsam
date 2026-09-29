#Requires -RunAsAdministrator
param(
  [string]$Namespace = "\\contoso\data",
  [string]$SharePath = "F:\Shares\Data",
  [string]$ShareName = "Data"
)

New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Authenticated Users" -ErrorAction SilentlyContinue

# Domain-based namespace requires the machine to be domain joined.
# For a workgroup lab, use a standalone namespace on FS01:
if (-not (Get-DfsnRoot -ErrorAction SilentlyContinue)) {
  try {
    New-DfsnRoot -Path $Namespace -TargetPath "\\$env:COMPUTERNAME\$ShareName" -Type DomainV2
  } catch {
    Write-Warning "Domain namespace failed (machine may not be domain-joined). Creating standalone root \\$env:COMPUTERNAME\dfs."
    New-DfsnRoot -Path "\\$env:COMPUTERNAME\dfs" -TargetPath "\\$env:COMPUTERNAME\$ShareName" -Type Standalone
  }
}

Write-Host "Publish the same folder target from FS02 after it is installed so UNC stays stable during a node loss."
