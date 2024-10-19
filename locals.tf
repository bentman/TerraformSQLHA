#################### LOCALS ####################
locals {
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"

  # Comprehensive timezone mapping for all Azure regions
  region_tz_map = {
    eastus = {
      windows = "Eastern Standard Time"
      linux   = "America/New_York"
      state   = "Virginia"
    }
    eastus2 = {
      windows = "Eastern Standard Time"
      linux   = "America/New_York"
      state   = "Virginia"
    }
    centralus = {
      windows = "Central Standard Time"
      linux   = "America/Chicago"
      state   = "Iowa"
    }
    northcentralus = {
      windows = "Central Standard Time"
      linux   = "America/Chicago"
      state   = "Illinois"
    }
    southcentralus = {
      windows = "Central Standard Time"
      linux   = "America/Chicago"
      state   = "Texas"
    }
    westus = {
      windows = "Pacific Standard Time"
      linux   = "America/Los_Angeles"
      state   = "California"
    }
    westus2 = {
      windows = "Pacific Standard Time"
      linux   = "America/Los_Angeles"
      state   = "Washington"
    }
    westus3 = {
      windows = "Mountain Standard Time"
      linux   = "America/Phoenix"
      state   = "Arizona"
    }
  }

  # List all VMs and their configurations
  vm_configs = merge(
    {
      for vm in azurerm_windows_virtual_machine.addc_vm : vm.name => {
        id       = vm.id
        location = lower(vm.location)
        os_type  = "windows"
      }
    },
    {
      for vm in azurerm_windows_virtual_machine.sqlha_vm : vm.name => {
        id       = vm.id
        location = lower(vm.location)
        os_type  = "windows"
      }
    }
  )
}

