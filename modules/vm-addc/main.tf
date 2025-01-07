# ./modules/vm-addc/main.tf
#################### ADD ADDC ####################

# Public IP for ADDC in each region
resource "azurerm_public_ip" "addc_public_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-addc-pip"
  location            = var.regions[count.index]
  resource_group_name = var.resource_group_names[count.index]
  zones               = ["1"]
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface for ADDC in each region
resource "azurerm_network_interface" "addc_nic" {
  count                          = length(var.regions)
  name                           = "${var.shortregions[count.index]}-addc-nic"
  location                       = var.regions[count.index]
  resource_group_name            = var.resource_group_names[count.index]
  tags                           = var.tags
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[count.index]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_cidrs[count.index], 5) # Ensure no IP conflicts
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.addc_public_ip[count.index].id
  }

  # Use domain-specific DNS servers for the NIC
  dns_servers = var.domain_dns_servers
}

# Windows Virtual Machine for ADDC in each region
resource "azurerm_windows_virtual_machine" "addc_vm" {
  count               = length(var.regions)
  name                = lower("${var.shortregions[count.index]}-addc-vm")
  computer_name       = upper("${var.shortregions[count.index]}-addc")
  resource_group_name = var.resource_group_names[count.index]
  location            = var.regions[count.index]
  size                = var.vm_addc_size
  admin_username      = var.domain_admin_user
  admin_password      = var.domain_admin_pswd
  provision_vm_agent  = true
  tags                = var.tags
  network_interface_ids = [
    azurerm_network_interface.addc_nic[count.index].id
  ]

  os_disk {
    name                 = "${var.shortregions[count.index]}-addc-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Ensure proper remote management capabilities
  winrm_listener {
    protocol = "Http"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_network_interface.addc_nic, # Explicit dependency on NIC creation
  ]
}

# OpenSSH Extension for ADDC VMs
resource "azurerm_virtual_machine_extension" "install_openssh_addc" {
  count                      = length(var.regions)
  name                       = "${var.shortregions[count.index]}-InstallOpenSSH-addc"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
}

# Wait for VM stabilization after OpenSSH installation
resource "time_sleep" "install_openssh_addc_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh_addc,
  ]
}

########## DOMAIN SETUP ##########

# Setup the domain on the first ADDC
resource "null_resource" "setup_domain" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomain.ps1"
    destination = "c:\\Install-AdDomain.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomain.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
    ]
  }

  depends_on = [
    time_sleep.install_openssh_addc_wait,
  ]
}

# Restart the ADDC VM after domain promotion
resource "azurerm_virtual_machine_run_command" "restart_addc_vm" {
  count               = 1
  name                = "Restart-ADDC-VM"
  location            = var.regions[0]
  virtual_machine_id  = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }

  depends_on = [
    null_resource.setup_domain,
  ]
}
