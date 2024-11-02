<#
.SYNOPSIS
    Sets up domain accounts, including creating Organizational Units (OUs) and adding users.
.DESCRIPTION
    This script automates the process of creating OUs, svc_accounts, users, & adding to relevant AD groups.
.PARAMETER domain_name
    The Fully Qualified Domain Name (FQDN) of the domain (e.g., "starwars.lan").
.PARAMETER temp_admin_pswd
    A temporary password to be used for newly created domain users.
.NOTES
    This script is intended for non-production use in a lab environment. 
    It assumes the Active Directory module is available on the machine running the script.
#>

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$temp_admin_pswd
)

# Split the domain name into its components to construct the distinguished name (DN) path
$split_domain = $domain_name.Split(".")
$dn_path = ($split_domain | ForEach-Object { "DC=$_" }) -join ","

# Ensure the logs directory exists
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force }

# Start logging
Start-Transcript -Path 'C:\BUILD\Logs\transcript-Add_DomainAccounts.log' -Force

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

# Define users to be added
$users = @(
    @{Name = "mando"; GivenName = "Din"; Surname = "Djarin"; Office = "Mandalore" },
    @{Name = "luke"; GivenName = "Luke"; Surname = "Skywalker"; Office = "Tatooine" },
    @{Name = "han"; GivenName = "Han"; Surname = "Solo"; Office = "Millennium Falcon" }
)

# Add users to the domain and assign them to the 'Domain Admins' group
foreach ($user in $users) {
    New-ADUser -Name $user.Name `
        -UserPrincipalName "$($user.Name)@$domain_name" `
        -SamAccountName $user.Name `
        -GivenName $user.GivenName `
        -Surname $user.Surname `
        -Office $user.Office `
        -AccountPassword (ConvertTo-SecureString "$temp_admin_pswd" -AsPlainText -Force) `
        -Enabled $true -ChangePasswordAtLogon $true -PassThru -Verbose |
    Add-ADGroupMember -Identity "Domain Admins" -Members $_ -Verbose
}

# Stop logging
Stop-Transcript
