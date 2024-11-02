# VM Jumpbox Module (`vm_jumpwin`)

This Terraform module deploys a **Windows-based jumpbox virtual machine (VM)** with OpenSSH for remote access, static IP assignment, and an auto-shutdown schedule. It is intended to serve as a secure administrative access point for managing resources within a specific subnet.

---

## Features

- **Windows 11 Virtual Machine** with static IP for consistent accessibility.
- **OpenSSH Extension** for easy remote access over SSH.
- **Auto-shutdown Schedule** to manage costs effectively.
- **Timezone Configuration** to match regional settings.
- Supports **accelerated networking** for enhanced performance.
- Fully customizable VM size, image SKU, and other settings.

---

## Usage

```hcl
module "vm_jumpwin" {  
  source              = "./modules/vm-jumpwin"  
  resource_group_name = azurerm_resource_group.rg[0].name  
  location            = var.regions[0]  
  vm_size             = var.vm_jump_size  
  sku                 = var.vm_jumpwin_sku  
  computer_name       = var.vm_jumpwin_hostname  
  admin_username      = var.vm_localadmin_user  
  admin_password      = var.vm_localadmin_pswd  
  vm_shutdown_hhmm    = var.vm_shutdown_hhmm  
  vm_shutdown_tz      = var.vm_shutdown_tz  
  subnet_id           = data.azurerm_subnet.snet_gw.id
  subnet_cidr         = data.azurerm_subnet.snet_gw.address_prefix
  shortregion         = var.shortregions[0]  
  tags                = var.labtags  

  depends_on = [  
    module.v_network,  
  ]  
}  
```

---

## Inputs

| **Name**              | **Description**                              | **Type**        | **Default**            | **Required** |
|-----------------------|----------------------------------------------|-----------------|------------------------|--------------|
| `resource_group_name` | Name of the resource group.                  | `string`        | n/a                    | Yes          |
| `location`            | Azure region for resources.                  | `string`        | n/a                    | Yes          |
| `vm_size`             | Size of the jumpbox VM.                      | `string`        | `"Standard_B2s"`       | No           |
| `sku`                 | Image SKU for the Windows VM.                | `string`        | `"win11-22h2-pro"`     | No           |
| `computer_name`       | Name of the virtual machine (hostname).      | `string`        | n/a                    | Yes          |
| `admin_username`      | Admin username for the VM.                   | `string`        | `"localadmin"`         | Yes          |
| `admin_password`      | Admin password for the VM.                   | `string`        | `"P@ssw0rd!234"`       | Yes          |
| `vm_shutdown_hhmm`    | Daily shutdown time in HHMM format.          | `string`        | `"0000"`               | No           |
| `vm_shutdown_tz`      | Timezone for VM shutdown.                    | `string`        | `"Central Standard Time"` | No       |
| `subnet_id`           | ID of the subnet where the VM connects.      | `string`        | n/a                    | Yes          |
| `subnet_cidr`         | CIDR block of the subnet for VM NIC.         | `string`        | n/a                    | Yes          |
| `shortregion`         | Short region identifier (e.g., "usw").       | `string`        | `"void"`               | No           |
| `tags`                | Tags to apply to resources.                  | `map(string)`   | `{}`                   | No           |

---

## Outputs

| **Name**                 | **Description**                                 |
|--------------------------|-------------------------------------------------|
| `vm_jumpwin_public_ip`   | Public IP address of the Windows jumpbox VM.    |
| `vm_jumpwin_public_dns`  | Public DNS name of the Windows jumpbox VM.      |

---

## Requirements

- **Dependencies**: Requires the `v-network` module for subnet and network configuration.

---

This module is intended for use in test or lab environments, providing a secure and reliable Windows-based jumpbox for remote administration. Be sure to manage credentials securely and follow best practices for securing access.