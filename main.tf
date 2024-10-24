#################### LOCALS ####################
locals {
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
  # Define a flat list of region-server pairs
  region_server_pairs = flatten([
    for r in var.shortregions : [
      { region = r, index = 0 },
      { region = r, index = 1 }
    ]
  ])
}

#################### MAIN ####################
# Create a resource group in each region
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
  depends_on = [
    azurerm_resource_group.rg,
  ]
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
  address_prefixes     = [cidrsubnet(var.address_spaces[count.index], 4, 7)]
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

#################### VIRTUAL NETWORK PEERING ####################
# Create VNet peering from first region to second region
resource "azurerm_virtual_network_peering" "peering1" {
  name                         = "${var.shortregions[0]}-peering-to-${var.shortregions[1]}"
  resource_group_name          = azurerm_resource_group.rg[0].name
  virtual_network_name         = azurerm_virtual_network.vnet[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[1].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network.vnet[0],
    azurerm_virtual_network.vnet[1],
  ]
}

# Create VNet peering from second region to first region
resource "azurerm_virtual_network_peering" "peering2" {
  name                         = "${var.shortregions[1]}-peering-to-${var.shortregions[0]}"
  resource_group_name          = azurerm_resource_group.rg[1].name
  virtual_network_name         = azurerm_virtual_network.vnet[1].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network.vnet[1],
    azurerm_virtual_network.vnet[0],
  ]
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
    zones                         = ["1"]
  }
  depends_on = [
    azurerm_virtual_network_peering.peering1,
    azurerm_virtual_network_peering.peering2,
  ]
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
  depends_on = [
    azurerm_virtual_network_peering.peering1,
    azurerm_virtual_network_peering.peering2,
  ]
}

# Blob container for cloud SQL quorum
resource "azurerm_storage_container" "sqlha_quorum" {
  count                 = length(var.regions)
  name                  = lower("${var.shortregions[count.index]}sqlquorum")
  storage_account_name  = azurerm_storage_account.sqlha_witness[count.index].name
  container_access_type = "private"
}

#################### ADD ADDC ####################
# Public IP for ADDC in each region
resource "azurerm_public_ip" "addc_public_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-addc-pip"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  allocation_method   = "Static"
  zones               = ["1"]
  tags                = var.labtags
  depends_on = [
    azurerm_virtual_network_peering.peering1,
    azurerm_virtual_network_peering.peering2,
  ]
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
    cidrhost(azurerm_subnet.snet_addc[0].address_prefixes[0], 5), # First DC's IP
    cidrhost(azurerm_subnet.snet_addc[1].address_prefixes[0], 5), # Second DC's IP
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
  resource_group_name = azurerm_resource_group.rg[count.index].name
  location            = var.regions[count.index]
  zone                = "1"
  size                = var.vm_addc_size
  admin_username      = var.domain_admin_user
  admin_password      = var.domain_admin_pswd
  provision_vm_agent  = true
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
resource "azurerm_virtual_machine_run_command" "setup_domain_exec" {
  name               = "SetupDomain"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File c:\\Install-AdDomain.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd}"
  }
  depends_on = [
    null_resource.setup_domain_copy,
  ]
}

# Ensure the VM is in a stable state before executing the next command
resource "time_sleep" "setup_domain_wait" {
  create_duration = "2m"
  depends_on = [
    azurerm_virtual_machine_run_command.setup_domain_exec,
  ]
}

# Restart the first Active Directory Domain Controller VM after domain promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart" {
  name               = "AddcRestartCommand0"
  location           = var.regions[0]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[0].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.setup_domain_wait,
  ]
}

# Wait for the VM to restart after domain promotion
resource "time_sleep" "addc_vm_restart_wait" {
  create_duration = "10m"
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
resource "azurerm_virtual_machine_run_command" "setup_domain_controller_exec" {
  name               = "SetupDomainController"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Install-AdDomainController.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -safemode_admin_pswd ${var.safemode_admin_pswd} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
  }
  depends_on = [
    null_resource.setup_domain_controller_copy,
  ]
}

# Ensure the VM is in a stable state before executing the next command
resource "time_sleep" "setup_domain_controller_wait" {
  create_duration = "3m"
  depends_on = [
    azurerm_virtual_machine_run_command.setup_domain_controller_exec,
  ]
}

# Restart the second Active Directory Domain Controller VM after promotion
resource "azurerm_virtual_machine_run_command" "addc_vm_restart_second" {
  name               = "AddcRestartCommand1"
  location           = var.regions[1]
  virtual_machine_id = azurerm_windows_virtual_machine.addc_vm[1].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.setup_domain_controller_wait,
  ]
}

# Wait for the second VM to restart after domain controller promotion
resource "time_sleep" "addc_vm_restart_wait_second" {
  create_duration = "10m"
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

########## EXECUTE ADD-DOMAINACCOUNTS SCRIPT ON ADDC VMS ##########
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
# Public IPs for SQLHA
resource "azurerm_public_ip" "sqlha_public_ip" {
  for_each            = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                = lower("${each.value.region}-sqlha${each.value.index}-public-ip")
  location            = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.labtags
  depends_on = [
    azurerm_virtual_network_peering.peering1,
    azurerm_virtual_network_peering.peering2,
  ]
}

# Network Interfaces for SQLHA
resource "azurerm_network_interface" "sqlha_nic" {
  for_each                       = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                           = lower("${each.value.region}-sqlha${each.value.index}-nic")
  location                       = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name            = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  accelerated_networking_enabled = true
  tags                           = var.labtags
  ip_configuration {
    name                          = lower("${each.value.region}-sqlha${each.value.index}-nic-config")
    subnet_id                     = azurerm_subnet.snet_db[index(var.shortregions, each.value.region)].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.snet_db[index(var.shortregions, each.value.region)].address_prefixes[0], each.value.index == 0 ? 9 : 10)
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.sqlha_public_ip[each.key].id
  }
  dns_servers = [
    cidrhost(azurerm_subnet.snet_addc[0].address_prefixes[0], 5),
    cidrhost(azurerm_subnet.snet_addc[1].address_prefixes[0], 5),
  ]
}

# SQLHA Virtual Machines
resource "azurerm_windows_virtual_machine" "sqlha_vm" {
  for_each            = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                = lower("${each.value.region}-sqlha${each.value.index}-vm")
  computer_name       = upper("${each.value.region}-sqlha${each.value.index}")
  resource_group_name = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  location            = var.regions[index(var.shortregions, each.value.region)]
  zone                = "1"
  size                = var.vm_sqlha_size
  admin_username      = var.sql_localadmin_user
  admin_password      = var.sql_localadmin_pswd
  tags                = var.labtags
  network_interface_ids = [
    azurerm_network_interface.sqlha_nic[each.key].id
  ]
  os_disk {
    name                 = lower("${each.value.region}-sqlha${each.value.index}-os-disk")
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
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

########## INSTALL OPENSSH ON SQLHA VIRTUAL MACHINES ##########
resource "azurerm_virtual_machine_extension" "install_openssh_sql" {
  for_each                   = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                       = "InstallOpenSSH-${each.value.region}-sqlha${each.value.index}"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
  ]
}

########## SQL MANAGED DISKS ##########
# Data Disks for SQLHA VMs
resource "azurerm_managed_disk" "sqlha_data" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-data-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 90
  tags                 = var.labtags
}

resource "azurerm_managed_disk" "sqlha_logs" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-log-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 60
  tags                 = var.labtags
}

resource "azurerm_managed_disk" "sqlha_temp" {
  for_each             = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name                 = "${each.value.region}-sqlha${each.value.index}-temp-disk"
  location             = var.regions[index(var.shortregions, each.value.region)]
  resource_group_name  = azurerm_resource_group.rg[index(var.shortregions, each.value.region)].name
  zone                 = "1"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  tags                 = var.labtags
}

# Data Disk Attachments
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_attachments" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  managed_disk_id    = azurerm_managed_disk.sqlha_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  lun                = 0
  caching            = "ReadWrite"
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
    azurerm_managed_disk.sqlha_temp,
  ]
}

########## DOMAIN JOIN SQL SERVERS ##########
# Copy Domain Join Script
resource "null_resource" "sql_domainjoin_script_copy" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  provisioner "file" {
    source      = "${path.module}/Add-SqlDomainJoin.ps1"
    destination = "C:\\Add-SqlDomainJoin.ps1"
    connection {
      type            = "ssh"
      user            = var.sql_localadmin_user
      password        = var.sql_localadmin_pswd
      host            = azurerm_public_ip.sqlha_public_ip[each.key].ip_address
      target_platform = "windows"
      timeout         = "10m"
    }
  }
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.sqlha_attachments,
  ]
}

# Execute Domain Join Script
resource "azurerm_virtual_machine_run_command" "sql_domainjoin_script_exec" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name               = "SqlDomainJoinCommand-${each.value.region}-${each.value.index}"
  location           = var.regions[index(var.shortregions, each.value.region)]
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -File C:\\Add-SqlDomainJoin.ps1 -domain_name ${var.domain_name} -domain_netbios_name ${var.domain_netbios_name} -domain_admin_user ${var.domain_admin_user} -domain_admin_pswd ${var.domain_admin_pswd}"
  }
  depends_on = [
    null_resource.sql_domainjoin_script_copy,
  ]
}
# Wait for SQLHA VMs After Domain Join
resource "time_sleep" "sqlha_domainjoin_script_wait" {
  create_duration = "3m"
  depends_on = [
    azurerm_virtual_machine_run_command.sql_domainjoin_script_exec,
  ]
}

# Restart SQLHA VMs After Domain Join
resource "azurerm_virtual_machine_run_command" "sqlha_domainjoin_restart" {
  for_each           = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }
  name               = "SqlRestartCommand-${each.value.region}-${each.value.index}"
  location           = var.regions[index(var.shortregions, each.value.region)]
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id
  source {
    script = "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -Command Restart-Computer -Force"
  }
  depends_on = [
    time_sleep.sqlha_domainjoin_script_wait,
  ]
}

# Final Wait After SQLHA VM Restart
resource "time_sleep" "sqlha_domainjoin_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_virtual_machine_run_command.sqlha_domainjoin_restart,
  ]
}

########## ASSOCIATE SQL SERVERS TO LOAD BALANCER BACKEND POOL ##########
resource "azurerm_network_interface_backend_address_pool_association" "sqlha_nic_lb_association" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }

  network_interface_id    = azurerm_network_interface.sqlha_nic[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlha_backend_pool[floor(index(var.shortregions, each.value.region) / 1)].id

  depends_on = [
    time_sleep.sqlha_domainjoin_wait,
  ]
}

########## CREATE VIRTUAL MACHINE GROUP IN EACH REGION ##########
resource "azurerm_mssql_virtual_machine_group" "sqlha_vmg" {
  for_each = { for idx, region in var.shortregions : region => idx }

  name                = lower("${each.key}-sqlhavmg")
  location            = var.regions[each.value]
  resource_group_name = azurerm_resource_group.rg[each.value].name
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
    storage_account_url            = azurerm_storage_account.sqlha_witness[each.value].primary_blob_endpoint
    storage_account_primary_key    = azurerm_storage_account.sqlha_witness[each.value].primary_access_key
  }

  depends_on = [
    azurerm_network_interface_backend_address_pool_association.sqlha_nic_lb_association,
  ]
}

resource "time_sleep" "sqlha_vmg_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_mssql_virtual_machine_group.sqlha_vmg,
  ]
}

########## CREATE MSSQL VIRTUAL MACHINE FOR EACH SQL SERVER ##########
resource "azurerm_mssql_virtual_machine" "az_sqlha" {
  for_each = { for pair in local.region_server_pairs : "${pair.region}-${pair.index}" => pair }

  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[each.key].id

  # Access the VM group correctly using the region name as a key
  sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.sqlha_vmg[each.value.region].id

  sql_license_type      = "PAYG"
  r_services_enabled    = false
  sql_connectivity_port = 1433
  sql_connectivity_type = "PRIVATE"
  tags                  = var.labtags

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

resource "time_sleep" "sqlha_mssqlvm_wait" {
  create_duration = "10m"
  depends_on = [
    azurerm_mssql_virtual_machine.az_sqlha,
  ]
}

########## SET ACLS FOR VMG ACCESS OVER THE SERVERS OU ##########
resource "null_resource" "add_sql_acl_clusters" {
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
    time_sleep.sqlha_mssqlvm_wait,
  ]
}

/*#################### PUBLIC IP AND NAT GATEWAY ####################
# Create a single Public IP per region for NAT Gateway
resource "azurerm_public_ip" "gateway_ip" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-nat-gateway-ip"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.labtags
}

# Create NAT Gateway in each region
resource "azurerm_nat_gateway" "nat_gateway" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-nat-gateway"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  sku_name            = "Standard"
  tags                = var.labtags
  depends_on          = [azurerm_public_ip.gateway_ip]
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = length(var.regions)
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[count.index].id
  public_ip_address_id = azurerm_public_ip.gateway_ip[count.index].id

  depends_on = [
    azurerm_nat_gateway.nat_gateway,
    azurerm_public_ip.gateway_ip
  ]
}

#################### SUBNET ASSOCIATIONS ####################
# Associate NAT Gateway with Gateway Subnets
resource "azurerm_subnet_nat_gateway_association" "nat_association" {
  count          = length(var.regions)
  subnet_id      = azurerm_subnet.snet_gw[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[count.index].id

  depends_on = [
    azurerm_nat_gateway.nat_gateway,
  ]
}

#################### ROUTE TABLES AND ROUTES ####################
# Create Route Table for each region
resource "azurerm_route_table" "route_table" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-route-table"
  location            = var.regions[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
  tags                = var.labtags
  depends_on = [
    azurerm_subnet_network_security_group_association,
  ]
}

# Associate Route Tables with Gateway Subnets
resource "azurerm_subnet_route_table_association" "route_table_association" {
  count          = length(var.regions)
  subnet_id      = azurerm_subnet.snet_gw[count.index].id
  route_table_id = azurerm_route_table.route_table[count.index].id

  depends_on = [
    azurerm_route_table.route_table,
  ]
}

# Create a default route internet-bound traffic
resource "azurerm_route" "route_to_internet" {
  count               = length(var.regions)
  name                = "${var.shortregions[count.index]}-route-to-internet"
  resource_group_name = azurerm_resource_group.rg[count.index].name
  route_table_name    = azurerm_route_table.route_table[count.index].name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}
*/
