# SQL High-Availability Virtual Machine Module (`vm-sql`)

This Terraform module deploys **SQL Server virtual machines (VMs) with high availability (HA)** in a multi-region setup, using Always On Availability Groups and Windows Server Failover Clustering (WSFC). The module is intended for use in lab and testing environments.

---

## Features

- **SQL Server 2019 on Windows Server 2022** configured for Always On availability.
- **Multi-region Deployment** for disaster recovery and resilience.
- **Automatic VNet Peering and Load Balancer Configuration** for SQL traffic distribution.
- **Active Directory Integration** for domain-based authentication and group management.
- **Static IP Assignment** for consistent network connectivity.
- **Configurable Storage for SQL Data, Logs, and TempDB**.

---

## Usage

```hcl
module "sql_ha" {
  source                = "./modules/vm-sql"
  resource_group_names  = [for rg in azurerm_resource_group.rg : rg.name]
  regions               = var.regions
  shortregions          = var.shortregions
  subnet_ids            = [for subnet in azurerm_subnet.snet_db : subnet.id]
  subnet_cidrs          = [for subnet in azurerm_subnet.snet_db : subnet.address_prefixes[0]]
  vm_sqlha_size         = var.vm_sqlha_size
  domain_name           = var.domain_name
  domain_netbios_name   = var.domain_netbios_name
  domain_admin_user     = var.domain_admin_user
  domain_admin_pswd     = var.domain_admin_pswd
  sql_localadmin_user   = var.sql_localadmin_user
  sql_localadmin_pswd   = var.sql_localadmin_pswd
  sql_sysadmin_user     = var.sql_sysadmin_user
  sql_sysadmin_pswd     = var.sql_sysadmin_pswd
  sql_svc_acct_user     = var.sql_svc_acct_user
  sql_svc_acct_pswd     = var.sql_svc_acct_pswd
  tags                  = var.labtags
  domain_dns_servers    = local.domain_dns_servers

  depends_on = [
    module.v_network,
  ]
}
```

---

## Inputs

| **Name**               | **Description**                                             | **Type**        | **Default**            | **Required** |
|------------------------|-------------------------------------------------------------|-----------------|------------------------|--------------|
| `resource_group_names` | Names of the resource groups for the VMs.                   | `list(string)`  | n/a                    | Yes          |
| `regions`              | Azure regions for SQL VM deployment.                        | `list(string)`  | n/a                    | Yes          |
| `shortregions`         | Short region identifiers (e.g., "usw").                     | `list(string)`  | n/a                    | Yes          |
| `subnet_ids`           | Subnet IDs where SQL VMs will connect.                      | `list(string)`  | n/a                    | Yes          |
| `subnet_cidrs`         | CIDR blocks of the subnets for VM NICs.                     | `list(string)`  | n/a                    | Yes          |
| `vm_sqlha_size`        | Size of the SQL VM instances.                               | `string`        | `"Standard_DS3_v2"`    | No           |
| `domain_name`          | FQDN of the Active Directory domain.                        | `string`        | n/a                    | Yes          |
| `domain_netbios_name`  | NetBIOS name for the domain.                                | `string`        | n/a                    | Yes          |
| `domain_admin_user`    | Admin username for the domain.                              | `string`        | n/a                    | Yes          |
| `domain_admin_pswd`    | Password for the domain admin user.                         | `string`        | n/a                    | Yes          |
| `sql_localadmin_user`  | Local admin username for the SQL VM.                        | `string`        | `"localadmin"`         | Yes          |
| `sql_localadmin_pswd`  | Password for the SQL VM local admin user.                   | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `sql_sysadmin_user`    | SQL Server sysadmin username.                               | `string`        | `"sqladmin"`           | Yes          |
| `sql_sysadmin_pswd`    | SQL Server sysadmin password.                               | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `sql_svc_acct_user`    | SQL Server service account username.                        | `string`        | `"svc_sqlserver"`      | Yes          |
| `sql_svc_acct_pswd`    | SQL Server service account password.                        | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `domain_dns_servers`   | List of DNS server IPs for Active Directory integration.    | `list(string)`  | `[]`                   | No           |
| `tags`                 | Tags to apply to resources.                                 | `map(string)`   | `{}`                   | No           |

---

## Outputs

| **Name**                     | **Description**                                      |
|------------------------------|------------------------------------------------------|
| `sqlha_public_ip_dns_map`    | Map of SQL HA public IP addresses to DNS hostnames.  |
| `sqlha_private_ip_addresses` | List of private IP addresses for each SQL HA VM.     |
| `sqlha_vm_names`             | Names of the deployed SQL HA VMs.                    |

---

## Requirements

- **Dependencies**: This module requires the `v-network` module for network and subnet configuration.

---

## Notes

- **Lab Environment**: This configuration is intended for learning and testing. For production environments, additional security and resource optimization are recommended.
- **Sensitive Data**: Avoid committing sensitive data such as passwords and domain details to version control.
- **High Availability**: This module is designed for SQL high availability and requires an existing AD domain configuration to function fully.

This module facilitates a robust SQL Server high-availability setup with Always On Availability Groups, ideal for exploring HA configurations in a controlled environment. Make sure to secure credentials and follow best practices when deploying in a live environment.