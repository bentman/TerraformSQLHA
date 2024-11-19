# .\terraform.tfvars
/*#################### SECRETS ####################
#####  Declare confidential variables here
#####  Store secret values in *.tfvars file
#####  Check .gitignore in repo for details
########## SECRETS
arm_tenant_id       = "YourTenantId"               // azure tenant id
arm_subscription_id = "YourSubscriptionId"         // azure subscription id
arm_client_id       = "YourServicePrincipalId"     // azure service principal id
arm_client_secret   = "YourServicePrincipalSecret" // azure service principal secret

#################### ENABLE MODULES ####################
enable_vm_jumpwin = false
enable_vm_jumplin = false
enable_vm_addc    = true
enable_vm_sql     = true

#################### VALUES ####################
########## RESOURCE VALUES
# NOTE: Regions require instance & capacity for the vm 'size'
regions      = ["westus", "eastus"] // defaults to '["westus", "eastus"]'
shortregions = ["usw", "use"]       // defaults to '["usw", "use"]'
labtags = {
  "source"      = "terraform"
  "project"     = "learn-sqlha"
  "environment" = "lab-sqlha"
}

########## NETWORK VALUES
address_spaces = ["10.1.0.0/24", "10.1.1.0/24"] // defaults to '["10.1.0.0/24", "10.1.1.0/24"]'

########## SHUTDOWN VALUES
vm_shutdown_hhmm = "0600"                   // defaults to "0600"
vm_shutdown_tz   = "Dateline Standard Time" // defaults to "Dateline Standard Time" (UTC)

########## VM JUMPBOX VALUES
vm_jump_size        = "Standard_B2s_v2" // vm jump size 'Standard_B2s_v2'
vm_jump_adminuser   = "localadmin"      // vm jumpbox local admin username
vm_jump_adminpswd   = "P@ssw0rd!234"    // vm jumpbox local admin password
vm_jumpwin_hostname = "jumpwin007"      // fails if not unique in public DNS for region
vm_jumpwin_sku      = "win11-23h2-pro"
vm_jumplin_hostname = "jumpwin008" // fails if not unique in public DNS for region
vm_jumplin_sku      = "22_04-lts"

########## VM ADDC VALUES
vm_addc_size      = "Standard_B2s_v2"
domain_admin_user = "domainadmin"  // domain admin username
domain_admin_pswd = "P@ssword!234" // domain admin password

########## DOMAIN VALUES
domain_name         = "sqlhalab.lan" // ad fqdn domain name
domain_netbios_name = "SQLHALAB"     // ad netbios domain name
safemode_admin_pswd = "P@ssword!234" // domain safemode password
temp_admin_pswd     = "P@ssword!234" // added domain admins temp password

########## VM SQL VALUES
vm_sqlha_size       = "Standard_D2s_v4" // vm sqlha size
sql_localadmin_user = "localadmin"      // sql local admin username
sql_localadmin_pswd = "P@ssword!234"    // sql local admin password

########## SQLHA VALUES
sql_svc_acct_user = "svc_mssqlserver" // sql service username
sql_svc_acct_pswd = "P@ssword!234"    // sql service password
sql_sysadmin_user = "sqladmin"        // sql sysadmin username
sql_sysadmin_pswd = "P@ssword!234"    // sql sysadmin password ('P@ssword!234')
sql_disk_data     = 90                // GB SQL Disk - Data
sql_disk_logs     = 60                // GB SQL Disk - Logs
sql_disk_temp     = 30                // GB SQL Disk - Temp
*/
#################### NOTES ####################
# Instructions for generating a new Service Principal and Secret using PowerShell
#
# 1. Open PowerShell and run:
#    $sp = New-AzADServicePrincipal -DisplayName "Terraform" -Role "Contributor"
#    $sp.AppId 
#    $sp.PasswordCredentials.SecretText # Create Credential Secret
#
# Instructions for generating a new Service Principal and Secret using Azure CLI
#
# 1. Open a terminal and run:
#    az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<your-subscription-id>"
