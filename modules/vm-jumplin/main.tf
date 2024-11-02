# Public IP for Linux jumpbox
resource "azurerm_public_ip" "vm_jumplin_pip" {
  name                = "${var.shortregion}-vm-${var.computer_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = ["1"]
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.computer_name
  tags                = var.tags
}

# Network interface for Linux jumpbox
resource "azurerm_network_interface" "vm_jumplin_nic" {
  name                           = "${var.shortregion}-vm-${var.computer_name}-nic"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true
  tags                           = var.tags
  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_cidr, 8)
    subnet_id                     = var.subnet_id
    primary                       = true
  }
}

# Linux VM jumpbox configuration
resource "azurerm_linux_virtual_machine" "vm_jumplin" {
  name                            = "${var.shortregion}-vm-${var.computer_name}"
  computer_name                   = var.computer_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  zone                            = "1"
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags
  os_disk {
    name                 = "${var.shortregion}-vm-${var.computer_name}-dsk0os"
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.sku
    version   = "latest"
  }
  network_interface_ids = [
    azurerm_network_interface.vm_jumplin_nic.id
  ]
}

# Copy script to VM using null resource
resource "null_resource" "jumplin_copy_file" {
  provisioner "file" {
    source      = "${path.module}/get-mystuff.bash"
    destination = "~/get-mystuff.bash"
    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.vm_jumplin_pip.ip_address
      agent    = false
      timeout  = "5m"
    }
  }
  depends_on = [
    azurerm_linux_virtual_machine.vm_jumplin,
  ]
}

# vm-jumpLin AUTOSHUTDOWN
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_jumplin_shutdown" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm_jumplin.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.vm_shutdown_hhmm
  timezone              = var.vm_shutdown_tz
  notification_settings {
    enabled = false
  }
  depends_on = [
    null_resource.jumplin_copy_file,
  ]
}
