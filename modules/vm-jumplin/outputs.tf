#################### VM-JUMPLIN ####################
output "vm_jumplin_public_name" {
  value = azurerm_public_ip.vm_jumplin_pip.fqdn
}

output "vm_jumplin_public_ip" {
  value = azurerm_public_ip.vm_jumplin_pip.ip_address
}
