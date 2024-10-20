# **Azure Multi-Region Lab Environment**  

This repository provides a **Terraform configuration** for deploying a **multi-region Azure lab environment**. The infrastructure includes **SQL High Availability (SQLHA)** using **Windows Server Failover Clustering (WSFC)** and **Active Directory Domain Controllers (ADDC)** across two Azure regions.

---

## **Overview**  

The lab environment offers:  
- **Multi-region infrastructure** with deployments across **two Azure regions**.  
- **Two Resource Groups**: One per region to organize resources.  
- **Virtual Network setup** with multiple subnets (gateways, domain controllers, applications, databases, and clients).  
- **Two Active Directory Domain Controllers** (one per region).  
- **SQLHA** with Always On Availability Groups and load balancers using **‘SingleSubnet’** design.  
- **Custom scripts**: For domain setup, cluster configuration, and SQL management tasks.

---

## **Components**

1. **Resource Groups**  
   - Two resource groups: One per region to manage resources separately.

2. **Networking Configuration** (now integrated into `main.tf`):  
   - **Virtual Networks**: One vNet per region.  
   - **Subnets**:  
     - **Gateway Subnet** (`snet_gw`): For VPN/NAT gateways.  
     - **ADDC Subnet** (`snet_addc`): For Active Directory Domain Controllers.  
     - **Database Subnet** (`snet_db`): For SQL services.  
     - **Application Subnet** (`snet_app`): For application workloads.  
     - **Client Subnet** (`snet_client`): For external-facing services.  
   - **Public IPs**: Static IPs for gateways, SQL servers, and NAT gateways.  
   - **NAT Gateways**: Provide outbound internet traffic for application and database subnets.  
   - **Load Balancers**: Manage SQLHA listener traffic across regions.  
   - **Route Tables**: Custom routes for internet access.  
   - **Network Peering**: Enable secure communication between regions.  
   - **NSGs**: Define security rules for remote access, internal communication, and outbound traffic.  
   - **NSG Associations**: Applied to specific subnets for security enforcement.

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

## **Project Structure**

- **`terraform.tfvars`**: Holds secret values for authentication (keep secure).  
- **`providers.tf`**: Specifies required Terraform and provider versions.  
- **`main.tf`**: Main Terraform configuration, including all networking and resources.  
- **`variables.tf`**: Contains all variables and sensitive data placeholders.  
- **`.\scripts.ps1`**: PowerShell scripts for domain setup, clusters, and SQL configurations.

---

## **Important Notes**

- **Lab Environment**: Designed for learning and testing scenarios.  
- **Security Considerations**: Use strong passwords and manage public IPs carefully.  
- **Sensitive Data**: Exclude `terraform.tfvars` from version control to secure credentials.  
- **.gitignore**: Use the included `.gitignore` to manage version control effectively.

---

## **Prerequisites**

- **Terraform**: v1.6.0 or higher.  
- **Azure Subscription**: With necessary privileges.  
- **Service Principal**: For authentication with Azure.  
- **PowerShell**: For executing custom scripts.

---

## **Deployment Steps**

1. **Clone the Repository**:
   ```powershell
   git clone https://github.com/bentman/TerraformSQLHA
   cd .\TerraformSQLHA
   ```

2. **Set Up Environment Variables**: Create a `terraform.tfvars` file with:
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

6. **Access Resources**: Use the generated public IPs to connect to domain controllers and SQL servers.

---

## **Cleanup**

To remove all resources created by this configuration:
```sh
terraform destroy
```

---

## Contributions
Contributions are welcome. Please open an issue or submit a pull request if you have any suggestions, questions, or would like to contribute to the project.

### GNU General Public License
This script is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this script. If not, see <https://www.gnu.org/licenses/>.