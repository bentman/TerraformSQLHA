<#
.SYNOPSIS
    Joins a SQL Server to the specified domain.
.DESCRIPTION
    This script joins the local machine to an Active Directory domain using the provided credentials.
    It does not perform a restart. Restart should be managed externally (e.g., Terraform).
.PARAMETER domain_name
    The Fully Qualified Domain Name (FQDN) of the domain (e.g., "starwars.lan").
.PARAMETER domain_netbios_name
    The NetBIOS name of the domain (e.g., "STARWARS").
.PARAMETER domain_admin_user
    The domain admin username (without domain prefix).
.PARAMETER domain_admin_pswd
    The password for the domain admin account.
.NOTES
    This script is intended for use in a lab or testing environment.
#>

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_netbios_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_admin_user,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_admin_pswd
)

# Ensure the logs directory exists
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force }

# Start logging the process
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlDomainJoin.log' -Force

# Convert the domain admin password to a secure string
$domainPswd = ConvertTo-SecureString $domain_admin_pswd -AsPlainText -Force

# Create the credential object
$domainCred = New-Object System.Management.Automation.PSCredential ( $domain_admin_user, $domainPswd )

# Join the server to the domain without restarting
Add-Computer -DomainName $domain_name -Credential $domainCred -Force

# Stop logging
Stop-Transcript
