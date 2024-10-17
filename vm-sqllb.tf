########## CREATE LOAD BALANCERS FOR SQLHA ##########
# Create Load Balancer in each region
resource "azurerm_lb" "sqlha_lb" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-lb"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.labtags

  frontend_ip_configuration {
    name                          = "${var.shortregions[count.index]}-sqlha-frontend"
    subnet_id                     = azurerm_subnet.snet_db[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_db[count.index].address_prefixes[0], 20)
  }
}

# Health probe for SQLHA Load Balancer
resource "azurerm_lb_probe" "sqlha_probe" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-probe"
  loadbalancer_id     = azurerm_lb.sqlha_lb[count.index].id
  protocol            = "Tcp"
  port                = 5999
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer rule for SQL listener
resource "azurerm_lb_rule" "sqlha_lb_rule" {
  count                          = length(var.regions)
  name                           = "${var.shortregions[count.index]}-sqlha-rule"
  loadbalancer_id                = azurerm_lb.sqlha_lb[count.index].id
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "${var.shortregions[count.index]}-sqlha-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.sqlha_backend_pool[count.index].id]
  probe_id                       = azurerm_lb_probe.sqlha_probe[count.index].id
}

# Backend address pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "sqlha_backend_pool" {
  count           = length(var.regions)
  name            = "${var.shortregions[count.index]}-sqlha-backend-pool"
  loadbalancer_id = azurerm_lb.sqlha_lb[count.index].id
}
