# .\modules\vm-sql\outputs.tf
#################### VM-ADDC OUTPUTS ####################
output "sqlha_public_ip_dns_map" {
  description = "Map of SQL HA public IP addresses to their DNS hostnames"
  value = {
    for ip in azurerm_public_ip.sqlha_public_ip :
    ip.id => {
      ip_address = ip.ip_address
      dns_name   = ip.fqdn
    }
  }
}
