terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
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
  default = "hybridlab"
}

locals {
  tags = { project = "hybrid-hyperv-azure" }
}

resource "random_string" "uniq" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
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

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "shared" {
  name                 = "snet-shared"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "asr" {
  name                 = "snet-asr"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_network_security_group" "shared" {
  name                = "nsg-shared"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.shared.id
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
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
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
}

resource "azurerm_storage_share" "corp" {
  name               = "corpdata"
  storage_account_id = azurerm_storage_account.files.id
  quota              = 100
}

resource "azurerm_storage_sync" "this" {
  name                = "sss-${var.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_storage_sync_group" "corp" {
  name            = "sg-corpdata"
  storage_sync_id = azurerm_storage_sync.this.id
}

resource "azurerm_storage_sync_cloud_endpoint" "corp" {
  name                  = "ce-corpdata"
  storage_sync_group_id = azurerm_storage_sync_group.corp.id
  file_share_name       = azurerm_storage_share.corp.name
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

  retention_daily {
    count = 14
  }
}

resource "azurerm_backup_container_storage_account" "files" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  storage_account_id  = azurerm_storage_account.files.id
}

resource "azurerm_backup_protected_file_share" "corp" {
  resource_group_name       = azurerm_resource_group.this.name
  recovery_vault_name       = azurerm_recovery_services_vault.this.name
  source_storage_account_id = azurerm_backup_container_storage_account.files.storage_account_id
  source_file_share_name    = azurerm_storage_share.corp.name
  backup_policy_id          = azurerm_backup_policy_file_share.daily.id
}

resource "azurerm_monitor_diagnostic_setting" "vault" {
  name                       = "diag-vault"
  target_resource_id         = azurerm_recovery_services_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category_group = "allLogs" }
}

# Optional Arc onboarding application. Client secret is written to Key Vault only.
resource "azuread_application" "arc" {
  display_name = "${var.name_prefix}-arc-onboard"
}

resource "azuread_service_principal" "arc" {
  client_id = azuread_application.arc.client_id
}

resource "azuread_service_principal_password" "arc" {
  service_principal_id = azuread_service_principal.arc.id
}

resource "azurerm_role_assignment" "arc" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Azure Connected Machine Onboarding"
  principal_id         = azuread_service_principal.arc.object_id
}

resource "azurerm_key_vault_secret" "arc_app" {
  name         = "arc-onboard-client-id"
  value        = azuread_application.arc.client_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.kv]
}

resource "azurerm_key_vault_secret" "arc_secret" {
  name         = "arc-onboard-client-secret"
  value        = azuread_service_principal_password.arc.value
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.kv]
}

output "resource_group" { value = azurerm_resource_group.this.name }
output "hub_vnet_id" { value = azurerm_virtual_network.hub.id }
output "asr_subnet_id" { value = azurerm_subnet.asr.id }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "storage_account_name" { value = azurerm_storage_account.files.name }
output "file_share_name" { value = azurerm_storage_share.corp.name }
output "storage_sync_name" { value = azurerm_storage_sync.this.name }
output "recovery_vault_name" { value = azurerm_recovery_services_vault.this.name }
output "log_analytics_id" { value = azurerm_log_analytics_workspace.this.id }
output "arc_onboard_secret_names" {
  value = ["arc-onboard-client-id", "arc-onboard-client-secret"]
}
