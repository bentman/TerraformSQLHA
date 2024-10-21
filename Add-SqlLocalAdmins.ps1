<#
.SYNOPSIS
    Adds SQL-related accounts to the local Administrators group on a Windows server.

.DESCRIPTION
    This script ensures that the specified SQL service and installation accounts 
    are added to the local Administrators group. It also checks network connectivity 
    to the domain and logs all activities.

.PARAMETER domain_name
    The domain name (FQDN) to which the server belongs.

.PARAMETER sql_svc_acct_user
    The SQL service account user to be added to the local Administrators group.

.EXAMPLE
    ./Add-SqlLocalAdmins.ps1 -domain_name "contoso.com" -sql_svc_acct_user "sqlservice"
.NOTES
    This script is intended for use in a lab or testing environment.
#>

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_user
)

# Ensure the 'C:\BUILD\Logs\' directory exists; create it if it does not
if (!(Test-Path -Path 'C:\BUILD\Logs\')) {
    New-Item -Path 'C:\BUILD\' -ItemType Directory -Force
}

# Start a transcript to log all activities
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlLocalAdmins.log'

# Test network connectivity to the domain on port 9389 (Active Directory Web Services)
Test-NetConnection -ComputerName $domain_name -Port 9389

# Add the SQL installation account to the local Administrators group
Add-LocalGroupMember -Group 'Administrators' -Member "sqlinstall@$domain_name" -Verbose

# Add the SQL service account to the local Administrators group
Add-LocalGroupMember -Group 'Administrators' -Member "$sql_svc_acct_user@$domain_name" -Verbose

# Stop the transcript
Stop-Transcript
