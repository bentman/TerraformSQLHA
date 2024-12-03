# .\modules\vm-sql\main.tf
#################### MAIN ####################
########## CREATE LOAD BALANCERS FOR SQLHA ##########
# Create Load Balancer in each region
resource "azurerm_lb" "sqlha_lb" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-lb"
  location            = var.regions[count.index]
  resource_group_name = var.resource_group_names[count.index]
  sku                 = "Standard"
  tags                = var.tags
  frontend_ip_configuration {
    name                          = "${var.shortregions[count.index]}-sqlha-frontend"
    subnet_id                     = var.subnet_ids[count.index]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_cidrs[count.index], 5)
    zones                         = null
  }
}

# Health probe for SQLHA Load Balancer
resource "azurerm_lb_probe" "sqlha_probe" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-probe"
  loadbalancer_id     = azurerm_lb.sqlha_lb[count.index].id
  protocol            = "Tcp"
  port                = 5999
  interval_in_seconds = 5
  number_of_probes    = 3 # Increased for better reliability
}

# Load Balancer rule for SQL listener
resource "azurerm_lb_rule" "sqlha_lb_rule" {
  count                          = length(var.regions)
  name                           = "${var.shortregions[count.index]}-sqlha-rule"
  loadbalancer_id                = azurerm_lb.sqlha_lb[count.index].id
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "${var.shortregions[count.index]}-sqlha-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.sqlha_backend_pool[count.index].id]
  probe_id                       = azurerm_lb_probe.sqlha_probe[count.index].id
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 4
  enable_tcp_reset               = true
}

# Backend address pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "sqlha_backend_pool" {
  count           = length(var.regions)
  name            = "${var.shortregions[count.index]}-sqlha-backend-pool"
  loadbalancer_id = azurerm_lb.sqlha_lb[count.index].id
}

########## CREATE STORAGE FOR SQLHA ##########
# Storage account for cloud SQL witness
resource "azurerm_storage_account" "sqlha_witness" {
  count                      = length(var.regions)
  name                       = lower("${var.shortregions[count.index]}sqlwitness")
  location                   = var.regions[count.index]
  resource_group_name        = var.resource_group_names[count.index]
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  tags                       = var.tags
  depends_on = [
    azurerm_lb.sqlha_lb,
  ]
}

# Blob container for cloud SQL quorum
resource "azurerm_storage_container" "sqlha_quorum" {
  count                 = length(var.regions)
  name                  = lower("${var.shortregions[count.index]}sqlquorum")
  storage_account_id    = azurerm_storage_account.sqlha_witness[count.index].id
  container_access_type = "private"
}

########## CREATE SQL NODES FOR SQLHA ##########
# Public IPs for SQLHA
resource "azurerm_public_ip" "sqlha_public_ip" {
  for_each            = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                = lower("${each.value.region}-sqlha${each.value.index}-public-ip")
  location            = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name = var.resource_group_names[index(var.shortregions, each.value.region)]
  zones               = ["1"]
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
  depends_on = [
    azurerm_storage_container.sqlha_quorum,
  ]
}

# Network Interfaces for SQLHA
resource "azurerm_network_interface" "sqlha_nic" {
  for_each            = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                = lower("${each.value.region}-sqlha${each.value.index}-nic")
  location            = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name = var.resource_group_names[index(var.shortregions, each.value.region)]
  tags                = var.tags
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[index(var.shortregions, each.value.region)]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_cidrs[index(var.shortregions, each.value.region)], each.value.index == 0 ? 8 : 9)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.sqlha_public_ip[each.key].id
  }
  dns_servers = var.domain_dns_servers
  depends_on = [
    azurerm_public_ip.sqlha_public_ip,
  ]
}

# SQLHA Virtual Machines
resource "azurerm_windows_virtual_machine" "sqlha_vm" {
  for_each            = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                = lower("${each.value.region}-sqlha${each.value.index}-vm")
  computer_name       = upper("${each.value.region}-sqlha${each.value.index}")
  resource_group_name = var.resource_group_names[index(var.shortregions, each.value.region)]
  location            = var.regions[index(var.shortregions, each.value.region)]
  zone                = "1"
  size                = var.vm_sqlha_size
  admin_username      = var.sql_localadmin_user
  admin_password      = var.sql_localadmin_pswd
  tags                = var.tags
  network_interface_ids = [
    azurerm_network_interface.sqlha_nic[each.key].id
  ]
  os_disk {
    name                 = lower("${each.value.region}-sqlha${each.value.index}-os-disk")
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 127
  }
  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2022"
    sku       = "Enterprise"
    version   = "latest"
  }
  winrm_listener {
    protocol = "Http"
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_network_interface.sqlha_nic,
  ]
}

########## SQL MANAGED DISKS ##########
# Create Disks (DATA, LOGS, TEMP)
resource "azurerm_managed_disk" "sqlha_data" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-data-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = var.resource_group_names[index(var.shortregions, each.value.region)]
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 90
  tags                 = var.tags
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

resource "azurerm_managed_disk" "sqlha_logs" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-logs-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = var.resource_group_names[index(var.shortregions, each.value.region)]
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 60
  tags                 = var.tags
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

resource "azurerm_managed_disk" "sqlha_temp" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-temp-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = var.resource_group_names[index(var.shortregions, each.value.region)]
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  tags                 = var.tags
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

# Attach Disks (DATA, LOGS, TEMP)
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_data_attach" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  managed_disk_id    = azurerm_managed_disk.sqlha_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_logs_attach" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  managed_disk_id    = azurerm_managed_disk.sqlha_logs[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  lun                = 1
  caching            = "ReadOnly"
}

# SQL Disk Attachments
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_temp_attach" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  managed_disk_id    = azurerm_managed_disk.sqlha_temp[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  lun                = 2
  caching            = "None"
}

########## INSTALL OPENSSH ON SQLHA VIRTUAL MACHINES ##########
resource "azurerm_virtual_machine_extension" "install_openssh_sql" {
  for_each                   = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                       = "${each.value.region}-InstallOpenSSH-sqlha${each.value.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

# Wait for sql ssh to settle
resource "time_sleep" "install_openssh_sql_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh_sql,
  ]
}

########## COPY SQL VM SCRIPTS
# Copy SqlLocalAdmins script to each SQL VM
resource "null_resource" "add_sqllocaladmins_copy" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "file" {
    source      = "${path.module}/Add-SqlLocalAdmins.ps1"
    destination = "c:\\Add-SqlLocalAdmins.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = var.addc_pip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.install_openssh_sql_wait,
  ]
}

# Copy SqlSysAdmins script to each SQL VM
resource "null_resource" "add_sqlsysadmins_copy" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "file" {
    source      = "${path.module}/Add-SqlSysAdmins.ps1"
    destination = "c:\\Add-SqlSysAdmins.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = var.addc_pip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    null_resource.add_sqllocaladmins_copy,
  ]
}

# Copy Domain Join Script
resource "null_resource" "sql_domainjoin_script_copy" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "file" {
    source      = "${path.module}/Add-SqlDomainJoin.ps1"
    destination = "C:\\Add-SqlDomainJoin.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[each.key].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    null_resource.add_sqlsysadmins_copy,
  ]
}

########## DOMAIN JOIN SQL VM
# Execute Domain Join Script
resource "azurerm_virtual_machine_run_command" "sql_domainjoin_exec" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name               = "${each.value.region}-SqlDomainJoin${each.value.index}"
  location           = var.regions[index(var.shortregions, each.value.region)]
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlDomainJoin.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
  }
  depends_on = [
    null_resource.sql_domainjoin_script_copy,
  ]
}

# Wait for SQLHA VMs After Domain Join
resource "time_sleep" "sqlha_domainjoin_script_wait" {
  create_duration = "3m"
  depends_on = [
    azurerm_virtual_machine_run_command.sql_domainjoin_exec,
  ]
}

########## Restart SQLHA after Domain Join & Disks
resource "azurerm_virtual_machine_run_command" "sqlha_domainjoin_restart" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name               = "${each.value.region}-SqlRestartCommand${each.value.index}"
  location           = var.regions[index(var.shortregions, each.value.region)]
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.sqlha_domainjoin_script_wait,
    azurerm_virtual_machine_data_disk_attachment.sqlha_data_attach,
    azurerm_virtual_machine_data_disk_attachment.sqlha_logs_attach,
    azurerm_virtual_machine_data_disk_attachment.sqlha_temp_attach,
  ]
}

# Wait After SQLHA VM Restart
resource "time_sleep" "sqlha_domainjoin_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.sqlha_domainjoin_restart,
  ]
}

########## ASSOCIATE SQL SERVERS TO LOAD BALANCER BACKEND POOL
resource "azurerm_network_interface_backend_address_pool_association" "sqlha_nic_lb_association" {
  for_each                = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  network_interface_id    = azurerm_network_interface.sqlha_nic[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlha_backend_pool[floor(index(var.shortregions, each.value.region) / 1)].id
  depends_on = [
    time_sleep.sqlha_domainjoin_wait,
  ]
}

########## EXECUTE SQL SCRIPTS
# Execute SqlLocalAdmins script
resource "null_resource" "add_sqllocaladmins_exec" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[each.key].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlLocalAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user}"
    ]
  }
  depends_on = [
    azurerm_network_interface_backend_address_pool_association.sqlha_nic_lb_association,
  ]
}

# Execute SqlDomainAccounts script
resource "null_resource" "add_sqldomainaccounts_exec" {
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = var.addc_pip_address
      target_platform = "windows"
      timeout         = "10m"
    }
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlDomainAccounts.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_svc_acct_pswd ${var.sql_svc_acct_pswd}"
    ]
  }
  depends_on = [
    null_resource.add_sqllocaladmins_exec,
  ]
}

########## CREATE VIRTUAL MACHINE GROUP IN EACH REGION
resource "azurerm_mssql_virtual_machine_group" "sqlha_vmg" {
  for_each = { for idx, region in var.shortregions : region => idx }

  name                = lower("${each.key}-sqlhavmg")
  location            = var.regions[each.value]
  resource_group_name = var.resource_group_names[each.value]
  sql_image_offer     = var.sql_image_offer
  sql_image_sku       = var.sql_image_sku
  tags                = var.tags
  wsfc_domain_profile {
    fqdn                           = var.domain_name
    cluster_subnet_type            = "MultiSubnet"
    cluster_bootstrap_account_name = "sqlinstall@${var.domain_name}"
    cluster_operator_account_name  = "sqlinstall@${var.domain_name}"
    sql_service_account_name       = "${var.sql_svc_acct_user}@${var.domain_name}"
    organizational_unit_path       = local.servers_ou_path
    storage_account_url            = azurerm_storage_account.sqlha_witness[each.value].primary_blob_endpoint
    storage_account_primary_key    = azurerm_storage_account.sqlha_witness[each.value].primary_access_key
  }
  depends_on = [
    azurerm_network_interface_backend_address_pool_association.sqlha_nic_lb_association,
  ]
}

resource "time_sleep" "sqlha_vmg_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_mssql_virtual_machine_group.sqlha_vmg,
  ]
}

########## CREATE MSSQL VIRTUAL MACHINE FOR EACH SQL SERVER
resource "azurerm_mssql_virtual_machine" "az_sqlha" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }

  virtual_machine_id           = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.sqlha_vmg[each.value.region].id
  sql_license_type             = "PAYG"
  r_services_enabled           = false
  sql_connectivity_port        = 1433
  sql_connectivity_type        = "PRIVATE"
  tags                         = var.tags
  wsfc_domain_credential {
    cluster_bootstrap_account_password = var.sql_svc_acct_pswd
    cluster_operator_account_password  = var.sql_svc_acct_pswd
    sql_service_account_password       = var.sql_svc_acct_pswd
  }
  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"
    data_settings {
      default_file_path = var.sqldatafilepath
      luns              = [0]
    }
    log_settings {
      default_file_path = var.sqllogfilepath
      luns              = [1]
    }
    temp_db_settings {
      default_file_path = var.sqltempfilepath
      luns              = [2]
    }
  }
  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }
  depends_on = [
    time_sleep.sqlha_vmg_wait,
  ]
}

resource "time_sleep" "sqlha_mssqlvm_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}

########## SET ACLS FOR VMG ACCESS OVER THE SERVERS OU ##########
resource "null_resource" "add_sql_acl_clusters" {
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = var.addc_pip_address
      target_platform = "windows"
      timeout         = "10m"
    }
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlAcl.ps1 -domain_name ${var.domain_name} -sqlcluster_region1 ${azurerm_mssql_virtual_machine_group.sqlha_vmg[0].name} -sqlcluster_region2 ${azurerm_mssql_virtual_machine_group.sqlha_vmg[1].name}"
    ]
  }
  depends_on = [
    time_sleep.sqlha_mssqlvm_wait,
  ]
}

########## Execute SqlSysAdmins script
resource "null_resource" "add_sqlsysadmins_exec" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[each.key].ip_address
      target_platform = "windows"
      timeout         = "5m"
    }
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlSysAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_sysadmin_user ${var.sql_sysadmin_user} -sql_sysadmin_pswd ${var.sql_sysadmin_pswd}"
    ]
  }
  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}
