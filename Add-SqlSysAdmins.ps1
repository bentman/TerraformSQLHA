[CmdletBinding()]
param ( 
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_netbios_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_admin,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_sysadmin_user,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sql_sysadmin_pswd
)
# Check if the directory 'C:\BUILD\Logs\' exists, and create it if it does not
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\' -ItemType Directory -Force }
# Start a transcript to log all activities to the specified path
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlSysAdmins.log'
# Test the network connection to the local computer on port 1433 (default SQL Server port)
Test-NetConnection -Computername $env:COMPUTERNAME -Port 1433
# Define a SQL script to create a new SQL login and add it to the sysadmin server role
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
# Execute the SQL script using the specified SQL admin credentials and the local SQL Server instance
Invoke-Sqlcmd -Username "$sql_sysadmin_user" -Password "$sql_sysadmin_pswd" -ServerInstance 'localhost' -Database 'master' -InputFile 'C:\BUILD\sqladmin.sql'
# Stop the transcript
Stop-Transcript
