output "resource_group_platform" {
  value = azurerm_resource_group.platform.name
}

output "resource_group_workloads" {
  value = azurerm_resource_group.workloads.name
}

output "profile" {
  value = var.profile
}

output "hub_vnet_id" {
  value = module.hub.vnet_id
}

output "spoke_app_vnet_id" {
  value = module.spoke_app.vnet_id
}

output "spoke_data_vnet_id" {
  value = module.spoke_data.vnet_id
}

output "nat_gateway_id" {
  value = module.hub.nat_gateway_id
}

output "firewall_private_ip" {
  value = module.hub.firewall_private_ip
}

output "vpn_gateway_id" {
  value = module.hub.vpn_gateway_id
}

output "waf_public_ip" {
  value = module.hub.waf_public_ip
}

output "key_vault_uri" {
  value = module.shared.key_vault_uri
}

output "key_vault_name" {
  value = module.shared.key_vault_name
}

output "storage_account_name" {
  value = module.shared.storage_account_name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "jumpbox_private_ip" {
  value = try(module.jumpbox[0].private_ip, null)
}

output "jumpbox_public_ip" {
  value = try(module.jumpbox[0].public_ip, null)
}

output "jumpbox_admin_secret_name" {
  value       = try(module.jumpbox[0].admin_secret_name, null)
  description = "Key Vault secret that holds the jumpbox password. Value is not printed."
}

output "sql_fqdn" {
  value = try(module.sql[0].fqdn, null)
}

output "aks_name" {
  value = try(module.aks[0].name, null)
}

output "management_group_id" {
  value = module.identity.management_group_id
}

output "next_steps" {
  value = compact([
    "1. Confirm NSGs: jumpbox only from ${var.admin_source_prefix} (or VPN pool when VPN is on).",
    "2. Get the jumpbox password: az keyvault secret show --vault-name ${module.shared.key_vault_name} --name ${try(module.jumpbox[0].admin_secret_name, "jumpbox-admin")} --query value -o tsv",
    local.enable_firewall ? "3. Spoke default route points at Azure Firewall ${coalesce(module.hub.firewall_private_ip, "pending")}." : "3. Firewall is off in this profile; spokes use VNet local routing + NAT on the hub shared subnet.",
    local.enable_vpn_gateway ? "4. VPN Gateway is on (VpnGw*AZ). Use azure-p2s-vpn-lab for Entra ID OpenVPN/443." : "4. VPN Gateway is off. Keep it off unless you need S2S/P2S.",
    "5. terraform destroy -var-file=profiles/${var.profile}.tfvars when the demo is done.",
  ])
}
