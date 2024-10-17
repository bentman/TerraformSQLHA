# Azure Network Configuration (v-network.tf)

This repository contains Terraform configurations to create a virtual network setup in Azure with multiple subnets, NAT gateways, security rules, and network gateways.

## Overview

The Terraform configuration defines the following Azure networking components across two regions:

1. **Virtual Networks**: Two virtual networks (`vnet`) are created, each in a different Azure region. Each network has its own address space specified by `var.address_spaces`.

2. **Subnets**: Each virtual network contains the following subnets:
   - **Gateway Subnet (`snet_gw`)**: Used for the VPN gateway.
   - **AD Domain Controller Subnet (`snet_addc`)**: For hosting Active Directory Domain Controllers.
   - **Database Subnet (`snet_db`)**: Dedicated for database services.
   - **Application Subnet (`snet_app`)**: For hosting application workloads.
   - **Client Subnet (`snet_client`)**: Designated for client-facing services.

3. **Public IPs**: Static public IPs are created for the VPN gateways.

4. **NAT Gateway**: Each application and database subnet has a NAT gateway associated to allow outbound internet traffic.

5. **Routing**: Custom route tables are created to route traffic to the internet and associated with the appropriate subnets.

6. **Network Peering**: Virtual network peering is established between the two virtual networks to enable communication between them.

7. **Network Security Groups (NSGs)**: NSGs are used to control inbound and outbound traffic for each virtual network.
   - **Allow Internet Outbound**: Allows outbound traffic to the internet.
   - **Allow SSH/RDP**: Allows inbound SSH and RDP connections from the internet.
   - **Allow Internal Traffic**: Allows traffic between resources within the same virtual network.

8. **Security Group Associations**: The NSGs are associated with the `snet_client` subnets to enforce security rules.

## Network Variables
The following variables are used in the configuration:
- `var.shortregions`: Short codes for Azure regions (e.g., `eastus`, `westeurope`).
- `var.regions`: Full Azure region names.
- `var.address_spaces`: CIDR blocks defining the address spaces for the virtual networks.
