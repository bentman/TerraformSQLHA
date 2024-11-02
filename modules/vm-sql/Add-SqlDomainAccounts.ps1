<#
.SYNOPSIS
    Sets up domain accounts, including creating Organizational Units (OUs) and adding users.
.DESCRIPTION
    This script automates the process of creating OUs, svc_accounts, users, & adding to relevant AD groups.
.PARAMETER domain_name
    The Fully Qualified Domain Name (FQDN) of the domain (e.g., "starwars.lan").
.PARAMETER temp_admin_pswd
    A temporary password to be used for newly created domain users.
.PARAMETER sql_svc_acct_user
    The username for the SQL service account to be created.
.PARAMETER sql_svc_acct_pswd
    The password for the SQL service account.
.NOTES
    This script is intended for non-production use in a lab environment. 
    It assumes the Active Directory module is available on the machine running the script.
#>

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_user,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_pswd
)

# Split the domain name into its components to construct the distinguished name (DN) path
$split_domain = $domain_name.Split(".")
$dn_path = ($split_domain | ForEach-Object { "DC=$_" }) -join ","

# Ensure the logs directory exists
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force }

# Start logging
Start-Transcript -Path 'C:\BUILD\Logs\transcript-Add_SqlDomainAccounts.log' -Force

# Import the Active Directory module
Import-Module ActiveDirectory

# Create the 'Servers' OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Servers'" -SearchBase "$dn_path")) {
    New-ADOrganizationalUnit -Name 'Servers' -Path "$dn_path" -Description 'OU for Server objects' -Verbose
}

# Create the 'SVC_Accounts' OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'SVC_Accounts'" -SearchBase "$dn_path")) {
    New-ADOrganizationalUnit -Name 'SVC_Accounts' -Path "$dn_path" -Description 'OU for Service Accounts' -Verbose
}

# Construct the Distinguished Name (DN) path for 'SVC_Accounts'
$svc_accounts_ou_path = "OU=SVC_Accounts,$dn_path"

# Create SQL service account in the 'SVC_Accounts' OU
New-ADUser `
    -SamAccountName $sql_svc_acct_user `
    -Name 'SVC_SQL' `
    -GivenName 'SQL' `
    -Surname 'SERVICE ACCOUNT' `
    -UserPrincipalName "$sql_svc_acct_user@$domain_name" `
    -Path $svc_accounts_ou_path `
    -AccountPassword (ConvertTo-SecureString "$sql_svc_acct_pswd" -AsPlainText -Force) `
    -Enabled $true -Verbose

Set-ADUser -Identity $sql_svc_acct_user `
    -PasswordNeverExpires $true `
    -ChangePasswordAtLogon $false `
    -CannotChangePassword $true `
    -Description 'SQL Service Account' `
    -DisplayName 'SQL Service Account'

# Create SQL installation account in the 'SVC_Accounts' OU
New-ADUser `
    -SamAccountName 'sqlinstall' `
    -Name 'sqlinstall' `
    -GivenName 'SQL' `
    -Surname 'SQL INSTALLER' `
    -UserPrincipalName "sqlinstall@$domain_name" `
    -Path $svc_accounts_ou_path `
    -AccountPassword (ConvertTo-SecureString "$sql_svc_acct_pswd" -AsPlainText -Force) `
    -Enabled $true -Verbose

Set-ADUser -Identity 'sqlinstall' `
    -PasswordNeverExpires $true `
    -ChangePasswordAtLogon $false `
    -CannotChangePassword $true `
    -Description 'SQL Install Account' `
    -DisplayName 'SQL Install Account'

Add-ADGroupMember -Identity "Domain Admins" -Members 'sqlinstall'

# Stop logging
Stop-Transcript
