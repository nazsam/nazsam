param(
  [string]$Profile = "learn"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\terraform")

terraform output -json | Out-File -FilePath "..\docs\last-outputs.json" -Encoding utf8
Write-Host "Wrote terraform outputs (no secrets) to docs/last-outputs.json"

$rg = terraform output -raw resource_group_platform
Write-Host "Platform RG: $rg"
az resource list -g $rg --query "[].{name:name, type:type}" -o table
