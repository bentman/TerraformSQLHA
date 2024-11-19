# .\main.tf
#################### RESOURCE GROUPS ####################
# Create resource groups for each region specified in the 'regions' variable
resource "azurerm_resource_group" "rg" {
  count    = length(var.regions)
  name     = lower("rg-multiregion-${var.shortregions[count.index]}")
  location = var.regions[count.index]
  tags     = var.labtags
}

#################### V-NETWORK MODULE ####################
# Create Virtual Networks and associated subnets across specified regions
resource "azurerm_virtual_network" "vnet" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-vnet"
  address_space       = [var.address_spaces[count.index]]
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  tags                = var.labtags
  depends_on          = [azurerm_resource_group.rg]
}

#################### VIRTUAL NETWORK PEERING ####################
# Enable peering between VNets in different regions for cross-region traffic
resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each = local.vnet_peerings

  name                         = each.value.name
  resource_group_name          = azurerm_resource_group.rg[each.value.src_index].name
  virtual_network_name         = azurerm_virtual_network.vnet[each.value.src_index].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[each.value.dst_index].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on                   = [azurerm_virtual_network.vnet]
}

#################### VIRTUAL NETWORK SUBNETS ####################
# Gateway Subnet
resource "azurerm_subnet" "snet_gw" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-gw"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 0)]
  depends_on           = [azurerm_virtual_network.vnet]
}

# Domain Controller Subnet
resource "azurerm_subnet" "snet_dc" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-dc"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 1)]
  depends_on           = [azurerm_subnet.snet_gw]
}

# Database Subnet
resource "azurerm_subnet" "snet_db" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-db"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 2)]
  depends_on           = [azurerm_subnet.snet_dc]
}

# Application Subnet
resource "azurerm_subnet" "snet_app" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-app"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 3)]
  depends_on           = [azurerm_subnet.snet_db]
}

# Endpoint Subnet
resource "azurerm_subnet" "snet_end" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-end"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 4)]
  depends_on           = [azurerm_subnet.snet_app]
}

# Public Subnet for externally accessible resources
resource "azurerm_subnet" "snet_pub" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-pub"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 5)]
  depends_on           = [azurerm_subnet.snet_end]
}

#################### NETWORK SECURITY GROUPS ####################
# Create Network Security Groups (NSG) for controlling traffic to VMs
resource "azurerm_network_security_group" "nsg" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-nsg"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  tags                = var.labtags
  depends_on          = [azurerm_subnet.snet_pub]

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-VNET-Traffic"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

# Associate NSGs with respective subnets for traffic control
resource "azurerm_subnet_network_security_group_association" "snet_gw_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_gw[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_network_security_group.nsg]
}

resource "azurerm_subnet_network_security_group_association" "snet_dc_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_dc[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_subnet_network_security_group_association.snet_gw_nsg_assoc]
}

resource "azurerm_subnet_network_security_group_association" "snet_db_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_db[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_subnet_network_security_group_association.snet_dc_nsg_assoc]
}

resource "azurerm_subnet_network_security_group_association" "snet_app_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_app[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_subnet_network_security_group_association.snet_db_nsg_assoc]
}

resource "azurerm_subnet_network_security_group_association" "snet_end_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_end[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_subnet_network_security_group_association.snet_app_nsg_assoc]
}

resource "azurerm_subnet_network_security_group_association" "snet_pub_nsg_assoc" {
  count                     = length(var.regions)
  subnet_id                 = azurerm_subnet.snet_pub[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
  depends_on                = [azurerm_subnet_network_security_group_association.snet_end_nsg_assoc]
}

#################### VM JUMPWIN MODULE ####################
# VM Jumpbox for Windows (Administrative access with RDP & OpenSSH)
module "vm_jumpwin" {
  count               = var.enable_vm_jumpwin ? 1 : 0
  source              = "./modules/vm-jumpwin"
  resource_group_name = azurerm_resource_group.rg[0].name
  location            = var.regions[0]
  shortregion         = var.shortregions[0]
  subnet_id           = azurerm_subnet.snet_gw[0].id
  subnet_cidr         = azurerm_subnet.snet_gw[0].address_prefixes
  vm_size             = var.vm_jump_size
  sku                 = var.vm_jumpwin_sku
  computer_name       = var.vm_jumpwin_hostname
  admin_username      = var.vm_jump_adminuser
  admin_password      = var.vm_jump_adminpswd
  vm_shutdown_hhmm    = var.vm_shutdown_hhmm
  vm_shutdown_tz      = var.vm_shutdown_tz
  tags                = var.labtags
  depends_on = [
    azurerm_subnet_network_security_group_association.snet_pub_nsg_assoc,
  ]
}

#################### VM JUMPLIN MODULE ####################
# VM Jumpbox for Windows (Administrative access with OpenSSH)
module "vm_jumplin" {
  count               = var.enable_vm_jumplin ? 1 : 0
  source              = "./modules/vm-jumplin"
  resource_group_name = azurerm_resource_group.rg[0].name
  location            = var.regions[0]
  shortregion         = var.shortregions[0]
  subnet_id           = azurerm_subnet.snet_gw[0].id
  subnet_cidr         = azurerm_subnet.snet_gw[0].address_prefixes
  vm_size             = var.vm_jump_size
  sku                 = var.vm_jumplin_sku
  computer_name       = var.vm_jumplin_hostname
  admin_username      = var.vm_jump_adminuser
  admin_password      = var.vm_jump_adminpswd
  vm_shutdown_hhmm    = var.vm_shutdown_hhmm
  vm_shutdown_tz      = var.vm_shutdown_tz
  tags                = var.labtags
  depends_on = [
    azurerm_subnet_network_security_group_association.snet_pub_nsg_assoc,
  ]
}

#################### VM ADDC MODULE ####################
# Active Directory Domain Controller (ADDC) setup
module "vm_addc" {
  count                = var.enable_vm_addc ? 1 : 0
  source               = "./modules/vm-addc"
  resource_group_names = [for rg in azurerm_resource_group.rg : rg.name]
  regions              = var.regions
  shortregions         = var.shortregions
  subnet_ids           = [for subnet in azurerm_subnet.snet_dc : subnet.id]
  subnet_cidrs         = [for subnet in azurerm_subnet.snet_dc : subnet.address_prefixes[0]]
  vm_addc_size         = var.vm_addc_size
  domain_name          = var.domain_name
  domain_netbios_name  = var.domain_netbios_name
  domain_admin_user    = var.domain_admin_user
  domain_admin_pswd    = var.domain_admin_pswd
  safemode_admin_pswd  = var.safemode_admin_pswd
  temp_admin_pswd      = var.temp_admin_pswd
  tags                 = var.labtags
  domain_dns_servers   = local.domain_dns_servers
  depends_on = [
    azurerm_subnet_network_security_group_association.snet_dc_nsg_assoc,
  ]
}

##### MODULE SQL-HA
# SQL High-Availability Setup using WSFC
module "sql_ha" {
  count                = var.enable_vm_sql ? 1 : 0
  source               = "./modules/vm-sql"
  resource_group_names = [for rg in azurerm_resource_group.rg : rg.name]
  regions              = var.regions
  shortregions         = var.shortregions
  subnet_ids           = [for subnet in azurerm_subnet.snet_db : subnet.id]
  subnet_cidrs         = [for subnet in azurerm_subnet.snet_db : subnet.address_prefixes[0]]
  vm_sqlha_size        = var.vm_sqlha_size
  domain_name          = var.domain_name
  domain_netbios_name  = var.domain_netbios_name
  domain_admin_user    = var.domain_admin_user
  domain_admin_pswd    = var.domain_admin_pswd
  domain_dns_servers   = local.domain_dns_servers
  addc_pip_address     = data.azurerm_public_ip.addc_public_ip.ip_address
  sql_localadmin_user  = var.sql_localadmin_user
  sql_localadmin_pswd  = var.sql_localadmin_pswd
  sql_sysadmin_user    = var.sql_sysadmin_user
  sql_sysadmin_pswd    = var.sql_sysadmin_pswd
  sql_svc_acct_user    = var.sql_svc_acct_user
  sql_svc_acct_pswd    = var.sql_svc_acct_pswd
  tags                 = var.labtags
  depends_on = [
    module.vm_addc,
  ]
}
