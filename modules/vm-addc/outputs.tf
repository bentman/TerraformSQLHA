# .\modules\vm-addc\outputs.tf
#################### VM-ADDC OUTPUTS ####################
output "addc_public_ip_dns_map" {
  description = "Map of ADDC public IP addresses to their DNS hostnames"
  value = {
    for ip in azurerm_public_ip.addc_public_ip :
    ip.id => {
      ip_address = ip.ip_address
      dns_name   = ip.fqdn
    }
  }
}

output "first_addc_public_ip" {
  value = azurerm_public_ip.addc_public_ip[0].ip_address

  precondition {
    condition     = length(azurerm_public_ip.addc_public_ip) > 0
    error_message = "No public IP addresses have been created; ensure that 'azurerm_public_ip.addc_public_ip' has at least one instance."
  }
}

output "second_addc_public_ip" {
  value = azurerm_public_ip.addc_public_ip[1].ip_address

  precondition {
    condition     = length(azurerm_public_ip.addc_public_ip) > 1
    error_message = "No public IP addresses have been created; ensure that 'azurerm_public_ip.addc_public_ip' has at least one instance."
  }
}
