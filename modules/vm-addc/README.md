
# Active Directory Domain Controller Module (`vm_addc`)

This Terraform module deploys **Windows-based Active Directory Domain Controllers (ADDC)** across multiple regions for high availability and fault tolerance. It sets up a primary domain and replicates to ensure resilience within the Azure environment.

---

## Features

- **Windows Server 2022** virtual machines configured as Domain Controllers.
- **Multi-region Deployment** for high availability.
- **Active Directory Forest and Domain** setup with replication.
- **Automated configuration** for Domain DNS and replication settings.
- **Static IP Assignment** for consistent network access.
- **Customizable VM size, domain names, and credentials**.

---

## Usage

```hcl
module "vm_addc" {
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
  domain_dns_servers   = local.domain_dns_servers
  tags                 = var.labtags

  depends_on = [
    module.v_network,
  ]
}
```

---

## Inputs

| **Name**               | **Description**                                           | **Type**        | **Default**            | **Required** |
|------------------------|-----------------------------------------------------------|-----------------|------------------------|--------------|
| `resource_group_names` | Names of the resource groups for the VMs.                 | `list(string)`  | n/a                    | Yes          |
| `regions`              | Azure regions for ADDC deployment.                        | `list(string)`  | n/a                    | Yes          |
| `shortregions`         | Short region identifiers (e.g., "usw").                   | `list(string)`  | n/a                    | Yes          |
| `subnet_ids`           | Subnet IDs where the Domain Controllers will connect.     | `list(string)`  | n/a                    | Yes          |
| `subnet_cidrs`         | CIDR blocks of the subnets for VM NICs.                   | `list(string)`  | n/a                    | Yes          |
| `vm_addc_size`         | Size of the ADDC virtual machines.                        | `string`        | `"Standard_B2ms"`      | No           |
| `domain_name`          | FQDN of the Active Directory domain (e.g., `example.com`).| `string`        | n/a                    | Yes          |
| `domain_netbios_name`  | NetBIOS name for the domain (e.g., `EXAMPLE`).            | `string`        | n/a                    | Yes          |
| `domain_admin_user`    | Admin username for the domain.                            | `string`        | `"domainadmin"`        | Yes          |
| `domain_admin_pswd`    | Password for the domain admin user.                       | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `safemode_admin_pswd`  | Safe mode admin password for the ADDC.                    | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `temp_admin_pswd`      | Temporary admin password for initial setup.               | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `domain_dns_servers`   | List of DNS server IPs for domain integration.            | `list(string)`  | `[]`                   | No           |
| `tags`                 | Tags to apply to resources.                               | `map(string)`   | `{}`                   | No           |

---

## Outputs

| **Name**                    | **Description**                                      |
|-----------------------------|------------------------------------------------------|
| `addc_public_ip_dns_map`    | Map of ADDC public IPs to their DNS hostnames.       |
| `addc_private_ip_addresses` | List of private IP addresses for each ADDC VM.       |
| `addc_computer_names`       | Computer names of the deployed Domain Controllers.   |

---

## Requirements

- **Dependencies**: This module relies on the `v-network` module for network and subnet configuration.

---

This module provides a robust Active Directory setup for testing and learning scenarios, ensuring domain resilience across multiple regions. Be sure to manage credentials securely and review security best practices when using this module.