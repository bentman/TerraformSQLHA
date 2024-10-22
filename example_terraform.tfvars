#################### SECRETS ####################
#####  Declare confidential variables here
#####  Store secret values in *.tfvars file
#####  Check .gitignore in repo for details
########## SECRETS
arm_tenant_id          = "YourTenantId"               // azure tenant id
arm_subscription_id    = "YourSubscriptionId"         // azure subscription id
arm_client_id          = "YourServicePrincipalId"     // azure service principal id
arm_client_secret      = "YourServicePrincipalSecret" // azure service principal secret
vm_localadmin_username = "YourAdminUsername"          // vm local admin username 'localadmin'
vm_localadmin_password = "YourAdminPassword"          // vm local admin password 'P@ssw0rd!234'

#################### VALUES ####################
########## RESOURCE VALUES
regions      = ["westus", "eastus"] // defaults to '["westus", "eastus"]'
shortregions = ["usw", "use"]       // defaults to '["usw", "use"]'
labtags = {
  "source"      = "terraform"
  "project"     = "learning"
  "environment" = "lab"
}

########## NETWORK VALUES
address_spaces = ["10.1.0.0/24", "10.2.0.0/24"] // defaults to '["10.1.0.0/24", "10.2.0.0/24"]'

########## VM VALUES
vm_addc_size     = "Standard_B2s_v2"       // vm addc size 'Standard_B2s_v2'
vm_sqlha_size    = "Standard_D2s_v4"       // vm sqlha size 'Standard_D2s_v4'
sql_disk_data    = 90                      // GB SQL Disk - Data
sql_disk_logs    = 60                      // GB SQL Disk - Logs
sql_disk_temp    = 30                      // GB SQL Disk - Temp
vm_shutdown_hhmm = "0000"                  // defaults to "0000"
vm_shutdown_tz   = "Central Standard Time" // defaults to "Pacific Standard Time"

########## DOMAIN VALUES
domain_name         = "sqlhalab.lan" // ad fqdn domain name
domain_netbios_name = "SQLHALAB"     // ad netbios domain name
domain_admin_user   = "domainadmin"  // domain admin username
domain_admin_pswd   = "P@ssword!234" // domain admin password ('P@ssword!234')
temp_admin_pswd     = "P@ssword!234" // domain admins added temp password ('P@ssword!234')
safemode_admin_pswd = "P@ssword!234" // domain safemode password ('P@ssword!234')

########## SQLHA VALUES
sql_localadmin_user = "localadmin"      // sql local admin username
sql_localadmin_pswd = "P@ssword!234"    // sql local admin password
sql_svc_acct_user   = "svc_mssqlserver" // sql service username
sql_svc_acct_pswd   = "P@ssword!234"    // sql service password ('P@ssword!234')
sql_sysadmin_user   = "sqladmin"        // sql sysadmin username ('sysadmin')
sql_sysadmin_pswd   = "P@ssword!234"    // sql sysadmin password ('P@ssword!234')

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
