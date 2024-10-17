# Azure Multi-Region Lab Environment

This repository provides a Terraform configuration for deploying a multi-region Azure lab environment. The project is designed to set up an infrastructure with SQL High Availability (SQLHA) using Windows Server Failover Cluster (WSFC) and Active Directory Domain Controllers (ADDC) across two Azure regions.

## Overview

The lab environment includes the following features:

- A single resource group to host all resources
- Infrastructure provisioned across two Azure regions
- Virtual Network setup with multiple subnets (gateways, domain controllers, applications, databases, & clients)
- Two Active Directory Domain Controllers (one per region)
- SQLHA with Always On Availability Groups configured in each regions
- Load Balancers for SQLHA listener configured for 'SingleSubnet'
- Custom scripts for domain setup, cluster configuration, and SQL management

## Components

1. **Resource Group**: A single Azure resource group to host all resources

2. **Networking**: vNets & subnets in two regions, includes peering, NAT gateways, and route tables

3. **Active Directory**: Domain Controller in each region configured from scripts to promote and synchronize domain

4. **SQL High Availability (Ready for Disaster Recovery Scenarios)**
   - SQL HA clusters/AG are set up in a 'SingleSubnet' configuration using a load balancer
   - SQL Virtual Machines are configured with Always On Availability Groups
   - Load balancers are set up to manage SQLHA listener traffic
   - SQL Virtual Machine Groups and WSFC Domain Profiles are configured for HA setup

## Project Structure

- **tfvars file**: Contains the secret values for authentication (example, keep yours secure!)
- **providers.tf**: Specifies the required Terraform and provider versions
- **v-network.tf**: Virtual Network and subnet configurations for both regions
- **main.tf**: Main Terraform configuration file containing all resources for the Azure lab environment
- **variables.tf**: Contains all variables used throughout the Terraform configuration, including sensitive information placeholders
- **scripts**: PowerShell scripts for setting up domain controllers, configuring clusters, and setting up SQL permissions

## Important Notes

- **Lab Environment**: This setup is intended as a lab environment for learning/testing scenarios
- **Single Resource Group**: All resources are placed in a single resource group for simplicity
- **Security Considerations**: Public IPs for SSH, default passwords, etc. should not be used in production
- **Sensitive Data**: Ensure your `terraform.tfvars` file is not committed to the repository to keep secrets safe
- **.gitignore**: Use the included `.gitignore` file to manage `commit` & `push`

## Prerequisites

- **Terraform**: v1.6.0 or higher
- **Azure Subscription**: Active subscription with necessary privileges
- **Service Principal**: Credentials for deploying resources in Azure
- **PowerShell**: For running custom scripts locally

## Deployment Steps

1. **Clone the Repository**:
   ```powershell
   git clone https://github.com/bentman/TerraformSQLHA
   pushd .\TerraformSQLHA
   ```

2. **Set Up Environment Variables**: Create a `terraform.tfvars` file with the following confidential information:
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

6. **Access Resources**: Use the generated public IPs to access domain controllers and SQL servers for customization.

## Cleanup

To remove all resources created by this configuration, run:
```sh
terraform destroy
```

## Helpful Links

- [Terraform Azure | HashiCorp](https://developer.hashicorp.com/terraform/tutorials/azure-get-started)
- [Terraform Azure | Microsoft](https://learn.microsoft.com/en-us/azure/developer/terraform/)
- [Create on-premises virtual network in Azure using Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/hub-spoke-on-prem)
- [Quickstart: Create a lab in Azure DevTest Labs using Terraform](https://learn.microsoft.com/en-us/azure/devtest-labs/quickstarts/create-lab-windows-vm-terraform)
- [Quickstart: Use Terraform to create a Windows VM - Azure Virtual Machines](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-terraform)
- [Deploying an Azure Windows VM using Terraform IaC](https://www.c-sharpcorner.com/article/deploying-an-azure-windows-vm-using-terraform-iac/)
- [Azure - Provisioning a Windows Virtual Machine using Terraform](https://www.patrickkoch.dev/posts/post_12/)
- [The Infrastructure Developer's Guide to Terraform: Azure Edition](https://cloudacademy.com/learning-paths/terraform-on-azure-01-1-2658/)
- [Terraform on Azure | Udemy](https://www.udemy.com/course/terraform-on-azure/)

## Contributions
Contributions are welcome. Please open an issue or submit a pull request if you have any suggestions, questions, or would like to contribute to the project.

### GNU General Public License
This script is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this script. If not, see <https://www.gnu.org/licenses/>.