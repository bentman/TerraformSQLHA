#################### MAIN ####################
# Resource Group for multi-region lab setup
resource "azurerm_resource_group" "rg" {
  name     = "rg-multiregion-sqlha"
  location = var.regions[0]
  tags     = var.labtags
}

# Enable dev/test shutdown schedule for all ADDC VMs
resource "azurerm_dev_test_global_vm_shutdown_schedule" "addc_vm_shutdown" {
  count                 = length(azurerm_windows_virtual_machine.addc_vm)
  virtual_machine_id    = azurerm_windows_virtual_machine.addc_vm[count.index].id
  location              = azurerm_windows_virtual_machine.addc_vm[count.index].location
  enabled               = true
  daily_recurrence_time = var.vm_shutdown_hhmm
  timezone              = var.vm_shutdown_tz
  notification_settings {
    enabled = false
  }
  depends_on = [
    time_sleep.sqlha_sqlacl_wait,
  ]
}

# Set VM timezone for all ADDC VMs
resource "azurerm_virtual_machine_run_command" "set_timezone_addc_vm" {
  count              = length(azurerm_windows_virtual_machine.addc_vm)
  name               = "SetTimeZone-ADDC-${count.index}"
  location           = azurerm_windows_virtual_machine.addc_vm[count.index].location
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[count.index].id
  source {
    script = "Set-TimeZone -Name '${var.vm_shutdown_tz}' -Confirm:\\$false"
  }
  depends_on = [
    azurerm_dev_test_global_vm_shutdown_schedule.addc_vm_shutdown,
  ]
}

# Enable dev/test shutdown schedule for all SQLHA VMs
resource "azurerm_dev_test_global_vm_shutdown_schedule" "sqlha_vm_shutdown" {
  count                 = length(azurerm_windows_virtual_machine.sqlha_vm)
  virtual_machine_id    = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  location              = azurerm_windows_virtual_machine.sqlha_vm[count.index].location
  enabled               = true
  daily_recurrence_time = var.vm_shutdown_hhmm
  timezone              = var.vm_shutdown_tz
  notification_settings {
    enabled = false
  }
  depends_on = [
    time_sleep.sqlha_sqlacl_wait,
  ]
}

# Set VM timezone for all SQLHA VMs
resource "azurerm_virtual_machine_run_command" "set_timezone_sqlha_vm" {
  count              = length(azurerm_windows_virtual_machine.sqlha_vm)
  name               = "SetTimeZone-SQLHA-${count.index}"
  location           = azurerm_windows_virtual_machine.sqlha_vm[count.index].location
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  source {
    script = "Set-TimeZone -Name '${var.vm_shutdown_tz}' -Confirm:\\$false"
  }
  depends_on = [
    azurerm_dev_test_global_vm_shutdown_schedule.sqlha_vm_shutdown,
  ]
}
