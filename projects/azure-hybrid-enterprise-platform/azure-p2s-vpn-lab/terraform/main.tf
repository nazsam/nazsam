terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "location" {
  type    = string
  default = "canadacentral"
}
variable "name_prefix" {
  type    = string
  default = "p2slab"
}
variable "admin_username" {
  type    = string
  default = "azadmin"
}

variable "p2s_pool" {
  type        = string
  default     = "172.16.201.0/24"
  description = "VPN client address pool. Must not overlap hub, spoke, or on-prem."
}

locals {
  tags      = { project = "azure-p2s-vpn-lab" }
  hub_cidr  = "10.10.0.0/16"
  spoke_cidr = "10.20.0.0/16"
  aad_audience = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
}

resource "random_string" "uniq" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.name_prefix}-${random_string.uniq.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  tags                       = local.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "kv" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "admin" {
  name         = "lab-admin"
  value        = random_password.admin.result
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.kv]
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.hub_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "gw" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.1.0/27"]
}

resource "azurerm_subnet" "fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.0.0/26"]
}

resource "azurerm_subnet" "fw_mgmt" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.0.64/26"]
}

resource "azurerm_subnet" "jump" {
  name                 = "snet-jump"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.3.0/24"]
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.name_prefix}-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.spoke_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_virtual_network_peering" "hub_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
  depends_on                = [azurerm_virtual_network_gateway.vpn]
}

resource "azurerm_network_security_group" "jump" {
  name                = "nsg-jump"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh-from-p2s"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.p2s_pool
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-rdp-from-p2s"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.p2s_pool
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet"
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

resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "allow-from-jump-ssh"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.jump.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-from-jump-rdp"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = azurerm_subnet.jump.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-p2s-direct"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.p2s_pool
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet"
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

resource "azurerm_subnet_network_security_group_association" "jump" {
  subnet_id                 = azurerm_subnet.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

resource "azurerm_public_ip" "vpn" {
  name                = "pip-vpngw"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpngw-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"
  tags                = local.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gw.id
  }

  vpn_client_configuration {
    address_space        = [var.p2s_pool]
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["AAD"]
    aad_tenant           = "https://login.microsoftonline.com/${var.tenant_id}"
    aad_audience         = local.aad_audience
    aad_issuer           = "https://sts.windows.net/${var.tenant_id}/"
  }
}

resource "azurerm_public_ip" "fw" {
  name                = "pip-afw"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "fw_mgmt" {
  name                = "pip-afw-mgmt"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall_policy" "this" {
  name                = "afwp-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "p2s" {
  name               = "rcg-p2s"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  network_rule_collection {
    name     = "p2s-to-jump-and-spoke"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "p2s-to-jump"
      protocols             = ["TCP"]
      source_addresses      = [var.p2s_pool]
      destination_addresses = ["10.10.3.0/24"]
      destination_ports     = ["22", "3389"]
    }

    rule {
      name                  = "jump-to-workload"
      protocols             = ["TCP"]
      source_addresses      = ["10.10.3.0/24"]
      destination_addresses = ["10.20.1.0/24"]
      destination_ports     = ["22", "3389"]
    }
  }
}

resource "azurerm_firewall" "this" {
  name               = "afw-${var.name_prefix}"
  location           = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name           = "AZFW_VNet"
  sku_tier           = "Basic"
  firewall_policy_id = azurerm_firewall_policy.this.id
  tags               = local.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }

  management_ip_configuration {
    name                 = "fw-mgmt"
    subnet_id            = azurerm_subnet.fw_mgmt.id
    public_ip_address_id = azurerm_public_ip.fw_mgmt.id
  }
}

resource "azurerm_route_table" "spoke" {
  name                = "rt-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  route {
    name                   = "default-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "workload" {
  subnet_id      = azurerm_subnet.workload.id
  route_table_id = azurerm_route_table.spoke.id
}

resource "azurerm_monitor_diagnostic_setting" "vpn" {
  name                       = "diag-vpn"
  target_resource_id         = azurerm_virtual_network_gateway.vpn.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category = "GatewayDiagnosticLog" }
  enabled_log { category = "TunnelDiagnosticLog" }
  enabled_log { category = "RouteDiagnosticLog" }
  enabled_log { category = "IKEDiagnosticLog" }
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                       = "diag-fw"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category_group = "allLogs" }
}

resource "azurerm_network_watcher" "this" {
  name                = "nw-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_storage_account" "flow" {
  name                            = "stfl${var.name_prefix}${random_string.uniq.result}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_network_watcher_flow_log" "hub" {
  name                 = "fl-hub"
  network_watcher_name = azurerm_network_watcher.this.name
  resource_group_name  = azurerm_resource_group.this.name
  target_resource_id   = azurerm_virtual_network.hub.id
  storage_account_id   = azurerm_storage_account.flow.id
  enabled              = true
  version              = 2
  retention_policy {
    enabled = true
    days    = 7
  }
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.this.workspace_id
    workspace_region      = var.location
    workspace_resource_id = azurerm_log_analytics_workspace.this.id
    interval_in_minutes   = 60
  }
}

resource "azurerm_network_watcher_flow_log" "spoke" {
  name                 = "fl-spoke"
  network_watcher_name = azurerm_network_watcher.this.name
  resource_group_name  = azurerm_resource_group.this.name
  target_resource_id   = azurerm_virtual_network.spoke.id
  storage_account_id   = azurerm_storage_account.flow.id
  enabled              = true
  version              = 2
  retention_policy {
    enabled = true
    days    = 7
  }
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.this.workspace_id
    workspace_region      = var.location
    workspace_resource_id = azurerm_log_analytics_workspace.this.id
    interval_in_minutes   = 60
  }
}

module "jump_linux" {
  source              = "./modules/linux-vm"
  name                = "jump"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.jump.id
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.tags
}

module "spoke_linux" {
  source              = "./modules/linux-vm"
  name                = "spoke-linux"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.workload.id
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.tags
}

module "spoke_win" {
  source              = "./modules/windows-vm"
  name                = "spoke-win"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.workload.id
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.tags
}

output "resource_group" { value = azurerm_resource_group.this.name }
output "vpn_gateway_id" { value = azurerm_virtual_network_gateway.vpn.id }
output "vpn_public_ip" { value = azurerm_public_ip.vpn.ip_address }
output "p2s_pool" { value = var.p2s_pool }
output "jumpbox_private_ip" { value = module.jump_linux.private_ip }
output "spoke_linux_private_ip" { value = module.spoke_linux.private_ip }
output "spoke_windows_private_ip" { value = module.spoke_win.private_ip }
output "admin_secret_name" { value = azurerm_key_vault_secret.admin.name }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "log_analytics_id" { value = azurerm_log_analytics_workspace.this.id }
output "aad_audience" { value = local.aad_audience }
output "next_steps" {
  value = [
    "Download Azure VPN Client, import the P2S profile from the gateway.",
    "Connect with Entra ID. Confirm your client IP is in ${var.p2s_pool}.",
    "SSH to jumpbox ${module.jump_linux.private_ip} only. Direct SSH to spoke VMs from the VPN must fail.",
    "Kusto: AzureDiagnostics | where Category has 'Gateway' or Category has 'AzureFirewall'",
  ]
}
