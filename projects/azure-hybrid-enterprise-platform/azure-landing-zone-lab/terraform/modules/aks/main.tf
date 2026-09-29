variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "log_analytics_id" { type = string }
variable "node_count" { type = number }
variable "vm_size" { type = string }
variable "private_cluster" { type = bool }

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.name_prefix}"
  sku_tier            = "Free"
  oidc_issuer_enabled = true
  private_cluster_enabled = var.private_cluster
  role_based_access_control_enabled = true
  tags                = var.tags

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = var.subnet_id
    os_disk_size_gb = 64
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
  }
}

output "name" { value = azurerm_kubernetes_cluster.this.name }
output "id" { value = azurerm_kubernetes_cluster.this.id }
