#################### MAIN ####################
# Resource Group for multi-region lab setup
resource "azurerm_resource_group" "rg" {
  name     = lower("rg-multiregion-sqlha")
  location = var.regions[0]
  tags     = var.labtags
}

# Set timezone for VMs in vm timezone
resource "azurerm_virtual_machine_run_command" "set_windows_timezone" {
  for_each = { for k, v in local.vm_configs : k => v if v.os_type == "windows" }

  name               = "SetTimeZone-${each.key}"
  location           = each.value.location
  virtual_machine_id = each.value.id

  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command \\\"Set-TimeZone -Name '${local.region_tz_map[each.value.location].windows}' -Confirm:\\$false\\\""
  }
  depends_on = [
    time_sleep.sqlha_sqlacl_wait,
  ]
}

# Enable dev/test shutdown schedule for all ADDC VMs (after vm-sqhla.tf)
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
    azurerm_virtual_machine_run_command.set_windows_timezone,
  ]
}

# Enable dev/test shutdown schedule for all SQLHA VMs (after vm-sqlha.tf)
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
    azurerm_virtual_machine_run_command.set_windows_timezone,
  ]
}
