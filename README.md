# Azure SQL High-Availability Multi-Region Lab

## Overview
This project contains Terraform configurations to deploy a multi-region Azure lab environment for SQL High Availability (SQLHA) using Active Directory Domain Controllers (ADDC) and Windows Server Failover Clustering (WSFC) across two Azure regions. This setup is designed for testing and educational purposes.

---

## Prerequisites
- **Terraform** v1.6.0+
- **AzureRM Provider** v4.0+
- **Azure Subscription** with necessary permissions
- **Service Principal** for authentication
- **PowerShell** for custom domain and SQL configuration scripts

---

## Project Structure
- `terraform.tfvars`: Contains sensitive authentication secrets.
- `providers.tf`: Specifies provider versions.
- `main.tf`: Main Terraform configuration file.
- `variables.tf`: Variables used across the configuration.
- `./modules/`: Contains sub-modules for modular configuration (e.g., `vm-addc`, `vm-sql`).
- `./scripts.ps1`: PowerShell scripts for domain setup, clustering, and SQL configurations.

---

## Quick Start
1. **Clone the Repository**:
   ```powershell
   git clone https://github.com/bentman/TerraformSQLHA
   cd .\TerraformSQLHA
   ```

2. **Set Up Environment Variables**: 
   Copy `example_terraform.tfvars` to `terraform.tfvars` and fill in the required details:
   ```hcl
   arm_tenant_id       = "YourTenantId"
   arm_subscription_id = "YourSubscriptionId"
   arm_client_id       = "YourServicePrincipalId"
   arm_client_secret   = "YourServicePrincipalSecret"
   ```
   **Note**: Ensure comments are removed to avoid syntax errors.

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

6. **Access Resources**: You can access resources using the generated public IPs provided in the outputs.

---

## Cleanup
To remove all created resources:
   ```powershell
   terraform destroy
   ```

---

## Networking Configuration
- **Two Virtual Networks (VNets)**: One per region, with peering between them for cross-region traffic.
- **Multiple Subnets** for different roles:
  - **Gateway Subnet**: For VPN or other gateway requirements.
  - **ADDC Subnet**: Hosts Active Directory Domain Controllers.
  - **Database Subnet**: Hosts SQL Server instances.
  - **Application Subnet**: For application servers if needed.
  - **Client Subnet**: For client machines or jump servers.
- **Static Public IPs** for ADDC and SQL servers for consistent external access.
- **Network Security Groups (NSGs)** to manage security rules.
- **Load Balancers** for SQLHA listener traffic.
- **Network Peering** for secure inter-region communication.

---

## Network Configuration Table

| **Address Space** | **Subnet**          | **Resources**                              |
|-------------------|---------------------|--------------------------------------------|
| **10.1.0.0/24**   | **Gateway Subnet**  | |
|                   | **ADDC Subnet**     | **usw-addc-vm** <br> - NIC: `usw-addc-nic` <br> - Private IP: 10.1.0.5 <br> - Public IP: `usw-addc-pip` (Static) |
|                   | **Database Subnet** | **usw-sqlha-lb** <br> - Frontend IP: 10.1.0.20 (Static) <br> **usw-sqlha0-vm** <br> - NIC: `usw-sqlha0-nic` <br> - Private IP: 10.1.0.9 <br> - Public IP: `usw-sqlha0-public-ip` (Static) <br> **usw-sqlha1-vm** <br> - NIC: `usw-sqlha1-nic` <br> - Private IP: 10.1.0.10 <br> - Public IP: `usw-sqlha1-public-ip` (Static) |
| **10.1.1.0/24**   | **Gateway Subnet**  | |
|                   | **ADDC Subnet**     | **use-addc-vm** <br> - NIC: `use-addc-nic` <br> - Private IP: 10.1.1.5 <br> - Public IP: `use-addc-pip` (Static) |
|                   | **Database Subnet** | **use-sqlha-lb** <br> - Frontend IP: 10.1.1.20 (Static) <br> **use-sqlha0-vm** <br> - NIC: `use-sqlha0-nic` <br> - Private IP: 10.1.1.9 <br> - Public IP: `use-sqlha0-public-ip` (Static) <br> **use-sqlha1-vm** <br> - NIC: `use-sqlha1-nic` <br> - Private IP: 10.1.1.10 <br> - Public IP: `use-sqlha1-public-ip` (Static) |

---

## Important Notes
- **Lab Environment**: This configuration is for learning and testing purposes. It is not intended for production environments.
- **Security Considerations**: Use strong passwords, restrict access to public IPs, and carefully manage network security groups.
- **Sensitive Data**: `terraform.tfvars` contains sensitive information; avoid committing it to version control.
- **.gitignore**: Use the included `.gitignore` file to exclude sensitive data and unnecessary files from your repository.

---

### Contributions

Contributions are welcome! Please open an issue or submit a pull request if you have suggestions or enhancements.

### License

This script is distributed without any warranty; use at your own risk.
This project is licensed under the GNU General Public License v3. 
See [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html) for details.