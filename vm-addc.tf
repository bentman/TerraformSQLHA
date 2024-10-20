#################### ADD ADDC ####################
# Active Directory Domain Controllers
resource "azurerm_public_ip" "addc_public_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-addc-pip"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.labtags
}

resource "azurerm_network_interface" "addc_nic" {
  count                          = length(var.regions)
  name                           = "${var.shortregions[count.index]}-addc-nic"
  location                       = var.regions[count.index]
  resource_group_name            = azurerm_resource_group.rg.name
  tags                           = var.labtags
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_addc[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_addc[count.index].address_prefixes[0], 5)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.addc_public_ip[count.index].id
  }
  depends_on = [
    azurerm_public_ip.addc_public_ip,
  ]
}

resource "azurerm_windows_virtual_machine" "addc_vm" {
  count               = length(var.regions)
  name                = lower("${var.shortregions[count.index]}-addc-vm")
  computer_name       = upper("${var.shortregions[count.index]}-addc")
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.domain_admin_user
  admin_password      = var.domain_admin_pswd
  provision_vm_agent  = true
  size                = var.vm_addc_size
  tags                = var.labtags
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

resource "azurerm_virtual_machine_extension" "install_openssh_addc" {
  count                      = length(var.regions)
  name                       = "InstallOpenSSH-addc${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.addc_vm
  ]
}

resource "azurerm_virtual_machine_extension" "allow_remote_addc" {
  count                      = length(var.regions)
  name                       = "allow-remote-addc${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command \"New-NetFirewallRule -DisplayName 'Open Port 22 for SSH' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any; Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv4-In)' -Enabled True; Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv6-In)' -Enabled True; Set-ItemProperty -Path 'HKLM:\\\\System\\\\CurrentControlSet\\\\Control\\\\Terminal Server' -Name 'fDenyTSConnections' -Value 0; Set-ItemProperty -Path 'HKLM:\\\\System\\\\CurrentControlSet\\\\Control\\\\Terminal Server\\\\WinStations\\\\RDP-Tcp' -Name 'UserAuthentication' -Value 0; Restart-Service -Name TermService -Force;\""    }
SETTINGS
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh_addc,
  ]
}

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
      timeout         = "10m"
    }
  }
  depends_on = [
    azurerm_virtual_machine_extension.allow_remote_addc,
  ]
}

# Execute the setup domain script on the first Active Directory Domain Controller VM
resource "azurerm_virtual_machine_extension" "setup_domain_exec" {
  name                       = "SetupDomain"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomain.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
    }
  SETTINGS
  depends_on = [
    null_resource.setup_domain_copy,
  ]
}

# Restart the first Active Directory Domain Controller VM after domain promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart" {
  name               = "RestartCommand"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    azurerm_virtual_machine_extension.setup_domain_exec,
  ]
}

# Wait for the VM to restart after domain promotion
resource "time_sleep" "addc_vm_restart_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart,
  ]
}

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
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait,
  ]
}

# Execute the setup domain controller script on the second Active Directory Domain Controller VM
resource "azurerm_virtual_machine_extension" "setup_domain_controller_exec" {
  name                       = "SetupDomainController"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[1].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Install-AdDomainController.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
    }
  SETTINGS
  depends_on = [
    null_resource.setup_domain_controller_copy,
  ]
}

# Restart the second Active Directory Domain Controller VM after promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart_second" {
  name               = "RestartCommand"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    azurerm_virtual_machine_extension.setup_domain_controller_exec,
  ]
}

# Wait for the second VM to restart after domain controller promotion
resource "time_sleep" "addc_vm_restart_wait_second" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart_second
  ]
}

# Copy Add-SqlAcl.ps1 script to the first Active Directory Domain Controller VM
resource "null_resource" "add_sqlacl_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-SqlAcl.ps1"
    destination = "c:\\SqlAcl.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
}

# Copy Add-DomainAccounts.ps1 script to the first Active Directory Domain Controller VM
resource "null_resource" "add_domain_accounts_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-DomainAccounts.ps1"
    destination = "c:\\Add-DomainAccounts.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
}

# Execute the setup domain script on the first Active Directory Domain Controller VM
resource "azurerm_virtual_machine_extension" "add_domain_accounts_exec" {
  name                       = "DomainAccounts"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-DomainAccounts.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_svc_acct_pswd ${var.sql_svc_acct_pswd}"
    }
  SETTINGS
  depends_on = [
    null_resource.add_domain_accounts_copy,
  ]
}

########## OUTPUT EXAMPLES ##########
output "vm_addc" {
  value = {
    for i in range(length(azurerm_windows_virtual_machine.addc_vm)) : i => {
      pip  = azurerm_public_ip.addc_public_ip[i].ip_address
      name = azurerm_windows_virtual_machine.addc_vm[i].computer_name
    }
  }
}

