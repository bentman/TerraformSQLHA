#################### VIRTUAL NETWORK (VNET) AND SUBNETS ####################
# Create Virtual Network (VNet) for each region specified in the variable 'regions'
resource "azurerm_virtual_network" "vnet" {
  for_each            = { for idx, reg in var.regions : idx => reg }
  name                = "${var.shortregions[each.key]}-vnet"
  location            = each.value
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_spaces[each.key]]
  tags                = var.labtags
}

# Create Gateway Subnet within each Virtual Network
resource "azurerm_subnet" "snet_gw" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 4, 0)]
}

# Create Active Directory Domain Controllers (ADDC) Subnet within each Virtual Network
resource "azurerm_subnet" "snet_addc" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-addc"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 1)]
}

# Create Database Subnet within each Virtual Network
resource "azurerm_subnet" "snet_db" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 2)]
}

# Create Application Subnet within each Virtual Network
resource "azurerm_subnet" "snet_app" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 3)]
}

# Create Client Subnet within each Virtual Network
resource "azurerm_subnet" "snet_client" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-client"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 4, 15)]
}

#################### PUBLIC IP AND NAT GATEWAY ####################
# Create Public IP for NAT Gateway in each region
resource "azurerm_public_ip" "gateway_ip" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-gateway-ip"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.labtags
}

# Create NAT Gateway in each region for outbound internet connectivity
resource "azurerm_nat_gateway" "nat_gateway" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-nat-gateway"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags
}

# Associate NAT Gateway with the Active Directory Domain Controllers (ADDC) Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_association" {
  for_each       = azurerm_subnet.snet_addc
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.key].id
  depends_on     = [azurerm_nat_gateway.nat_gateway]
}

#################### VIRTUAL NETWORK PEERING ####################
# Create VNet peering from the first region to the second region
resource "azurerm_virtual_network_peering" "peering1" {
  name                         = "${var.shortregions[0]}-peering-to-${var.shortregions[1]}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[1].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on                   = [azurerm_virtual_network.vnet]
}

# Create VNet peering from the second region to the first region
resource "azurerm_virtual_network_peering" "peering2" {
  name                         = "${var.shortregions[1]}-peering-to-${var.shortregions[0]}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet[1].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on                   = [azurerm_virtual_network.vnet]
}

#################### NETWORK SECURITY GROUP (NSG) FOR OPEN COMMUNICATION ####################
# Create Network Security Group (NSG) for each Virtual Network
resource "azurerm_network_security_group" "nsg_vnet" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-nsg-vnet"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags
}

# Allow communication between Virtual Networks for open communication
resource "azurerm_network_security_rule" "allow_vnet_communication" {
  for_each                        = azurerm_virtual_network.vnet
  name                            = "allow-vnet-communication"
  priority                        = 100
  direction                       = "Inbound"
  access                          = "Allow"
  protocol                        = "*"
  source_port_range               = "*"
  destination_port_range          = "*"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name             = azurerm_resource_group.rg.name
  network_security_group_name     = azurerm_network_security_group.nsg_vnet[each.key].name
}

# Allow RDP access (port 3389) from any source to all Virtual Machines
resource "azurerm_network_security_rule" "allow_rdp" {
  for_each                        = azurerm_virtual_network.vnet
  name                            = "allow-rdp"
  priority                        = 200
  direction                       = "Inbound"
  access                          = "Allow"
  protocol                        = "Tcp"
  source_port_range               = "*"
  destination_port_range          = "3389"
  source_address_prefix           = "*"
  destination_address_prefix      = "*"
  resource_group_name             = azurerm_resource_group.rg.name
  network_security_group_name     = azurerm_network_security_group.nsg_vnet[each.key].name
}

# Allow SSH access (port 22) from any source to all Virtual Machines
resource "azurerm_network_security_rule" "allow_ssh" {
  for_each                        = azurerm_virtual_network.vnet
  name                            = "allow-ssh"
  priority                        = 300
  direction                       = "Inbound"
  access                          = "Allow"
  protocol                        = "Tcp"
  source_port_range               = "*"
  destination_port_range          = "22"
  source_address_prefix           = "*"
  destination_address_prefix      = "*"
  resource_group_name             = azurerm_resource_group.rg.name
  network_security_group_name     = azurerm_network_security_group.nsg_vnet[each.key].name
}

#################### ASSOCIATE NETWORK SECURITY GROUP (NSG) WITH SUBNETS ####################
# Associate NSG with the Active Directory Domain Controllers (ADDC) Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each             = azurerm_subnet.snet_addc
  subnet_id            = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_vnet[each.key].id
}

# Associate NSG with the Application Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_app" {
  for_each             = azurerm_subnet.snet_app
  subnet_id            = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_vnet[each.key].id
}

# Associate NSG with the Database Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_db" {
  for_each             = azurerm_subnet.snet_db
  subnet_id            = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_vnet[each.key].id
}

# Associate NSG with the Client Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association_client" {
  for_each             = azurerm_subnet.snet_client
  subnet_id            = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg_vnet[each.key].id
}

#################### OUTPUT EXAMPLES ####################
# Output the Virtual Network address spaces and locations for each region
output "vnet_address" {
  description = "Map of Virtual Networks with their address spaces and locations"
  value = {
    for idx, vnet in azurerm_virtual_network.vnet : vnet.name => {
      region = vnet.location
      space  = vnet.address_space
    }
  }
}

# Output the VNet peering configurations between regions
output "vnet_peering" {
  description = "VNet peering configurations"
  value = {
    "${var.shortregions[0]}-to-${var.shortregions[1]}" = {
      peering_name = azurerm_virtual_network_peering.peering1.name
      vnet_name    = azurerm_virtual_network_peering.peering1.virtual_network_name
    }
    "${var.shortregions[1]}-to-${var.shortregions[0]}" = {
      peering_name = azurerm_virtual_network_peering.peering2.name
      vnet_name    = azurerm_virtual_network_peering.peering2.virtual_network_name
    }
  }
}
