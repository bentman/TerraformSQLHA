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
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-addc-nic"
  location            = var.regions[count.index]
  resource_group_name = var.resource_group_names[count.index]
  tags                = var.tags
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
  depends_on = [
    azurerm_public_ip.addc_public_ip,
  ]
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
  priority            = "Spot"       # Spot pricing
  eviction_policy     = "Deallocate" # Choose "Delete" or "Deallocate"
  tags                = var.tags
  zone                = "1"
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
  name                       = "${var.shortregions[count.index]}-InstallOpenSSH-Custom"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command \"
    Install-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0;
    Start-Service sshd;
    Set-Service -Name sshd -StartupType Automatic;
    New-NetFirewallRule -Name OpenSSH-Server-In-TCP -DisplayName 'OpenSSH Server (TCP)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22;
    Restart-Service sshd\""
  }
  SETTINGS
  depends_on = [
    azurerm_windows_virtual_machine.addc_vm,
  ]
}

# Wait for VM stabilization after OpenSSH installation
resource "time_sleep" "install_openssh_addc_wait" {
  create_duration = "3m"
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
  count              = 1
  name               = "Restart-ADDC-VM"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    null_resource.setup_domain,
  ]
}

# Wait for VM stabilization after OpenSSH installation
resource "time_sleep" "restart_addc_vm_wait" {
  create_duration = "7m"
  depends_on = [
    azurerm_virtual_machine_run_command.restart_addc_vm,
  ]
}

# Setup the domain on the second ADDC
resource "null_resource" "setup_domain_controller" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomainController.ps1"
    destination = "c:\\Install-AdDomainController.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[1].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomainController.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
    ]
  }
  depends_on = [
    time_sleep.restart_addc_vm_wait,
  ]
}

# Restart the ADDC VM after domain promotion
resource "azurerm_virtual_machine_run_command" "restart_addc_vm2" {
  count              = 1
  name               = "Restart-ADDC-VM"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    null_resource.setup_domain_controller,
  ]
}

# Setup the domain accounts on the first ADDC
resource "null_resource" "setup_domain_Accounts" {
  provisioner "file" {
    source      = "${path.module}/Install-DomainAccounts.ps1"
    destination = "c:\\Install-DomainAccounts.ps1"
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
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Add-DomainAccounts.ps1 -domain_name ${var.domain_name} -temp_admin_pswd ${var.temp_admin_pswd}"
    ]
  }
  depends_on = [
    azurerm_virtual_machine_run_command.restart_addc_vm2,
  ]
}

resource "null_resource" "sql_acl_script_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-SqlAcl.ps1"
    destination = "C:\\Add-SqlAcl.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    null_resource.setup_domain_Accounts,
  ]
}

# vm-addc AUTOSHUTDOWN
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_addc_shutdown" {
  count                 = length(var.regions)
  virtual_machine_id    = azurerm_windows_virtual_machine.addc_vm[count.index].id
  location              = var.regions[count.index]
  enabled               = true
  daily_recurrence_time = "0100"
  timezone              = "Central Standard Time"
  notification_settings {
    enabled = false
  }
  depends_on = [
    null_resource.sql_acl_script_copy,
  ]
}
