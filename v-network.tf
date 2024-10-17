#################### VNET & SUBNETS ####################
resource "azurerm_virtual_network" "vnet" {
  for_each            = { for idx, reg in var.regions : idx => reg }
  name                = "${var.shortregions[each.key]}-vnet"
  location            = each.value
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_spaces[each.key]]
  tags                = var.labtags
}

resource "azurerm_subnet" "snet_gw" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 4, 0)]
}

resource "azurerm_subnet" "snet_addc" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-addc"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 1)]
}

resource "azurerm_subnet" "snet_db" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 2)]
}

resource "azurerm_subnet" "snet_app" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 3, 3)]
}

resource "azurerm_subnet" "snet_client" {
  for_each             = azurerm_virtual_network.vnet
  name                 = "${var.shortregions[each.key]}-snet-client"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(var.address_spaces[each.key], 4, 15)]
}

resource "azurerm_public_ip" "gateway_ip" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-gateway-ip"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.labtags
}

resource "azurerm_nat_gateway" "nat_gateway" {
  for_each            = azurerm_virtual_network.vnet
  name                = "${var.shortregions[each.key]}-nat-gateway"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.labtags
}

resource "azurerm_subnet_nat_gateway_association" "nat_association" {
  for_each       = azurerm_subnet.snet_addc
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.key].id
  depends_on     = [azurerm_nat_gateway.nat_gateway]
}

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

########## OUTPUT EXAMPLES ##########
output "vnet_ids" {
  value = [for vnet in azurerm_virtual_network.vnet : vnet.id]
}

output "subnet_ids" {
  value = [for subnet in azurerm_subnet.snet_addc : subnet.id]
}

output "nat_gateway_ids" {
  value = [for nat in azurerm_nat_gateway.nat_gateway : nat.id]
}

output "peering_ids" {
  value = [azurerm_virtual_network_peering.peering1.id, azurerm_virtual_network_peering.peering2.id]
}
