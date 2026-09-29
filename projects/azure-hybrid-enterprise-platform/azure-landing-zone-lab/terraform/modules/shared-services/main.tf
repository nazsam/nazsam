variable "name_prefix" { type = string }
variable "uniq" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "tenant_id" { type = string }
variable "profile" { type = string }
variable "kv_purge_protection" { type = bool }
variable "shared_subnet_id" { type = string }
variable "log_analytics_id" { type = string }

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "shared" {
  name                            = "st${var.name_prefix}${var.uniq}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = var.profile == "prod" ? "GRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.profile != "prod"
  shared_access_key_enabled       = true
  https_traffic_only_enabled      = true
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_account" "flowlogs" {
  name                            = "stfl${var.name_prefix}${var.uniq}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  tags                            = var.tags
}

resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.name_prefix}-${var.uniq}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = var.profile == "prod" ? 90 : 7
  purge_protection_enabled      = var.kv_purge_protection
  public_network_access_enabled = var.profile != "prod"
  tags                          = var.tags

  network_acls {
    default_action = var.profile == "prod" ? "Deny" : "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log { category_group = "audit" }
  enabled_metric { category = "AllMetrics" }
}

output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "storage_account_name" { value = azurerm_storage_account.shared.name }
output "flow_log_storage_id" { value = azurerm_storage_account.flowlogs.id }
