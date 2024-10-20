# Azure Network Configuration (v-network.tf)

This repository contains Terraform code to deploy a virtual network setup in Azure with multiple subnets, gateways, and high availability components.

## Overview

The configuration creates the following network components across two regions:

1. **Virtual Networks**: Two virtual networks (`vnet`), one per region.

2. **Subnets**: Each network includes:
   - **Gateway Subnet (`snet_gw`)**: For VPN or NAT gateways.
   - **ADDC Subnet (`snet_addc`)**: Hosts Active Directory Domain Controllers.
   - **Database Subnet (`snet_db`)**: For SQL database services.
   - **Application Subnet (`snet_app`)**: For applications.
   - **Client Subnet (`snet_client`)**: For clients or external-facing services.

3. **Public IPs**: Static IPs for gateways, SQL servers, and NAT.

4. **NAT Gateway**: Enables outbound traffic from application and database subnets.

5. **Load Balancers**: For SQL High Availability (HA) across both regions.

6. **Routing**: Routes traffic to the internet via custom route tables.

7. **Network Peering**: Enables communication between the virtual networks.

8. **Network Security Groups (NSGs)**: Control traffic flow with rules:
   - **Outbound Internet**: Allows outgoing internet traffic.
   - **Inbound SSH/RDP**: Enables remote access.
   - **Internal Traffic**: Allows communication within the network.

9. **NSG Associations**: Applied to `snet_client` subnets to enforce rules.

## Network Variables

- `var.shortregions`: Short codes for regions (e.g., `usw`, `use`).
- `var.regions`: Full region names (e.g., `westus`, `eastus`).
- `var.address_spaces`: CIDR blocks for vNet address spaces (e.g., `10.1.0.0/24`, `10.1.1.0/24`).

## Network Configuration Table

| **Address Space**  | **Subnet**            | **Resources**                              |
|--------------------|-----------------------|--------------------------------------------|
| 10.1.0.0/24        | **Gateway Subnet**    | **usw-nat-gateway** <br>- Public IP: usw-gateway-ip (Static) |
|                    | **ADDC Subnet**       | **usw-addc-vm** <br>- NIC: usw-addc-nic <br>- Private IP: 10.1.0.5 <br>- Public IP: usw-addc-pip (Static) |
|                    | **Database Subnet**   | **usw-sqlha-lb** <br>- Frontend IP: 10.1.0.20 (Static) <br>**usw-sqlha0-vm** <br>- NIC: usw-sqlha0-nic <br>- Private IP: 10.1.0.9 <br>- Public IP: usw-sqlha0-public-ip (Static) <br>**usw-sqlha1-vm** <br>- NIC: usw-sqlha1-nic <br>- Private IP: 10.1.0.10 <br>- Public IP: usw-sqlha1-public-ip (Static) |
|                    | **Application Subnet**| None                                       |
|                    | **Client Subnet**     | None                                       |
| 10.1.1.0/24        | **Gateway Subnet**    | **use-nat-gateway** <br>- Public IP: use-gateway-ip (Static) |
|                    | **ADDC Subnet**       | **use-addc-vm** <br>- NIC: use-addc-nic <br>- Private IP: 10.1.1.5 <br>- Public IP: use-addc-pip (Static) |
|                    | **Database Subnet**   | **use-sqlha-lb** <br>- Frontend IP: 10.1.1.20 (Static) <br>**use-sqlha0-vm** <br>- NIC: use-sqlha0-nic <br>- Private IP: 10.1.1.9 <br>- Public IP: use-sqlha0-public-ip (Static) <br>**use-sqlha1-vm** <br>- NIC: use-sqlha1-nic <br>- Private IP: 10.1.1.10 <br>- Public IP: use-sqlha1-public-ip (Static) |
|                    | **Application Subnet**| None                                       |
|                    | **Client Subnet**     | None                                       |

This table outlines the Azure network design with virtual networks, subnets, NAT gateways, load balancers, and high availability VMs across regions.
