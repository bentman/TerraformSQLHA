# VM Jumpbox Module (`vm_jumplin`)

This Terraform module deploys a **Linux-based jumpbox virtual machine (VM)**, specifically designed for administrative access. It includes a static IP assignment, auto-shutdown configuration, and script management for remote administration.

---

## Features

- **Ubuntu 22.04 LTS Virtual Machine** with static IP address for secure and reliable access.
- **Remote SSH Access**: Easily accessible with specified local credentials.
- **Script Deployment and Execution**: Allows for remote script copy and execution via a null resource.
- **Auto-shutdown Schedule**: Configurable shutdown times to optimize cost management.
- **Customizable Options**: Easily configure VM size, image SKU, and other settings.

---

## Usage

```hcl
module "vm_jumplin" {  
  source              = "./modules/vm-jumplin"  
  resource_group_name = azurerm_resource_group.rg[0].name  
  location            = var.regions[0]  
  shortregion         = var.shortregions[0]  
  subnet_id           = data.azurerm_subnet.snet_gw.id
  subnet_cidr         = data.azurerm_subnet.snet_gw.address_prefix
  vm_size             = var.vm_jump_size  
  sku                 = var.vm_jumplin_sku  
  computer_name       = var.vm_jumplin_hostname  
  admin_username      = var.vm_jump_adminuser  
  admin_password      = var.vm_jump_adminpswd  
  vm_shutdown_hhmm    = var.vm_shutdown_hhmm  
  vm_shutdown_tz      = var.vm_shutdown_tz  
  tags                = var.labtags  

  depends_on = [  
    module.v_network,  
  ]  
}
```

---

## Inputs

| **Name**              | **Description**                           | **Type**   | **Default**            | **Required** |
|-----------------------|-------------------------------------------|------------|------------------------|--------------|
| `resource_group_name` | Name of the resource group.               | `string`   | n/a                    | Yes          |
| `location`            | Azure region for resources.               | `string`   | n/a                    | Yes          |
| `vm_size`             | Size of the Linux VM.                     | `string`   | `"Standard_B2s_v2"`    | No           |
| `sku`                 | Image SKU for the Linux VM.               | `string`   | `"22_04-lts"`          | No           |
| `computer_name`       | Name of the virtual machine (hostname).   | `string`   | `"jumplin008"`         | No           |
| `admin_username`      | Admin username for the VM.                | `string`   | `"localadmin"`         | Yes          |
| `admin_password`      | Admin password for the VM.                | `string`   | `"P@ssw0rd!234"`       | Yes          |
| `subnet_id`           | Subnet ID where the VM will connect.      | `string`   | n/a                    | Yes          |
| `subnet_cidr`         | CIDR block of the subnet for VM NIC.      | `string`   | n/a                    | Yes          |
| `shortregion`         | Short region identifier (e.g., "usw").    | `string`   | `"void"`               | No           |
| `vm_shutdown_hhmm`    | Daily shutdown time in HHMM format.       | `string`   | `"0000"`               | No           |
| `vm_shutdown_tz`      | Timezone for VM shutdown.                 | `string`   | `"UTC"`                | No           |
| `tags`                | Tags to apply to resources.               | `map(string)` | `{}`                 | No           |

---

## Outputs

| **Name**                | **Description**                            |
|-------------------------|--------------------------------------------|
| `vm_jumplin_public_ip`  | Public IP address of the Linux jumpbox VM. |
| `vm_jumplin_public_dns` | Public DNS name of the Linux jumpbox VM.   |

---

## Requirements

- **Dependencies**: This module relies on the `v-network` module for networking configuration.

---

This module is intended for lab and testing environments, offering an accessible and isolated administrative point for managing your Azure resources. Ensure that credentials and sensitive data are handled securely.