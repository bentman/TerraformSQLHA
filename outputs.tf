# .\outputs.tf
#################### OUTPUTS ####################
########## RESOURCE GROUP OUTPUTS 
# Output for Resource Group names and their locations
output "resource_groups" {
  description = "Map of resource group names to their regions"
  value       = { for rg in azurerm_resource_group.rg : rg.name => rg.location }
}

########## V-NETWORK OUTPUTS 
# Output for VNet names and addresses for each region
output "net_names_address_spaces" {
  description = "Map of VNet names to their address spaces"
  value       = { for vnet in azurerm_virtual_network.vnet : vnet.name => vnet.address_space }
}

# Output for Subnet names and CIDRs
output "net_subnet_names_cidrs" {
  description = "Map of Subnet names to their CIDR blocks"
  value = merge(
    { for subnet in azurerm_subnet.snet_gw : subnet.name => subnet.address_prefixes[0] },
    { for subnet in azurerm_subnet.snet_dc : subnet.name => subnet.address_prefixes[0] },
    { for subnet in azurerm_subnet.snet_db : subnet.name => subnet.address_prefixes[0] },
    { for subnet in azurerm_subnet.snet_app : subnet.name => subnet.address_prefixes[0] },
    { for subnet in azurerm_subnet.snet_end : subnet.name => subnet.address_prefixes[0] },
    { for subnet in azurerm_subnet.snet_pub : subnet.name => subnet.address_prefixes[0] }
  )
}

########## VM-JUMPWIN OUTPUTS 
output "vm_jumpwin_public_name" {
  description = "Public DNS name of Windows jumpbox VM, if exists - 'null' if not"
  value       = length(module.vm_jumpwin) > 0 ? module.vm_jumpwin[0].vm_jumpwin_public_name : null
}

output "vm_jumpwin_public_ip" {
  description = "Public IP address of Windows jumpbox VM, if exists - 'null' if not"
  value       = length(module.vm_jumpwin) > 0 ? module.vm_jumpwin[0].vm_jumpwin_public_ip : null
}

########## VM-JUMPLIN OUTPUTS 
output "vm_jumplin_public_name" {
  description = "Public DNS name of Windows jumpbox VM, if exists - 'null' if not"
  value       = length(module.vm_jumplin) > 0 ? module.vm_jumplin[0].vm_jumplin_public_name : null
}

output "vm_jumplin_public_ip" {
  description = "Public IP address of Windows jumpbox VM, if exists - 'null' if not"
  value       = length(module.vm_jumplin) > 0 ? module.vm_jumplin[0].vm_jumplin_public_ip : null
}

########## VM-ADDC OUTPUTS 
output "vm_addc_ip_public_name" {
  description = "Map of ADDC public IP addresses to their DNS hostnames from the vm_addc module"
  value       = length(module.vm_addc) > 0 ? module.vm_addc[0].addc_public_ip_dns_map : null
}

########## VM-SQL OUTPUTS 
# Output for SQL HA Public IP and DNS mapping
output "vm_sql_ip_public_name" {
  description = "Map of SQL HA public IP addresses to their DNS hostnames from the sql_ha module"
  value       = length(module.sql_ha) > 0 ? module.sql_ha[0].sqlha_public_ip_dns_map : null
}

########## Module Summary 
output "z_modules_summary" {
  description = "Summary of enabled VM modules and their public IPs"
  value = {
    jumpwin = length(module.vm_jumpwin) > 0 ? module.vm_jumpwin[0].vm_jumpwin_public_ip : null,
    jumplin = length(module.vm_jumplin) > 0 ? module.vm_jumplin[0].vm_jumplin_public_ip : null,
    addc    = length(module.vm_addc) > 0 ? module.vm_addc[0].addc_public_ip_dns_map : null,
    sql_ha  = length(module.sql_ha) > 0 ? module.sql_ha[0].sqlha_public_ip_dns_map : null
  }
}
