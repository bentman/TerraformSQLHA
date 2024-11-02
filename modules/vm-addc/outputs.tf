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
