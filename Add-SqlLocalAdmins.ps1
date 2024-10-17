[CmdletBinding()]
param ( 
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_svc_acct_user
)
# Check if the directory 'C:\BUILD\Logs\' exists, and create it if it does not
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\' -ItemType Directory -Force }
# Start a transcript to log all activities to the specified path
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlLocalAdmins.log'
# Test the network connection to the specified domain name and port 9389
Test-NetConnection -Computername $domain_name -Port 9389
# Add the SQL installation account to the local Administrators group
Add-LocalGroupMember -Group 'Administrators' -Member "sqlinstall@$domain_name" -Verbose
# Add the SQL service account to the local Administrators group
Add-LocalGroupMember -Group 'Administrators' -Member "$sql_svc_acct_user@$domain_name" -Verbose
# Stop the transcript
Stop-Transcript
