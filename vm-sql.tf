########## CREATE SQL SERVERS FOR SQLHA ##########
# Public IPs for SQLHA in both regions
resource "azurerm_public_ip" "sqlha_public_ip" {
  count               = length(var.regions) * 2
  name                = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-public-ip"
  location            = var.regions[floor(count.index / 2)]
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.labtags
}

# Network Interfaces for SQLHA in both regions
resource "azurerm_network_interface" "sqlha_nic" {
  count                          = length(var.regions) * 2
  name                           = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-nic"
  location                       = var.regions[floor(count.index / 2)]
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true
  tags                           = var.labtags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_db[floor(count.index / 2)].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_db[floor(count.index / 2)].address_prefixes[0], count.index % 2 == 0 ? 9 : 10)
    public_ip_address_id          = azurerm_public_ip.sqlha_public_ip[count.index].id
  }

  dns_servers = [
    azurerm_network_interface.addc_nic[floor(count.index / 2)].ip_configuration[0].private_ip_address,
    "1.1.1.1",
    "8.8.8.8"
  ]
}

# SQLHA Virtual Machines in both regions
resource "azurerm_windows_virtual_machine" "sqlha_vm" {
  count                 = length(var.regions) * 2
  name                  = lower("${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-vm")
  computer_name         = upper("${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}")
  location              = var.regions[floor(count.index / 2)]
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.sqlha_nic[count.index].id]
  admin_username        = var.domain_admin_user
  admin_password        = var.domain_admin_pswd
  size                  = "Standard_D2s_v3"
  tags                  = var.labtags

  os_disk {
    name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2022"
    sku       = "Enterprise"
    version   = "latest"
  }
}

# Install OpenSSH on SQLHA Virtual Machines
resource "azurerm_virtual_machine_extension" "install_openssh" {
  count                      = length(var.regions) * 2
  name                       = "InstallOpenSSH"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -Command Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0; Start-Service sshd; Set-Service -Name sshd -StartupType 'Automatic'"
  })

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

# File provisioner for SQL scripts
resource "null_resource" "sql_script_copy" {
  count = length(azurerm_windows_virtual_machine.sqlha_vm)
  provisioner "file" {
    source      = "${path.module}/Add-SqlSysAdmins.ps1"
    destination = "C:\\Add-SqlSysAdmins.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
      target_platform = "windows"
      timeout         = "3m"
    }
  }
  provisioner "file" {
    source      = "${path.module}/Add-SqlLocalAdmins.ps1"
    destination = "C:\\Add-SqlLocalAdmins.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
      target_platform = "windows"
      timeout         = "3m"
    }
  }
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh,
  ]
}

# Data disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_data" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-data-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 90
  tags                 = var.labtags
}

# Log disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_logs" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-log-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 60
  tags                 = var.labtags
}

# TempDB disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_temp" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-temp-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  tags                 = var.labtags
}

# Data Disk Attachments for SQLHA VMs
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_attachments" {
  count = length(var.regions) * 2 * 3
  managed_disk_id = (
    count.index % 3 == 0 ? azurerm_managed_disk.sqlha_data[floor(count.index / 3)].id :
    count.index % 3 == 1 ? azurerm_managed_disk.sqlha_logs[floor(count.index / 3)].id :
    azurerm_managed_disk.sqlha_temp[floor(count.index / 3)].id
  )
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[floor(count.index / 3)].id
  lun                = count.index % 3
  caching            = count.index % 3 == 0 ? "ReadWrite" : count.index % 3 == 1 ? "ReadOnly" : "None"
}

# Domain join SQLHA nodes
resource "azurerm_virtual_machine_extension" "sqlha_domainjoin" {
  count                      = length(var.regions) * 2
  name                       = "DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = local.servers_ou_path
    User    = "${var.domain_netbios_name}\\${var.domain_admin_user}"
    Restart = "false"
    Options = "3"
  })
  protected_settings = jsonencode({
    Password = var.domain_admin_pswd
  })
  depends_on = [
    null_resource.sql_script_copy,
    azurerm_virtual_machine_data_disk_attachment.sqlha_attachments
  ]
}

# Restart the second Active Directory Domain Controller VM after promotion
resource "azurerm_virtual_machine_run_command" "sqlha_domainjoin_restart" {
  name               = "RestartCommand"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    azurerm_virtual_machine_extension.sqlha_domainjoin,
  ]
}

# Wait for the second VM to restart after domain controller promotion
resource "time_sleep" "sqlha_domainjoin_wait" {
  create_duration = "5m"
  depends_on = [
    azurerm_virtual_machine_run_command.sqlha_domainjoin_restart,
  ]
}

# Add local admins to SQL Servers
resource "azurerm_virtual_machine_extension" "add_sqllocaladmins_exec" {
  count                      = length(var.regions) * 2
  name                       = "SqlLocalAdmin-${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlLocalAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user}"
    }
  SETTINGS

  depends_on = [
    time_sleep.sqlha_domainjoin_wait,
  ]
}

# Add SQL sysadmins to SQL Servers
resource "azurerm_virtual_machine_extension" "add_sqlsysadmins_exec" {
  count                      = length(var.regions) * 2
  name                       = "SqlSysAdmins-${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlSysAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_svc_acct_pswd ${var.sql_svc_acct_pswd}"
    }
  SETTINGS
  depends_on = [
    azurerm_virtual_machine_extension.add_sqllocaladmins_exec,
  ]
}

# Wait for localadmin & sysadmin script (& set depends_on flag ;-))
resource "time_sleep" "sqlha_final_wait" {
  create_duration = "1m"
  depends_on = [
    azurerm_virtual_machine_extension.add_sqlsysadmins_exec,
  ]
}
