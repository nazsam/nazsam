resource "random_string" "uniq" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${var.name_prefix}-platform-${var.profile}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "workloads" {
  name     = "rg-${var.name_prefix}-workloads-${var.profile}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}-${var.profile}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  sku                 = "PerGB2018"
  retention_in_days   = var.profile == "prod" ? 90 : 30
  tags                = local.tags
}

module "hub" {
  source = "./modules/hub-network"

  name_prefix          = var.name_prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.platform.name
  tags                 = local.tags
  hub_cidr             = local.hub_cidr
  subnets              = local.subnets
  enable_firewall      = local.enable_firewall
  enable_vpn_gateway   = local.enable_vpn_gateway
  enable_waf           = local.enable_waf
  enable_nat_gateway   = local.enable_nat_gateway
  firewall_sku_tier    = local.p.firewall_sku_tier
  vpn_sku              = local.p.vpn_sku
  log_analytics_id     = azurerm_log_analytics_workspace.this.id
}

module "shared" {
  source = "./modules/shared-services"

  name_prefix         = var.name_prefix
  uniq                = random_string.uniq.result
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
  tenant_id           = var.tenant_id
  profile             = var.profile
  kv_purge_protection = local.p.kv_purge
  shared_subnet_id    = module.hub.shared_subnet_id
  log_analytics_id    = azurerm_log_analytics_workspace.this.id
}

module "spoke_app" {
  source = "./modules/spoke-network"

  name                 = "app"
  name_prefix          = var.name_prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.workloads.name
  tags                 = local.tags
  address_space        = [local.spoke_app_cidr]
  subnets = {
    snet-app = local.subnets.snet-app
    snet-aks = local.subnets.snet-aks
  }
  hub_vnet_id          = module.hub.vnet_id
  hub_vnet_name        = module.hub.vnet_name
  hub_resource_group   = azurerm_resource_group.platform.name
  firewall_private_ip  = module.hub.firewall_private_ip
  enable_firewall      = local.enable_firewall
  log_analytics_id            = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.workspace_id
  flow_log_storage_id         = module.shared.flow_log_storage_id
  network_watcher_name        = module.hub.network_watcher_name
  network_watcher_rg          = module.hub.network_watcher_rg
}

module "spoke_data" {
  source = "./modules/spoke-network"

  name                 = "data"
  name_prefix          = var.name_prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.workloads.name
  tags                 = local.tags
  address_space        = [local.spoke_data_cidr]
  subnets = {
    snet-data = local.subnets.snet-data
    snet-pe   = local.subnets.snet-pe
  }
  hub_vnet_id          = module.hub.vnet_id
  hub_vnet_name        = module.hub.vnet_name
  hub_resource_group   = azurerm_resource_group.platform.name
  firewall_private_ip  = module.hub.firewall_private_ip
  enable_firewall      = local.enable_firewall
  log_analytics_id            = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.workspace_id
  flow_log_storage_id         = module.shared.flow_log_storage_id
  network_watcher_name        = module.hub.network_watcher_name
  network_watcher_rg          = module.hub.network_watcher_rg
}

module "identity" {
  source = "./modules/identity"

  name_prefix                = var.name_prefix
  enable_management_groups   = var.enable_management_groups
  subscription_id            = var.subscription_id
}

module "jumpbox" {
  count  = var.enable_jumpbox ? 1 : 0
  source = "./modules/jumpbox"
  depends_on = [module.shared]

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
  subnet_id           = module.hub.jump_subnet_id
  admin_username      = var.admin_username
  admin_source_prefix = var.admin_source_prefix
  public_ip_enabled   = local.jumpbox_public_ip
  key_vault_id        = module.shared.key_vault_id
}

module "sql" {
  count  = local.enable_sql ? 1 : 0
  source = "./modules/sql"
  depends_on = [module.shared]

  name_prefix         = var.name_prefix
  uniq                = random_string.uniq.result
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name
  tags                = local.tags
  sql_sku             = local.p.sql_sku
  subnet_id           = module.spoke_data.subnet_ids["snet-pe"]
  key_vault_id        = module.shared.key_vault_id
  admin_username      = var.admin_username
}

module "aks" {
  count  = local.enable_aks ? 1 : 0
  source = "./modules/aks"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name
  tags                = local.tags
  subnet_id           = module.spoke_app.subnet_ids["snet-aks"]
  log_analytics_id    = azurerm_log_analytics_workspace.this.id
  node_count          = local.p.aks_node_count
  vm_size             = local.p.aks_vm_size
  private_cluster     = var.profile == "prod"
}
