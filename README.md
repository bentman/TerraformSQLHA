Here's a revised version of the README.md that incorporates the network configuration table while maintaining conciseness:

# Azure SQL High-Availability Multi-Region Lab
---
## Overview
- Terraform configuration for multi-region Azure lab environment
- Includes Active Directory Domain Controllers (ADDC) and SQL High Availability (SQLHA)
- Uses Windows Server Failover Clustering (WSFC) across two Azure regions
---
## Networking Configuration
- Two Virtual Networks, one per region
- Multiple subnets for different purposes:
  - Gateway Subnet
  - ADDC Subnet
  - Database Subnet
  - Application Subnet
  - Client Subnet
- Static Public IPs for ADDC and SQL servers
- Network Security Groups (NSGs) for security rules
- Load Balancers for SQLHA listener traffic
- Network Peering for secure inter-region communication
---
## **Network Configuration Table**
| **Address Space**  | **Subnet**            | **Resources**                              |
|--------------------|-----------------------|--------------------------------------------|
| **10.1.0.0/24**    | **Gateway Subnet**    | **usw-nat-gateway** <br>- Public IP: `usw-gateway-ip` (Static) |
|                    | **ADDC Subnet**       | **usw-addc-vm** <br>- NIC: `usw-addc-nic` <br>- Private IP: 10.1.0.5 <br>- Public IP: `usw-addc-pip` (Static) |
|                    | **Database Subnet**   | **usw-sqlha-lb** <br>- Frontend IP: 10.1.0.20 (Static) <br> **usw-sqlha0-vm** <br>- NIC: `usw-sqlha0-nic` <br>- Private IP: 10.1.0.9 <br>- Public IP: `usw-sqlha0-public-ip` (Static) <br> **usw-sqlha1-vm** <br>- NIC: `usw-sqlha1-nic` <br>- Private IP: 10.1.0.10 <br>- Public IP: `usw-sqlha1-public-ip` (Static) |
| **10.1.1.0/24**    | **Gateway Subnet**    | **use-nat-gateway** <br>- Public IP: `use-gateway-ip` (Static) |
|                    | **ADDC Subnet**       | **use-addc-vm** <br>- NIC: `use-addc-nic` <br>- Private IP: 10.1.1.5 <br>- Public IP: `use-addc-pip` (Static) |
|                    | **Database Subnet**   | **use-sqlha-lb** <br>- Frontend IP: 10.1.1.20 (Static) <br> **use-sqlha0-vm** <br>- NIC: `use-sqlha0-nic` <br>- Private IP: 10.1.1.9 <br>- Public IP: `use-sqlha0-public-ip` (Static) <br> **use-sqlha1-vm** <br>- NIC: `use-sqlha1-nic` <br>- Private IP: 10.1.1.10 <br>- Public IP: `use-sqlha1-public-ip` (Static) |
---
## Project Structure
- `terraform.tfvars`: Authentication secrets
- `providers.tf`: Provider versions
- `main.tf`: Main configuration
- `variables.tf`: Variables and placeholders
- `.\scripts.ps1`: PowerShell scripts for domain setup, clustering, and SQL configurations
---
## Prerequisites
- Terraform v1.6.0+
- AzureRM v4.0+
- Azure subscription with necessary permissions
- Service Principal for authentication
- PowerShell for custom scripts
---
## Quick Start
1. **Clone the Repository**:
   ```powershell
   git clone https://github.com/bentman/TerraformSQLHA
   cd .\TerraformSQLHA
   ```
2. **Set Up Environment Variables**: 
   Copy `example_terraform.tfvars` to `terraform.tfvars`, edit to provide...
   - `arm_tenant_id`  
   - `arm_subscription_id`  
   - `arm_client_id`  
   - `arm_client_secret`
3. **Initialize Terraform**:
   ```powershell
   terraform init
   ```
4. **Plan the Deployment**:
   ```powershell
   terraform plan
   ```
5. **Apply the Configuration**:
   ```powershell
   terraform apply
   ```
6. Access resources via generated public IPs
---
## Cleanup
Remove all created resources
   ```powershell
   terraform destroy
   ```
---
## **Important Notes**
- **Lab Environment**: Intended for learning and testing scenarios (not production).  
- **Security Considerations**: Use strong passwords and manage public IPs carefully.  
- **Sensitive Data**: Exclude `terraform.tfvars` from version control to secure credentials.  
- **.gitignore**: Use the included `.gitignore` to manage version control effectively.
---
## Contributions
Contributions are welcome. Please open an issue or submit a pull request if you have any suggestions, questions, or would like to contribute to the project.
---
### GNU General Public License
This script is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this script. If not, see <https://www.gnu.org/licenses/>.