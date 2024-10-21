#################### LOCALS ####################
locals {
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
}

#################### MAIN ####################
resource "azurerm_resource_group" "rg" {
  count    = length(var.regions)
  name     = lower("rg-multiregion-${var.shortregions[count.index]}")
  location = var.regions[count.index]
  tags     = var.labtags
}

#################### VIRTUAL NETWORKS AND SUBNETS ####################
# Create Virtual Network (VNet) for each region 
resource "azurerm_virtual_network" "vnet" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-vnet"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  address_space       = [var.address_spaces[count.index]]
  tags                = var.labtags
}

# Create Gateway Subnet within each Virtual Network
resource "azurerm_subnet" "snet_gw" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-gw"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 4, 0)]
}

# Create Active Directory Domain Controllers (ADDC) Subnet
resource "azurerm_subnet" "snet_addc" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-addc"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 1)]
}

# Create Database Subnet within each Virtual Network
resource "azurerm_subnet" "snet_db" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-db"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 2)]
}

# Create Application Subnet within each Virtual Network
resource "azurerm_subnet" "snet_app" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-app"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 3, 3)]
}

# Create Client Subnet within each Virtual Network
resource "azurerm_subnet" "snet_client" {
  count                = length(var.regions)
  name                 = "${var.shortregions[count.index]}-snet-client"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 4, 15)]
}

#################### NETWORK SECURITY GROUP (NSG) ####################
resource "azurerm_network_security_group" "nsg" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-snet-nsg"
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = azurerm_resource_group.rg[count.index].name
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
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_gw1" {
  subnet_id                 = azurerm_subnet.snet_gw[1].id
  network_security_group_id = azurerm_network_security_group.nsg[1].id
}

# NSG Association for ADDC Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_addc0" {
  subnet_id                 = azurerm_subnet.snet_addc[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_addc1" {
  subnet_id                 = azurerm_subnet.snet_addc[1].id
  network_security_group_id = azurerm_network_security_group.nsg[1].id
}

# NSG Association for DB Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_db0" {
  subnet_id                 = azurerm_subnet.snet_db[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_db1" {
  subnet_id                 = azurerm_subnet.snet_db[1].id
  network_security_group_id = azurerm_network_security_group.nsg[1].id
}

# NSG Association for APP Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_app0" {
  subnet_id                 = azurerm_subnet.snet_app[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_app1" {
  subnet_id                 = azurerm_subnet.snet_app[1].id
  network_security_group_id = azurerm_network_security_group.nsg[1].id
}

# NSG Association for Client Subnet in both regions
resource "azurerm_subnet_network_security_group_association" "nsg_association_client0" {
  subnet_id                 = azurerm_subnet.snet_client[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_client1" {
  subnet_id                 = azurerm_subnet.snet_client[1].id
  network_security_group_id = azurerm_network_security_group.nsg[1].id
}

#################### ROUTE TABLE AND ROUTES ####################
# Create Route Table for each region
resource "azurerm_route_table" "route_table" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-route-table"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  tags                = var.labtags
}

# Create a route to the Internet for each Route Table
resource "azurerm_route" "route_to_internet" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-route-to-internet"
  resource_group_name = azurerm_resource_group.rg[count.index].name
  route_table_name    = azurerm_route_table.route_table[count.index].name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

#################### PUBLIC IP AND NAT GATEWAY ####################
# Create Public IP for NAT Gateway in each region
resource "azurerm_public_ip" "gateway_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-gateway-ip"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  allocation_method   = "Static"
  tags                = var.labtags
}

# Create NAT Gateway in each region
resource "azurerm_nat_gateway" "nat_gateway" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-nat-gateway"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  tags                = var.labtags
}

# Associate NAT Gateway with the Active Directory Domain Controllers (ADDC) Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_association" {
  count          = length(var.regions)
  subnet_id      = azurerm_subnet.snet_gw[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[count.index].id
}

#################### VIRTUAL NETWORK PEERING ####################
# Create VNet peering from the first region to the second region
resource "azurerm_virtual_network_peering" "peering1" {
  name                         = "${var.shortregions[0]}-peering-to-${var.shortregions[1]}"
  resource_group_name          = azurerm_resource_group.rg[0].name
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
  resource_group_name          = azurerm_resource_group.rg[1].name
  virtual_network_name         = azurerm_virtual_network.vnet[1].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on                   = [azurerm_virtual_network.vnet]
}

########## CREATE LOAD BALANCERS FOR SQLHA ##########
# Create Load Balancer in each region
resource "azurerm_lb" "sqlha_lb" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlha-lb"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
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

  depends_on = [
    azurerm_lb.sqlha_lb,
  ]
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

  depends_on = [
    azurerm_lb.sqlha_lb,
  ]
}

# Backend address pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "sqlha_backend_pool" {
  count           = length(var.regions)
  name            = "${var.shortregions[count.index]}-sqlha-backend-pool"
  loadbalancer_id = azurerm_lb.sqlha_lb[count.index].id

  depends_on = [
    azurerm_lb.sqlha_lb,
  ]
}

########## CREATE STORAGE FOR SQLHA ##########
# Storage account for cloud SQL witness
resource "azurerm_storage_account" "sqlha_witness" {
  count                      = length(var.regions)
  name                       = lower("${var.shortregions[count.index]}sqlwitness")
  location                   = var.regions[count.index]
  resource_group_name        = azurerm_resource_group.rg[count.index].name
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  tags                       = var.labtags
}

# Blob container for cloud SQL quorum
resource "azurerm_storage_container" "sqlha_quorum" {
  count                 = length(var.regions)
  name                  = lower("${var.shortregions[count.index]}sqlquorum")
  storage_account_name  = azurerm_storage_account.sqlha_witness[count.index].name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.sqlha_witness,
  ]
}

#################### ADD ADDC ####################
# Public IP for ADDC in each region
resource "azurerm_public_ip" "addc_public_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-addc-pip"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  allocation_method   = "Static"
  tags                = var.labtags
}

# Network Interface for ADDC in each region
resource "azurerm_network_interface" "addc_nic" {
  count                          = length(var.regions)
  name                           = "${var.shortregions[count.index]}-addc-nic"
  location                       = var.regions[count.index]
  resource_group_name            = azurerm_resource_group.rg[count.index].name
  tags                           = var.labtags
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_addc[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_addc[count.index].address_prefixes[0], 5)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.addc_public_ip[count.index].id
  }
  dns_servers = [
    cidrhost(azurerm_subnet.snet_addc[0].address_prefixes[0], 5),  # First DC's IP
    cidrhost(azurerm_subnet.snet_addc[1].address_prefixes[0], 5),  # Second DC's IP
    "1.1.1.1",
    "8.8.8.8",
  ]
  depends_on = [
    azurerm_public_ip.addc_public_ip
  ]
}

# Windows Virtual Machine for ADDC in each region
resource "azurerm_windows_virtual_machine" "addc_vm" {
  count               = length(var.regions)
  name                = lower("${var.shortregions[count.index]}-addc-vm")
  computer_name       = upper("${var.shortregions[count.index]}-addc")
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  admin_username      = var.domain_admin_user
  admin_password      = var.domain_admin_pswd
  provision_vm_agent  = true
  size                = var.vm_addc_size
  tags                = var.labtags

  network_interface_ids = [
    azurerm_network_interface.addc_nic[count.index].id
  ]

  os_disk {
    name                 = "${var.shortregions[count.index]}-addc-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Install OpenSSH Extension for ADDC VMs
resource "azurerm_virtual_machine_extension" "install_openssh_addc" {
  count                      = length(var.regions)
  name                       = "InstallOpenSSH-addc${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_windows_virtual_machine.addc_vm
  ]
}

########## INSTALL 1ST DOMAIN CONTROLLER FOR LAB ##########
# Copy setup domain script to the first Active Directory Domain Controller VM
resource "null_resource" "setup_domain_copy" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomain.ps1"
    destination = "c:\\Install-AdDomain.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    azurerm_virtual_machine_extension.install_openssh_addc,
  ]
}

# Execute the setup domain script on the first Active Directory Domain Controller VM
resource "azurerm_virtual_machine_extension" "setup_domain_exec" {
  name                       = "SetupDomain"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomain.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
    }
  SETTINGS
  depends_on = [
    null_resource.setup_domain_copy,
  ]
}

# Restart the first Active Directory Domain Controller VM after domain promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart" {
  name               = "RestartCommand"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    azurerm_virtual_machine_extension.setup_domain_exec,
  ]
}

# Wait for the VM to restart after domain promotion
resource "time_sleep" "addc_vm_restart_wait" {
  create_duration = "15m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart,
  ]
}

########## PROMOTE 2ND DOMAIN CONTROLLER FOR LAB ##########
# Copy setup domain controller script to the second Active Directory Domain Controller VM
resource "null_resource" "setup_domain_controller_copy" {
  provisioner "file" {
    source      = "${path.module}/Install-AdDomainController.ps1"
    destination = "c:\\Install-AdDomainController.ps1"
    connection {
      type            = "ssh"
      user            = var.domain_admin_user
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[1].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait,
  ]
}

# Execute the setup domain controller script on the second Active Directory Domain Controller VM
resource "azurerm_virtual_machine_extension" "setup_domain_controller_exec" {
  name                       = "SetupDomainController"
  virtual_machine_id         = azurerm_windows_virtual_machine.addc_vm[1].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.labtags
  settings                   = <<SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Install-AdDomainController.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
    }
  SETTINGS
  depends_on = [
    null_resource.setup_domain_controller_copy,
  ]
}

# Restart the second Active Directory Domain Controller VM after promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart_second" {
  name               = "RestartCommand"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    azurerm_virtual_machine_extension.setup_domain_controller_exec,
  ]
}

# Wait for the second VM to restart after domain controller promotion
resource "time_sleep" "addc_vm_restart_wait_second" {
  create_duration = "15m"
  depends_on = [
    azurerm_virtual_machine_run_command.addc_vm_restart_second,
  ]
}

########## COPY DOMAIN AND SQL SCRIPTS ##########
# Copy Add-SqlAcl.ps1 script to the first Active Directory Domain Controller VM
resource "null_resource" "add_sqlacl_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-SqlAcl.ps1"
    destination = "c:\\SqlAcl.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait_second,
  ]
}

# Copy Add-DomainAccounts.ps1 script to the first Active Directory Domain Controller VM
resource "null_resource" "add_domain_accounts_copy" {
  provisioner "file" {
    source      = "${path.module}/Add-DomainAccounts.ps1"
    destination = "c:\\Add-DomainAccounts.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.addc_vm_restart_wait_second,
  ]
}

# Execute the setup domain accounts script on the first Active Directory Domain Controller VM
# Execute Add-DomainAccounts.ps1 remotely on ADDC VMs
resource "null_resource" "add_domain_accounts_exec" {
  connection {
    type            = "ssh"
    host            = azurerm_public_ip.addc_public_ip[0].ip_address
    user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
    password        = var.domain_admin_pswd
    target_platform = "windows"
    timeout         = "10m"
  }
  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-DomainAccounts.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_svc_acct_pswd ${var.sql_svc_acct_pswd}"
    ]
  }
  depends_on = [
    null_resource.add_domain_accounts_copy,
  ]
}

########## CREATE SQL NODES FOR SQLHA ##########
# Public IPs for SQLHA in both regions
resource "azurerm_public_ip" "sqlha_public_ip" {
  count               = length(var.regions) * 2
  name                = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-public-ip"
  location            = var.regions[floor(count.index / 2)]
  resource_group_name = azurerm_resource_group.rg[floor(count.index / 2)].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.labtags
}

# Network Interfaces for SQLHA in both regions
resource "azurerm_network_interface" "sqlha_nic" {
  count                          = length(var.regions) * 2
  name                           = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-nic"
  location                       = var.regions[floor(count.index / 2)]
  resource_group_name            = azurerm_resource_group.rg[floor(count.index / 2)].name
  accelerated_networking_enabled = true
  tags                           = var.labtags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_db[floor(count.index / 2)].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_db[floor(count.index / 2)].address_prefixes[0], count.index % 2 == 0 ? 9 : 10)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.sqlha_public_ip[count.index].id
  }

  dns_servers = [
    cidrhost(azurerm_subnet.snet_addc[0].address_prefixes[0], 5),  # First DC's IP
    cidrhost(azurerm_subnet.snet_addc[1].address_prefixes[0], 5),  # Second DC's IP
  ]

  depends_on = [
    azurerm_public_ip.sqlha_public_ip,
  ]
}

# SQLHA Virtual Machines in both regions
resource "azurerm_windows_virtual_machine" "sqlha_vm" {
  count               = length(var.regions) * 2
  name                = lower("${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-vm")
  computer_name       = upper("${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}")
  location            = var.regions[floor(count.index / 2)]
  resource_group_name = azurerm_resource_group.rg[floor(count.index / 2)].name
  admin_username      = var.sql_localadmin_user
  admin_password      = var.sql_localadmin_pswd
  size                = "Standard_D2s_v3"
  tags                = var.labtags

  network_interface_ids = [
    azurerm_network_interface.sqlha_nic[count.index].id
  ]

  os_disk {
    name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2022"
    sku       = "Enterprise"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Install OpenSSH on SQLHA Virtual Machines
resource "azurerm_virtual_machine_extension" "install_openssh_sql" {
  count                      = length(var.regions) * 2
  name                       = "InstallOpenSSH-sqlha${count.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

########## DATA DISKS FOR SQLHA VMS ##########
# Data disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_data" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-data-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg[floor(count.index / 2)].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 90
  tags                 = var.labtags

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

# Log disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_logs" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-log-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg[floor(count.index / 2)].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 60
  tags                 = var.labtags

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
    azurerm_managed_disk.sqlha_data,
  ]
}

# TempDB disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_temp" {
  count                = length(var.regions) * 2
  name                 = "${var.shortregions[floor(count.index / 2)]}-sqlha${count.index % 2}-temp-disk"
  location             = var.regions[floor(count.index / 2)]
  resource_group_name  = azurerm_resource_group.rg[floor(count.index / 2)].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  tags                 = var.labtags

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
    azurerm_managed_disk.sqlha_logs,
  ]
}

# Data Disk Attachments for SQLHA VMs
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_attachments" {
  count = length(var.regions) * 2 * 3

  managed_disk_id = (
    count.index % 3 == 0 ? azurerm_managed_disk.sqlha_data[floor(count.index / 3)].id :
    count.index % 3 == 1 ? azurerm_managed_disk.sqlha_logs[floor(count.index / 3)].id :
    azurerm_managed_disk.sqlha_temp[floor(count.index / 3)].id
  )

  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[floor(count.index / 3)].id
  lun                = count.index % 3
  caching            = count.index % 3 == 0 ? "ReadWrite" : count.index % 3 == 1 ? "ReadOnly" : "None"

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
    azurerm_managed_disk.sqlha_temp,
  ]
}

########## DOMAIN JOIN SQLHA NODES ##########
# Domain join SQLHA nodes
resource "azurerm_virtual_machine_extension" "sqlha_domainjoin" {
  count                      = length(var.regions) * 2
  name                       = "DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = local.servers_ou_path
    User    = var.domain_admin_user
    Restart = "false"
    Options = "3"
  })

  protected_settings = jsonencode({
    Password = var.domain_admin_pswd
  })

  depends_on = [
    time_sleep.addc_vm_restart_wait_second,
    null_resource.add_domain_accounts_exec,
    azurerm_virtual_machine_data_disk_attachment.sqlha_attachments,
  ]
}

# Restart SQL VMs after domain join
resource "azurerm_virtual_machine_run_command" "sqlha_domainjoin_restart" {
  count              = length(var.regions) * 2
  name               = "RestartCommand"
  location           = var.regions[floor(count.index / 2)]
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id

  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }

  depends_on = [
    azurerm_virtual_machine_extension.sqlha_domainjoin,
  ]
}

# Wait for ALL SQL VMs to restart after domain join
resource "time_sleep" "sqlha_domainjoin_wait" {
  create_duration = "10m"

  depends_on = [
    azurerm_virtual_machine_run_command.sqlha_domainjoin_restart,
  ]
}

########## ADD LOCAL ADMINS AND SQL SYSADMINS TO SQL SERVERS ##########
# Copy Add-SqlLocalAdmins.ps1 script
resource "null_resource" "sql_localadmin_script_copy" {
  count = length(azurerm_windows_virtual_machine.sqlha_vm)
  provisioner "file" {
    source      = "${path.module}/Add-SqlLocalAdmins.ps1"
    destination = "C:\\Add-SqlLocalAdmins.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    time_sleep.sqlha_domainjoin_wait,
  ]
}

# Copy Add-SqlSysAdmins.ps1 script
resource "null_resource" "sql_sysadmin_script_copy" {
  count = length(azurerm_windows_virtual_machine.sqlha_vm)
  provisioner "file" {
    source      = "${path.module}/Add-SqlSysAdmins.ps1"
    destination = "C:\\Add-SqlSysAdmins.ps1"
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    null_resource.sql_localadmin_script_copy,
  ]
}

# Add local admins to SQL Servers
resource "null_resource" "add_sqllocaladmins_exec" {
  count = length(var.regions) * 2

  triggers = {
    vm_name = azurerm_windows_virtual_machine.sqlha_vm[count.index].name
  }

  connection {
    type            = "ssh"
    host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
    user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
    password        = var.domain_admin_pswd
    target_platform = "windows"
    timeout         = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlLocalAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user}"
    ]
  }

  depends_on = [
    null_resource.sql_localadmin_script_copy,
  ]
}

# Add SQL sysadmins to SQL Servers
resource "null_resource" "add_sqlsysadmins_exec" {
  count = length(var.regions) * 2

  triggers = {
    vm_name = azurerm_windows_virtual_machine.sqlha_vm[count.index].name
  }

  connection {
    type            = "ssh"
    host            = azurerm_public_ip.sqlha_public_ip[count.index].ip_address
    user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
    password        = var.domain_admin_pswd
    target_platform = "windows"
    timeout         = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlSysAdmins.ps1 -domain_name ${var.domain_name} -sql_svc_acct_user ${var.sql_svc_acct_user} -sql_svc_acct_pswd ${var.sql_svc_acct_pswd}"
    ]
  }

  depends_on = [
    null_resource.add_sqllocaladmins_exec,
  ]
}

# Wait for local admin & sysadmin scripts to complete
resource "time_sleep" "sqlha_final_wait" {
  create_duration = "5m"

  depends_on = [
    null_resource.add_sqlsysadmins_exec,
  ]
}

########## ASSOCIATE SQL SERVERS TO LOAD BALANCER BACKEND ##########
# Network interface backend address pool association for SQL VMs
resource "azurerm_network_interface_backend_address_pool_association" "sqlha_nic_lb_association" {
  count = length(azurerm_network_interface.sqlha_nic)

  network_interface_id    = azurerm_network_interface.sqlha_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlha_backend_pool[floor(count.index / 2)].id

  depends_on = [
    time_sleep.sqlha_final_wait,
  ]
}

########## CREATE SQL VIRTUAL MACHINE GROUPS FOR SQLHA ##########
resource "azurerm_mssql_virtual_machine_group" "sqlha_vmg" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-sqlhavmg"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  sql_image_offer     = var.sql_image_offer
  sql_image_sku       = var.sql_image_sku
  tags                = var.labtags

  wsfc_domain_profile {
    fqdn                           = var.domain_name
    cluster_subnet_type            = "MultiSubnet"
    cluster_bootstrap_account_name = "sqlinstall@${var.domain_name}"
    cluster_operator_account_name  = "sqlinstall@${var.domain_name}"
    sql_service_account_name       = "${var.sql_svc_acct_user}@${var.domain_name}"
    organizational_unit_path       = local.servers_ou_path
    storage_account_url            = azurerm_storage_account.sqlha_witness[count.index].primary_blob_endpoint
    storage_account_primary_key    = azurerm_storage_account.sqlha_witness[count.index].primary_access_key
  }

  depends_on = [
    azurerm_network_interface_backend_address_pool_association.sqlha_nic_lb_association,
  ]
}

# Wait for SQL VM Groups creation
resource "time_sleep" "sqlha_vmg_wait" {
  create_duration = "5m"

  depends_on = [
    azurerm_mssql_virtual_machine_group.sqlha_vmg,
  ]
}

########## CREATE AZURE MSSQL VIRTUAL MACHINES FOR SQL ##########
resource "azurerm_mssql_virtual_machine" "az_sqlha" {
  count                        = length(var.regions) * 2
  virtual_machine_id           = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.sqlha_vmg[floor(count.index / 2)].id
  sql_license_type             = "PAYG"
  r_services_enabled           = false
  sql_connectivity_port        = 1433
  sql_connectivity_type        = "PRIVATE"
  tags                         = var.labtags

  wsfc_domain_credential {
    cluster_bootstrap_account_password = var.sql_svc_acct_pswd
    cluster_operator_account_password  = var.sql_svc_acct_pswd
    sql_service_account_password       = var.sql_svc_acct_pswd
  }

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"
    data_settings {
      default_file_path = var.sqldatafilepath
      luns              = [0]
    }
    log_settings {
      default_file_path = var.sqllogfilepath
      luns              = [1]
    }
    temp_db_settings {
      default_file_path = var.sqltempfilepath
      luns              = [2]
    }
  }

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    time_sleep.sqlha_vmg_wait,
  ]
}

# Wait for MSSQL VMs initialization
resource "time_sleep" "sqlha_mssqlvm_wait" {
  create_duration = "5m"

  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}

########## SET ACLS FOR VMG ACCESS OVER THE SERVERS OU ##########
resource "null_resource" "add_sql_acl_clusters" {
  count = 1 # Run once for both regions

  triggers = {
    sqlcluster_region1 = azurerm_mssql_virtual_machine_group.sqlha_vmg[0].name
    sqlcluster_region2 = azurerm_mssql_virtual_machine_group.sqlha_vmg[1].name
    sql_vms            = join(",", [for vm in azurerm_mssql_virtual_machine.az_sqlha : vm.virtual_machine_id])
  }

  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.domain_admin_user}"
      password        = var.domain_admin_pswd
      host            = azurerm_public_ip.addc_public_ip[0].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }

    inline = [
      "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlAcl.ps1 -domain_name ${var.domain_name} -sqlcluster_region1 ${azurerm_mssql_virtual_machine_group.sqlha_vmg[0].name} -sqlcluster_region2 ${azurerm_mssql_virtual_machine_group.sqlha_vmg[1].name}"
    ]
  }

  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}
