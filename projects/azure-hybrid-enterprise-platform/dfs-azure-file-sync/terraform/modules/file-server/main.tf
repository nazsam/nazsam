variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "tags" { type = map(string) }

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_windows_virtual_machine" "this" {
  name                  = "vm-${var.name}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_B2ms"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]
  patch_mode            = "AutomaticByPlatform"
  tags                  = var.tags

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}

resource "azurerm_managed_disk" "shares" {
  name                 = "disk-${var.name}-shares"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  tags                 = var.tags
}

resource "azurerm_managed_disk" "dfsr" {
  name                 = "disk-${var.name}-dfsr"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "shares" {
  managed_disk_id    = azurerm_managed_disk.shares.id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "dfsr" {
  managed_disk_id    = azurerm_managed_disk.dfsr.id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = 1
  caching            = "ReadWrite"
}

output "private_ip" { value = azurerm_network_interface.this.private_ip_address }
output "public_ip" { value = azurerm_public_ip.this.ip_address }
