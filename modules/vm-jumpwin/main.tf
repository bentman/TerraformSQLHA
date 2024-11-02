# .\modules\vm-jumpwin\outputs.tf
#################### VM JUMPBOX ####################
# Create a static public IP for the jumpbox VM
resource "azurerm_public_ip" "vm_jumpwin_pip" {
  name                = "${var.shortregion}-vm-${var.computer_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = ["1"]
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.computer_name
  tags                = var.tags
}

# Create a network interface for the jumpbox VM
resource "azurerm_network_interface" "vm_jumpwin_nic" {
  name                           = "${var.shortregion}-vm-${var.computer_name}-nic"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true
  tags                           = var.tags
  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_cidr, 7)
    subnet_id                     = var.subnet_id
    primary                       = true
  }
}

# Create the Windows virtual machine for the jumpbox
resource "azurerm_windows_virtual_machine" "vm_jumpwin" {
  name                = "${var.shortregion}-vm-${var.computer_name}"
  computer_name       = var.computer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  zone                = "1"
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  license_type        = "Windows_Client"
  tags                = var.tags
  os_disk {
    name                 = "${var.shortregion}-vm-${var.computer_name}-dsk0os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = var.sku
    version   = "latest"
  }
  network_interface_ids = [
    azurerm_network_interface.vm_jumpwin_nic.id
  ]
}

# Create an extension to install OpenSSH on the jumpbox VM
resource "azurerm_virtual_machine_extension" "vm_jumpwin_openssh" {
  name                       = "InstallOpenSSH"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_jumpwin.id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "null_resource" "get_mystuff_win_copy" {
  provisioner "file" {
    source      = "${path.module}/get-mystuff.ps1"
    destination = "c:\\get-mystuff.ps1"
    connection {
      type            = "ssh"
      user            = var.admin_username
      password        = var.admin_password
      host            = azurerm_public_ip.vm_jumpwin_pip.ip_address
      target_platform = "windows"
      timeout         = "5m"
    }
  }
  depends_on = [
    azurerm_virtual_machine_extension.vm_jumpwin_openssh,
  ]
}

# Create an auto-shutdown schedule for the jumpbox VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_jumpwin_shutdown" {
  virtual_machine_id    = azurerm_windows_virtual_machine.vm_jumpwin.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.vm_shutdown_hhmm
  timezone              = var.vm_shutdown_tz
  notification_settings {
    enabled = false
  }
}

# Set the timezone for the jumpbox VM
resource "azurerm_virtual_machine_run_command" "vm_timezone_jumpwin" {
  name               = "SetTimeZone"
  location           = var.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_jumpwin.id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command \"Set-TimeZone -Name '${var.vm_shutdown_tz}' -Confirm:\\$false\""
  }
}
