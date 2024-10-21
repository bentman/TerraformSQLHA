<#
.SYNOPSIS
    Creates SQL logins and assigns them to the sysadmin role on a local SQL Server instance.
.DESCRIPTION
    This script creates several Windows-based SQL logins using the provided domain and user information.
    Each login is added to the sysadmin server role, granting administrative permissions in SQL Server.
.PARAMETER domain_netbios_name
    The NetBIOS name of the domain.
.PARAMETER domain_admin
    The domain administrator account to be added as a SQL login with sysadmin privileges.
.PARAMETER sql_sysadmin_user
    The SQL sysadmin user to authenticate with the local SQL Server instance.
.PARAMETER sql_sysadmin_pswd
    The password for the SQL sysadmin user used to authenticate with SQL Server.
.NOTES
    This script is intended for use in a lab or testing environment.
#>

[CmdletBinding()]
param ( 
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_netbios_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_admin,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_sysadmin_user,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_sysadmin_pswd
)

# Ensure the 'C:\BUILD\Logs\' directory exists; create it if it does not
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\' -ItemType Directory -Force }

# Start a transcript to log all activities
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlSysAdmins.log'

# Test network connectivity to the local SQL Server instance (default port 1433)
Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 1433

# Define the SQL script to create logins and assign them to the sysadmin role
$sqlAdmin = @"
CREATE LOGIN [$domain_netbios_name\$domain_admin] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
EXEC master..sp_addsrvrolemember @loginame = '$domain_netbios_name\$domain_admin', @rolename = 'sysadmin'

CREATE LOGIN [$domain_netbios_name\sqlinstall] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
EXEC master..sp_addsrvrolemember @loginame = '$domain_netbios_name\sqlinstall', @rolename = 'sysadmin'

CREATE LOGIN [$domain_netbios_name\mando] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
EXEC master..sp_addsrvrolemember @loginame = '$domain_netbios_name\mando', @rolename = 'sysadmin'

CREATE LOGIN [$domain_netbios_name\luke] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
EXEC master..sp_addsrvrolemember @loginame = '$domain_netbios_name\luke', @rolename = 'sysadmin'

CREATE LOGIN [$domain_netbios_name\han] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
EXEC master..sp_addsrvrolemember @loginame = '$domain_netbios_name\han', @rolename = 'sysadmin'
"@

# Save the SQL script to a file
$sqlAdmin | Set-Content -Path 'C:\BUILD\sqladmin.sql'

# Execute the SQL script using the provided SQL sysadmin credentials on the local instance
Invoke-Sqlcmd -Username "$sql_sysadmin_user" -Password "$sql_sysadmin_pswd" ` -ServerInstance 'localhost' -Database 'master' -InputFile 'C:\BUILD\sqladmin.sql'

# Stop the transcript
Stop-Transcript
