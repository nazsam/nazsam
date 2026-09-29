variable "name_prefix" { type = string }
variable "enable_management_groups" { type = bool }
variable "subscription_id" { type = string }

resource "azurerm_management_group" "lab" {
  count        = var.enable_management_groups ? 1 : 0
  display_name = "mg-${var.name_prefix}-lab"
}

resource "azurerm_management_group" "platform" {
  count                      = var.enable_management_groups ? 1 : 0
  display_name               = "mg-${var.name_prefix}-platform"
  parent_management_group_id = azurerm_management_group.lab[0].id
}

resource "azurerm_management_group" "workloads" {
  count                      = var.enable_management_groups ? 1 : 0
  display_name               = "mg-${var.name_prefix}-workloads"
  parent_management_group_id = azurerm_management_group.lab[0].id
}

resource "azurerm_management_group_subscription_association" "this" {
  count               = var.enable_management_groups ? 1 : 0
  management_group_id = azurerm_management_group.workloads[0].id
  subscription_id     = "/subscriptions/${var.subscription_id}"
}

output "management_group_id" {
  value = try(azurerm_management_group.lab[0].id, null)
}
