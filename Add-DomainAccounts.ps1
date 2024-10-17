[CmdletBinding()]
# This script is used to set up domain accounts, including creating Organizational Units and adding users.
param ( 
    # The fully qualified domain name (FQDN) of the domain to manage.
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    # Temporary password to be used for newly created domain users.
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$temp_admin_pswd,
    # Username for the SQL service account.
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_user,
    # Password for the SQL service account.
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_pswd
)

# Split the domain name into its components to construct the distinguished name (DN) path.
$split_domain = $domain_name.Split(".")
# Construct DN path from split domain components
$dn_path = ($split_domain | ForEach-Object { "DC=$_" }) -join ","

# Ensure the logging directory exists, create it if not already present.
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { 
    New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force 
}

# Start transcript logging for all actions in the script to help with auditing.
Start-Transcript -Path 'C:\BUILD\Logs\transcript-Add_DomainUsers.log'

# Import Active Directory module to use AD-related cmdlets
Import-Module ActiveDirectory

# Create a new Organizational Unit (OU) named 'Servers' in the domain if it does not already exist.
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Servers'" -SearchBase "$dn_path")) {
    New-ADOrganizationalUnit -Name 'Servers' -Path "$dn_path" -Description 'OU for Server objects' -Verbose
}

# Create new AD user for SQL service account with specified details
New-ADUser `
    -SamAccountName $sql_svc_acct_user `
    -Name 'SVC_SQL' `
    -GivenName 'SQL' `
    -Surname 'SERVICE ACCOUNT' `
    -UserPrincipalName "$sql_svc_acct_user@$domain_name" `
    -AccountPassword (ConvertTo-SecureString "$sql_svc_acct_pswd" -AsPlainText -Force) `
    -Enabled $true `
    -Verbose

# Set password options and other properties for the SQL service account
Set-ADUser -Identity $sql_svc_acct_user `
    -PasswordNeverExpires $true `
    -ChangePasswordAtLogon $false `
    -CannotChangePassword $true `
    -Description 'SQL Service Account' `
    -DisplayName 'SQL Service Account'

# Create new AD user for SQL installation with specified details
New-ADUser `
    -SamAccountName 'sqlinstall' `
    -Name 'sqlinstall' `
    -GivenName 'SQL' `
    -Surname 'SQL INSTALLER' `
    -UserPrincipalName "sqlinstall@$domain_name" `
    -AccountPassword (ConvertTo-SecureString "$sql_svc_acct_pswd" -AsPlainText -Force) `
    -Enabled $true `
    -Verbose

# Set password options and other properties for the SQL installation user.
Set-ADUser -Identity 'sqlinstall' `
    -PasswordNeverExpires $true `
    -ChangePasswordAtLogon $false `
    -CannotChangePassword $true `
    -Description 'SQL Install Account' `
    -DisplayName 'SQL Install Account'

# Add newly created SQL install user to 'Domain Admins' group (more permission than required)
Add-ADGroupMember -Identity "Domain Admins" -Members 'sqlinstall'

# Create a new Organizational Unit (OU) named 'Service_Accounts' in the domain if it does not already exist.
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Service_Accounts'" -SearchBase "$dn_path")) {
    New-ADOrganizationalUnit -Name 'Service_Accounts' -Path "$dn_path" -Description 'OU for Service_Accounts' -Verbose
}

# Define the array of users to be created in the domain.
$users = @(
    @{Name="mando"; GivenName="Din"; Surname="Djarin"; Office="Mandalore"},
    @{Name="luke"; GivenName="Luke"; Surname="Skywalker"; Office="Tatooine"},
    @{Name="han"; GivenName="Han"; Surname="Solo"; Office="Millennium Falcon"}
)

# Create each user in the array and add them to the Domain Admins group.
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

# Stop transcript
Stop-Transcript