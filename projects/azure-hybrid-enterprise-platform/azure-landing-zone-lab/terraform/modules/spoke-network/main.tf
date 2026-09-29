variable "name" { type = string }
variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "address_space" { type = list(string) }
variable "subnets" { type = map(string) }
variable "hub_vnet_id" { type = string }
variable "hub_vnet_name" { type = string }
variable "hub_resource_group" { type = string }
variable "enable_firewall" { type = bool }
variable "log_analytics_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "flow_log_storage_id" { type = string }
variable "network_watcher_name" { type = string }
variable "network_watcher_rg" { type = string }
variable "firewall_private_ip" {
  type     = string
  default  = null
  nullable = true
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-from-hub"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.10.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-inbound"
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

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = azurerm_subnet.this
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${var.name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-${var.name}"
  resource_group_name          = var.hub_resource_group
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.this.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_route_table" "spoke" {
  count               = var.enable_firewall ? 1 : 0
  name                = "rt-${var.name_prefix}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each       = var.enable_firewall ? azurerm_subnet.this : {}
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.spoke[0].id
}

resource "azurerm_network_watcher_flow_log" "vnet" {
  name                 = "fl-${var.name_prefix}-${var.name}"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_rg
  target_resource_id   = azurerm_virtual_network.this.id
  storage_account_id   = var.flow_log_storage_id
  enabled              = true
  version              = 2
  tags                 = var.tags

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_id
    interval_in_minutes   = 60
  }
}

output "vnet_id" { value = azurerm_virtual_network.this.id }
output "subnet_ids" { value = { for k, s in azurerm_subnet.this : k => s.id } }
