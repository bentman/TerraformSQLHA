# .\data.tf
#################### DATA SOURCES ####################
# Retrieve the Public IP information for the 1st Active Directory Domain Controller (ADDC)
# This data source fetches details of a public IP address by its name and resource group.
# The ADDC Public IP is referenced by other resources for connectivity and management purposes.
/*data "azurerm_public_ip" "addc_public_ip" {
  name                = "${var.shortregions[0]}-addc-pip" # Name of the Public IP for the ADDC in the primary region
  resource_group_name = azurerm_resource_group.rg[0].name # Resource Group in which the ADDC Public IP resides
}*/
