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
    resource_group { prevent_deletion_if_contains_resources = false }
    key_vault { purge_soft_delete_on_destroy = true }
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
  default = "dfslab"
}
variable "admin_username" {
  type    = string
  default = "azadmin"
}
variable "admin_source_prefix" {
  type        = string
  description = "Your public IP /32 for RDP in the lab. Use a jumpbox NSG in a real design."
}

locals { tags = { project = "dfs-azure-file-sync" } }

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
  name         = "fileserver-admin"
  value        = random_password.admin.result
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.kv]
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.40.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "files" {
  name                 = "snet-files"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_network_security_group" "files" {
  name                = "nsg-files"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "rdp-from-admin"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.admin_source_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "files" {
  subnet_id                 = azurerm_subnet.files.id
  network_security_group_id = azurerm_network_security_group.files.id
}

resource "azurerm_storage_account" "files" {
  name                            = "st${var.name_prefix}${random_string.uniq.result}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  tags                            = local.tags

  blob_properties {
    delete_retention_policy { days = 7 }
  }
}

resource "azurerm_storage_share" "data" {
  name               = "corpdata"
  storage_account_id = azurerm_storage_account.files.id
  quota              = 512
}

resource "azurerm_storage_sync" "this" {
  name                = "sss-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_storage_sync_group" "data" {
  name            = "sg-corpdata"
  storage_sync_id = azurerm_storage_sync.this.id
}

resource "azurerm_storage_sync_cloud_endpoint" "data" {
  name                  = "ce-corpdata"
  storage_sync_group_id = azurerm_storage_sync_group.data.id
  file_share_name       = azurerm_storage_share.data.name
  storage_account_id    = azurerm_storage_account.files.id
}

resource "azurerm_recovery_services_vault" "this" {
  name                = "rsv-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  soft_delete_enabled = false
  tags                = local.tags
}

resource "azurerm_backup_policy_file_share" "daily" {
  name                = "pol-files-daily"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  backup {
    frequency = "Daily"
    time      = "23:00"
  }
  retention_daily { count = 14 }
}

resource "azurerm_backup_container_storage_account" "files" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  storage_account_id  = azurerm_storage_account.files.id
}

resource "azurerm_backup_protected_file_share" "data" {
  resource_group_name       = azurerm_resource_group.this.name
  recovery_vault_name       = azurerm_recovery_services_vault.this.name
  source_storage_account_id = azurerm_backup_container_storage_account.files.storage_account_id
  source_file_share_name    = azurerm_storage_share.data.name
  backup_policy_id          = azurerm_backup_policy_file_share.daily.id
}

resource "azurerm_monitor_diagnostic_setting" "sync" {
  name                       = "diag-sync"
  target_resource_id         = azurerm_storage_sync.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category_group = "allLogs" }
}

module "fs01" {
  source              = "./modules/file-server"
  name                = "fs01"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.files.id
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.tags
}

module "fs02" {
  source              = "./modules/file-server"
  name                = "fs02"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.files.id
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.tags
}

output "resource_group" { value = azurerm_resource_group.this.name }
output "fs01_private_ip" { value = module.fs01.private_ip }
output "fs02_private_ip" { value = module.fs02.private_ip }
output "storage_account_name" { value = azurerm_storage_account.files.name }
output "file_share_name" { value = azurerm_storage_share.data.name }
output "storage_sync_id" { value = azurerm_storage_sync.this.id }
output "sync_group_id" { value = azurerm_storage_sync_group.data.id }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "admin_secret_name" { value = azurerm_key_vault_secret.admin.name }
output "recovery_vault_name" { value = azurerm_recovery_services_vault.this.name }
output "log_analytics_id" { value = azurerm_log_analytics_workspace.this.id }
