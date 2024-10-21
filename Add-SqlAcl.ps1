<#
.SYNOPSIS
    Adds SQL clusters to the Active Directory access control list (ACL).
.DESCRIPTION
    This script grants the necessary permissions for SQL clusters in two regions
    by adding their computer accounts to the Servers OU in Active Directory.
.PARAMETER domain_name
    The domain name (FQDN) to which the clusters belong.
.PARAMETER sqlcluster_region1
    The SQL cluster name for the first region.
.PARAMETER sqlcluster_region2
    The SQL cluster name for the second region.
.NOTES
    This script is intended for use in a lab or testing environment.
#>

[CmdletBinding()]
param ( 
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sqlcluster_region1,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$sqlcluster_region2
)

# Prepare the Servers OU path
$split_domain = $domain_name.Split(".")
$dn_path = ($split_domain | ForEach-Object { "DC=$_" }) -join ","
$servers_ou_path = "OU=Servers,$dn_path"

# Ensure the log directory exists
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force }

# Start logging the process
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlAcl.log'

# Helper function to apply ACL for a given cluster
function Add-ClusterAcl($cluster_name) {
    Test-NetConnection -ComputerName $domain_name -Port 9389
    $Computer = Get-ADComputer $cluster_name
    $ComputerSID = [System.Security.Principal.SecurityIdentifier] $Computer.SID
    $ACL = Get-Acl -Path "AD:$servers_ou_path"
    $Identity = [System.Security.Principal.IdentityReference] $ComputerSID
    $ADRight = [System.DirectoryServices.ActiveDirectoryRights] 'GenericAll'
    $Type = [System.Security.AccessControl.AccessControlType] 'Allow'
    $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] 'All'
    $Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type, $InheritanceType)
    $ACL.AddAccessRule($Rule)
    Set-Acl -Path "AD:$servers_ou_path" -AclObject $ACL -Verbose
}

# Apply ACLs for both regions
Add-ClusterAcl -cluster_name $sqlcluster_region1
Add-ClusterAcl -cluster_name $sqlcluster_region2

Stop-Transcript
