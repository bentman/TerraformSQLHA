#################### VIRTUAL NETWORKS AND SUBNETS ####################
# Create Virtual Network (VNet) for each region
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

#################### NETWORK SECURITY GROUP (NSG) ####################
# Create a single Network Security Group for all subnets
resource "azurerm_network_security_group" "nsg" {
  name                = "lab-nsg-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags

  # NSG rule to allow SSH access
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

  # NSG rule to allow RDP access
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

  # NSG rule to allow ICMP (ping)
  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # NSG rule to allow internal traffic
  security_rule {
    name                       = "Allow-Internal"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
}

# NSG Association for GW Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_gw0" {
  subnet_id                 = azurerm_subnet.snet_gw[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_gw1" {
  subnet_id                 = azurerm_subnet.snet_gw[1].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# NSG Association for ADDC Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_addc0" {
  subnet_id                 = azurerm_subnet.snet_addc[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_addc1" {
  subnet_id                 = azurerm_subnet.snet_addc[1].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# NSG Association for DB Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_db0" {
  subnet_id                 = azurerm_subnet.snet_db[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_db1" {
  subnet_id                 = azurerm_subnet.snet_db[1].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# NSG Association for APP Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_app0" {
  subnet_id                 = azurerm_subnet.snet_app[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_app1" {
  subnet_id                 = azurerm_subnet.snet_app[1].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# NSG Association for Client Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_client0" {
  subnet_id                 = azurerm_subnet.snet_client[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_client1" {
  subnet_id                 = azurerm_subnet.snet_client[1].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#################### ROUTE TABLE AND ROUTES ####################
# Create Route Table for each region
resource "azurerm_route_table" "route_table" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-route-table"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags
}

# Create a route to the Internet for each Route Table
resource "azurerm_route" "route_to_internet" {
  for_each            = azurerm_route_table.route_table
  name                = "${var.shortregions[each.key]}-route-to-internet"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = each.value.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
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

# Create NAT Gateway in each region
resource "azurerm_nat_gateway" "nat_gateway" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-nat-gateway"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags
}

# Associate NAT Gateway with the Active Directory Domain Controllers (ADDC) Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_association" {
  for_each       = azurerm_subnet.snet_gw
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.key].id
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

#################### OUTPUTS ####################
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
      vnet_name    = azurerm_virtual_network.vnet[0].name
    }
    "${var.shortregions[1]}-to-${var.shortregions[0]}" = {
      peering_name = azurerm_virtual_network_peering.peering2.name
      vnet_name    = azurerm_virtual_network.vnet[1].name
    }
  }
}
