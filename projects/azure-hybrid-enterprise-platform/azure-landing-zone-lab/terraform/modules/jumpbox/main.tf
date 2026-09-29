variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "admin_source_prefix" { type = string }
variable "public_ip_enabled" { type = bool }
variable "key_vault_id" { type = string }

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "admin" {
  name         = "jumpbox-admin"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_public_ip" "this" {
  count               = var.public_ip_enabled ? 1 : 0
  name                = "pip-${var.name_prefix}-jump"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}-jump"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-ssh-from-admin"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_prefix
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

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name_prefix}-jump"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_enabled ? azurerm_public_ip.this[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "vm-${var.name_prefix}-jump"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = "Standard_B2s"
  admin_username                  = var.admin_username
  admin_password                  = random_password.admin.result
  disable_password_authentication = false
  encryption_at_host_enabled      = false
  tags                            = var.tags
  network_interface_ids           = [azurerm_network_interface.this.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-${var.name_prefix}-jump"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

output "private_ip" { value = azurerm_network_interface.this.private_ip_address }
output "public_ip" { value = try(azurerm_public_ip.this[0].ip_address, null) }
output "admin_secret_name" { value = azurerm_key_vault_secret.admin.name }
