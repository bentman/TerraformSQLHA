
########## ASSOCIATE SQL SERVERS TO LOAD BALANCER BACKEND ##########
# Network interface backend address pool association for SQL VMs
resource "azurerm_network_interface_backend_address_pool_association" "sqlha_nic_lb_association" {
  count = length(azurerm_network_interface.sqlha_nic)

  network_interface_id    = azurerm_network_interface.sqlha_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlha_backend_pool[floor(count.index / 2)].id
  depends_on = [
    time_sleep.sqlha_final_wait,
  ]
}

########## CREATE SQL VIRTUAL MACHINE GROUPS FOR SQLHA ##########
resource "azurerm_mssql_virtual_machine_group" "sqlha_vmg" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-vmg"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg.name
  sql_image_offer     = var.sql_image_offer
  sql_image_sku       = var.sql_image_sku
  tags                = var.labtags
  wsfc_domain_profile {
    fqdn                           = var.domain_name
    cluster_subnet_type            = "MultiSubnet"
    cluster_bootstrap_account_name = "sqlinstall@${var.domain_name}"
    cluster_operator_account_name  = "sqlinstall@${var.domain_name}"
    sql_service_account_name       = "${var.sql_svc_acct_user}@${var.domain_name}"
    organizational_unit_path       = local.servers_ou_path
    storage_account_url            = azurerm_storage_account.sqlha_witness[count.index].primary_blob_endpoint
    storage_account_primary_key    = azurerm_storage_account.sqlha_witness[count.index].primary_access_key
  }
  depends_on = [
    azurerm_network_interface_backend_address_pool_association.sqlha_nic_lb_association,
  ]
}

# Wait for vmg creation (& set depends_on flag ;-))
resource "time_sleep" "sqlha_vmg_wait" {
  create_duration = "3m"
  depends_on = [
    azurerm_mssql_virtual_machine_group.sqlha_vmg,
  ]
}

########## CREATE AZURE MSSQL VIRTUAL MACHINES FOR SQL ##########
resource "azurerm_mssql_virtual_machine" "az_sqlha" {
  count                        = length(var.regions) * 2
  virtual_machine_id           = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.sqlha_vmg[floor(count.index / 2)].id
  sql_license_type             = "PAYG"
  r_services_enabled           = false
  sql_connectivity_port        = 1433
  sql_connectivity_type        = "PRIVATE"
  tags                         = var.labtags
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
      luns              = [0] # Using the first LUN for data
    }
    log_settings {
      default_file_path = var.sqllogfilepath
      luns              = [1] # Using the second LUN for logs
    }
    temp_db_settings {
      default_file_path = var.sqltempfilepath
      luns              = [2] # Using the third LUN for tempdb
    }
  }
  timeouts {
    create = "2h"
    update = "2h"
    delete = "2h"
  }
  depends_on = [
    time_sleep.sqlha_vmg_wait,
  ]
}

# Wait for vmg creation (& set depends_on flag ;-))
resource "time_sleep" "sqlha_mssqlvm_wait" {
  create_duration = "3m"
  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}

########## SET ACLS FOR VMG ACCESS OVER THE SERVERS OU ##########
resource "null_resource" "add_sql_acl_clusters" {
  count = length(var.regions)

  triggers = {
    cluster_name = azurerm_mssql_virtual_machine_group.sqlha_vmg[count.index].name
    sql_vms      = join(",", [for vm in azurerm_mssql_virtual_machine.az_sqlha : vm.virtual_machine_id])
  }

  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }

    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlAcl.ps1 -domain_name ${var.domain_name} -sqlcluster_name ${azurerm_mssql_virtual_machine_group.sqlha_vmg[count.index].name}"
    ]
  }

  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}

# Wait for vmg creation (& set depends_on flag ;-))
resource "time_sleep" "sqlha_sqlacl_wait" {
  create_duration = "3m"
  depends_on = [
    null_resource.add_sql_acl_clusters,
  ]
}

########## OUTPUT EXAMPLES ##########
output "sqlha_vmg" {
  value = {
    for i in range(length(azurerm_mssql_virtual_machine_group.sqlha_vmg)) : i => {
      name = azurerm_mssql_virtual_machine_group.sqlha_vmg[i].name
    }
  }
}
