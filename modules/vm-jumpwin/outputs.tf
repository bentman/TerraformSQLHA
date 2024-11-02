# .\modules\vm-jumpwin\outputs.tf
#################### VM-JUMPWIN ####################
output "vm_jumpwin_public_name" {
  value = azurerm_public_ip.vm_jumpwin_pip.fqdn
}

output "vm_jumpwin_public_ip" {
  value = azurerm_public_ip.vm_jumpwin_pip.ip_address
}
