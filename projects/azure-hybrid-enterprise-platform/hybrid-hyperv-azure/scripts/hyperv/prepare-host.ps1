#Requires -RunAsAdministrator
# Lab Hyper-V host prep. Safe defaults: nested virt off unless you know you need it.
Get-WindowsFeature Hyper-V, Hyper-V-PowerShell | Format-Table
Install-WindowsFeature Hyper-V, Hyper-V-PowerShell, RSAT-Hyper-V-Tools -IncludeManagementTools -Restart:$false
New-VMSwitch -Name "vSwitch-LAN" -SwitchType Internal -ErrorAction SilentlyContinue
Write-Host "Create LAN/DMZ external switches in Hyper-V Manager bound to the correct NICs before placing VMs."
