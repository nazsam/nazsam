variable "name_prefix" { type = string }
variable "uniq" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "sql_sku" { type = string }
variable "subnet_id" { type = string }
variable "key_vault_id" { type = string }
variable "admin_username" { type = string }

resource "random_password" "sql" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "sql" {
  name         = "sql-admin"
  value        = random_password.sql.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_mssql_server" "this" {
  name                          = "sql-${var.name_prefix}-${var.uniq}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "12.0"
  administrator_login           = var.admin_username
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_mssql_database" "this" {
  name           = "sqldb-app"
  server_id      = azurerm_mssql_server.this.id
  sku_name       = var.sql_sku
  zone_redundant = false
  tags           = var.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "sql-psc"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

output "fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "secret_name" { value = azurerm_key_vault_secret.sql.name }
