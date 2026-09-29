#Requires -RunAsAdministrator
param(
  [Parameter(Mandatory = $true)][string]$ServicePrincipalClientId,
  [Parameter(Mandatory = $true)][string]$ServicePrincipalSecret,
  [Parameter(Mandatory = $true)][string]$TenantId,
  [Parameter(Mandatory = $true)][string]$SubscriptionId,
  [Parameter(Mandatory = $true)][string]$ResourceGroup,
  [string]$Location = "canadacentral"
)

# Downloads the current Arc agent using Microsoft's documented onboard flow.
$ProgressPreference = "SilentlyContinue"
Invoke-WebRequest -Uri "https://aka.ms/azcmagent-windows" -TimeoutSec 120 -OutFile "$env:TEMP\install_windows_azcmagent.ps1"
& "$env:TEMP\install_windows_azcmagent.ps1"

& "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
  --service-principal-id $ServicePrincipalClientId `
  --service-principal-secret $ServicePrincipalSecret `
  --tenant-id $TenantId `
  --subscription-id $SubscriptionId `
  --resource-group $ResourceGroup `
  --location $Location `
  --cloud AzureCloud
