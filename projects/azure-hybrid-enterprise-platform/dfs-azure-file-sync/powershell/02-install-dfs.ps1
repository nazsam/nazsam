#Requires -RunAsAdministrator
Install-WindowsFeature FS-FileServer, FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools
Write-Host "DFS-N, DFS-R, and File Server installed. Reboot if the installer asked for one."
