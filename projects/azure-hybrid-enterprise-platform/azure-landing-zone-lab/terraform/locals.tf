locals {
  profiles = {
    learn = {
      enable_firewall    = false
      enable_vpn_gateway = false
      enable_waf         = false
      enable_nat_gateway = true
      enable_sql         = false
      enable_aks         = false
      firewall_sku_tier  = "Basic"
      vpn_sku            = "VpnGw1AZ"
      sql_sku            = "Basic"
      aks_node_count     = 1
      aks_vm_size        = "Standard_B2s"
      kv_purge           = false
      jumpbox_public_ip  = true
    }
    dev = {
      enable_firewall    = true
      enable_vpn_gateway = false
      enable_waf         = false
      enable_nat_gateway = true
      enable_sql         = true
      enable_aks         = false
      firewall_sku_tier  = "Basic"
      vpn_sku            = "VpnGw1AZ"
      sql_sku            = "Basic"
      aks_node_count     = 1
      aks_vm_size        = "Standard_B2s"
      kv_purge           = false
      jumpbox_public_ip  = true
    }
    prod = {
      enable_firewall    = true
      enable_vpn_gateway = true
      enable_waf         = true
      enable_nat_gateway = true
      enable_sql         = true
      enable_aks         = true
      firewall_sku_tier  = "Standard"
      vpn_sku            = "VpnGw2AZ"
      sql_sku            = "S0"
      aks_node_count     = 2
      aks_vm_size        = "Standard_D2s_v5"
      kv_purge           = true
      jumpbox_public_ip  = false
    }
  }

  p = local.profiles[var.profile]

  enable_firewall    = coalesce(var.enable_firewall, local.p.enable_firewall)
  enable_vpn_gateway = coalesce(var.enable_vpn_gateway, local.p.enable_vpn_gateway)
  enable_waf         = coalesce(var.enable_waf, local.p.enable_waf)
  enable_nat_gateway = coalesce(var.enable_nat_gateway, local.p.enable_nat_gateway)
  enable_sql         = coalesce(var.enable_sql, local.p.enable_sql)
  enable_aks         = coalesce(var.enable_aks, local.p.enable_aks)

  jumpbox_public_ip = local.enable_vpn_gateway ? false : local.p.jumpbox_public_ip

  tags = merge({
    project = "azure-landing-zone-lab"
    profile = var.profile
    owner   = "lab"
  }, var.tags)

  # CAF-style address plan. Do not overlap with on-prem or P2S pools.
  hub_cidr       = "10.10.0.0/16"
  spoke_app_cidr = "10.20.0.0/16"
  spoke_data_cidr = "10.30.0.0/16"

  subnets = {
    AzureFirewallSubnet           = "10.10.0.0/26"
    AzureFirewallManagementSubnet = "10.10.0.64/26"
    GatewaySubnet                 = "10.10.1.0/27"
    AzureBastionSubnet            = "10.10.1.32/26"
    snet-shared                   = "10.10.2.0/24"
    snet-jump                     = "10.10.3.0/24"
    snet-appgw                    = "10.10.4.0/24"
    snet-app                      = "10.20.1.0/24"
    snet-aks                      = "10.20.2.0/22"
    snet-data                     = "10.30.1.0/24"
    snet-pe                       = "10.30.2.0/24"
  }
}
