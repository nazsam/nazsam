variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "hub_cidr" { type = string }
variable "subnets" { type = map(string) }
variable "enable_firewall" { type = bool }
variable "enable_vpn_gateway" { type = bool }
variable "enable_waf" { type = bool }
variable "enable_nat_gateway" { type = bool }
variable "firewall_sku_tier" { type = string }
variable "vpn_sku" { type = string }
variable "log_analytics_id" { type = string }

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each = {
    AzureFirewallSubnet           = var.subnets.AzureFirewallSubnet
    AzureFirewallManagementSubnet = var.subnets.AzureFirewallManagementSubnet
    GatewaySubnet                 = var.subnets.GatewaySubnet
    snet-shared                   = var.subnets.snet-shared
    snet-jump                     = var.subnets.snet-jump
    snet-appgw                    = var.subnets.snet-appgw
  }

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "shared" {
  name                = "nsg-${var.name_prefix}-shared"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "deny-inbound-internet"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.hub["snet-shared"].id
  network_security_group_id = azurerm_network_security_group.shared.id
}

resource "azurerm_public_ip" "nat" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "pip-${var.name_prefix}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = "nat-${var.name_prefix}-hub"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "shared" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.hub["snet-shared"].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

resource "azurerm_public_ip" "fw" {
  count               = var.enable_firewall ? 1 : 0
  name                = "pip-${var.name_prefix}-afw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "fw_mgmt" {
  count               = var.enable_firewall && var.firewall_sku_tier == "Basic" ? 1 : 0
  name                = "pip-${var.name_prefix}-afw-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "afwp-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.firewall_sku_tier
  tags                = var.tags

  threat_intelligence_mode = var.firewall_sku_tier == "Basic" ? "Off" : "Alert"

  dns {
    proxy_enabled = var.firewall_sku_tier != "Basic"
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "baseline" {
  count              = var.enable_firewall ? 1 : 0
  name               = "rcg-baseline"
  firewall_policy_id = azurerm_firewall_policy.this[0].id
  priority           = 200

  network_rule_collection {
    name     = "allow-spoke-to-shared"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "spokes-to-hub-shared"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.20.0.0/16", "10.30.0.0/16"]
      destination_addresses = ["10.10.2.0/24"]
      destination_ports     = ["443", "1688"]
    }
  }

  application_rule_collection {
    name     = "allow-windows-update"
    priority = 300
    action   = "Allow"

    rule {
      name = "windows-update"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16"]
      destination_fqdns = ["*.windowsupdate.com", "*.microsoft.com", "*.azure.com"]
    }
  }
}

resource "azurerm_firewall" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "afw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.fw[0].id
  }

  dynamic "management_ip_configuration" {
    for_each = var.firewall_sku_tier == "Basic" ? [1] : []
    content {
      name                 = "fw-mgmt"
      subnet_id            = azurerm_subnet.hub["AzureFirewallManagementSubnet"].id
      public_ip_address_id = azurerm_public_ip.fw_mgmt[0].id
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  count                      = var.enable_firewall ? 1 : 0
  name                       = "diag-afw"
  target_resource_id         = azurerm_firewall.this[0].id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_public_ip" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-${var.name_prefix}-vpngw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vpngw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_sku
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub["GatewaySubnet"].id
  }
}

resource "azurerm_monitor_diagnostic_setting" "vpn" {
  count                      = var.enable_vpn_gateway ? 1 : 0
  name                       = "diag-vpngw"
  target_resource_id         = azurerm_virtual_network_gateway.vpn[0].id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log { category = "GatewayDiagnosticLog" }
  enabled_log { category = "TunnelDiagnosticLog" }
  enabled_log { category = "RouteDiagnosticLog" }
  enabled_log { category = "IKEDiagnosticLog" }
}

resource "azurerm_public_ip" "appgw" {
  count               = var.enable_waf ? 1 : 0
  name                = "pip-${var.name_prefix}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  count               = var.enable_waf ? 1 : 0
  name                = "wafp-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }
}

resource "azurerm_application_gateway" "waf" {
  count               = var.enable_waf ? 1 : 0
  name                = "appgw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  firewall_policy_id  = azurerm_web_application_firewall_policy.this[0].id
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gwip"
    subnet_id = azurerm_subnet.hub["snet-appgw"].id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.appgw[0].id
  }

  backend_address_pool {
    name = "placeholder"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "feip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "placeholder"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }
}

resource "azurerm_network_watcher" "this" {
  name                = "nw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

output "vnet_id" { value = azurerm_virtual_network.hub.id }
output "vnet_name" { value = azurerm_virtual_network.hub.name }
output "shared_subnet_id" { value = azurerm_subnet.hub["snet-shared"].id }
output "jump_subnet_id" { value = azurerm_subnet.hub["snet-jump"].id }
output "firewall_private_ip" { value = try(azurerm_firewall.this[0].ip_configuration[0].private_ip_address, null) }
output "nat_gateway_id" { value = try(azurerm_nat_gateway.this[0].id, null) }
output "vpn_gateway_id" { value = try(azurerm_virtual_network_gateway.vpn[0].id, null) }
output "waf_public_ip" { value = try(azurerm_public_ip.appgw[0].ip_address, null) }
output "network_watcher_name" { value = azurerm_network_watcher.this.name }
output "network_watcher_rg" { value = azurerm_network_watcher.this.resource_group_name }
