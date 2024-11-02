# .\modules\vm-addc\main.tf
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
    private_ip_address            = cidrhost(var.subnet_cidrs[count.index], 5)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.addc_public_ip[count.index].id
  }
  dns_servers = var.domain_dns_servers
}

# Windows Virtual Machine for ADDC in each region
resource "azurerm_windows_virtual_machine" "addc_vm" {
  count               = length(var.regions)
  name                = lower("${var.shortregions[count.index]}-addc-vm")
  computer_name       = upper("${var.shortregions[count.index]}-addc")
  resource_group_name = var.resource_group_names[count.index]
  location            = var.regions[count.index]
  zone                = "1"
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
  winrm_listener {
    protocol = "Http"
  }
  identity {
    type = "SystemAssigned"
  }
}

# Install OpenSSH Extension for ADDC VMs
resource "azurerm_virtual_machine_extension" "install_openssh_addc" {
  count                      = length(var.regions)
  name                       = "${var.shortregions[count.index]}-InstallOpenSSH-addc"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
}

# Ensure the VM is in a stable state before executing the next command
resource "time_sleep" "install_openssh_addc_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh_addc,
  ]
}

########## INSTALL 1ST DOMAIN CONTROLLER FOR LAB ##########
# Copy setup domain script to the first Active Directory Domain Controller VM
resource "null_resource" "setup_domain_copy" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomain.ps1"
    destination = "c:\\Install-AdDomain.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "5m"
    }
  }
  depends_on = [
    time_sleep.install_openssh_addc_wait,
  ]
}

# Execute the setup domain script on the first Active Directory Domain Controller VM
resource "azurerm_virtual_machine_run_command" "setup_domain_exec" {
  name               = "SetupDomain"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomain.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
  }
  depends_on = [
    null_resource.setup_domain_copy,
  ]
}

# Ensure the VM is in a stable state before executing the next command
resource "time_sleep" "setup_domain_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_run_command.setup_domain_exec,
  ]
}

# Restart the first Active Directory Domain Controller VM after domain promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart" {
  name               = "${var.shortregions[0]}-AddcRestartCommand"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.setup_domain_wait,
  ]
}

# Wait for the VM to restart after domain promotion
resource "time_sleep" "addc_vm_restart_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart,
  ]
}

########## PROMOTE 2ND DOMAIN CONTROLLER FOR LAB ##########
# Copy setup domain controller script to the second Active Directory Domain Controller VM
resource "null_resource" "setup_domain_controller_copy" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomainController.ps1"
    destination = "c:\\Install-AdDomainController.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[1].ip_address
      target_platform = "windows"
      timeout         = "5m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait,
  ]
}

# Execute the setup domain controller script on the second Active Directory Domain Controller VM
resource "azurerm_virtual_machine_run_command" "setup_domain_controller_exec" {
  name               = "SetupDomainController"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Install-AdDomainController.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
  }
  depends_on = [
    null_resource.setup_domain_controller_copy,
  ]
}

# Ensure the VM is in a stable state before executing the next command
resource "time_sleep" "setup_domain_controller_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_run_command.setup_domain_controller_exec,
  ]
}

# Restart the second Active Directory Domain Controller VM after promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart_second" {
  name               = "${var.shortregions[1]}-AddcRestartCommand"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.setup_domain_controller_wait,
  ]
}

# Wait for the second VM to restart after domain controller promotion
resource "time_sleep" "addc_vm_restart_wait_second" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart_second,
  ]
}

########## COPY & EXECUTE DOMAIN ACCONTS SCRIPT
# Copy SqlAcl script to first Active Directory Domain Controller VM
resource "null_resource" "add_sqlacl_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-SqlAcl.ps1"
    destination = "c:\\Add-SqlAcl.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait_second,
  ]
}

# Copy DomainAccounts script to first Active Directory Domain Controller VM
resource "null_resource" "add_domainaccounts_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-DomainAccounts.ps1"
    destination = "c:\\Add-DomainAccounts.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    null_resource.add_sqlacl_copy,
  ]
}

# Execute Add-DomainAccounts script on first Active Directory Domain Controller VM
resource "null_resource" "add_domain_accounts_exec" {
  connection {
    type            = "ssh"
    host            = azurerm_public_ip.addc_public_ip[0].ip_address
    user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
    password        = var.domain_admin_pswd
    target_platform = "windows"
    timeout         = "10m"
  }
  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-DomainAccounts.ps1 -domain_name ${var.domain_name}"
    ]
  }
  depends_on = [
    null_resource.add_domainaccounts_copy,
  ]
}
