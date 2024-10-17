[CmdletBinding()]
param ( 
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string]$domain_name,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] [string[]]$sqlcluster_names
)

# Split the domain name into its components
$split_domain = $domain_name.Split(".")
# Construct the DN path
$dn_path = ($split_domain | ForEach-Object { "DC=$_" }) -join ","
# Construct the servers OU path
$servers_ou_path = "OU=Servers,$dn_path"

# Check if the directory 'C:\BUILD\Logs\' exists, and create it if it does not
if (!(Test-Path -Path 'C:\BUILD\Logs\')) { New-Item -Path 'C:\BUILD\Logs\' -ItemType Directory -Force }
# Start a transcript to log all activities to the specified path
Start-Transcript -Path 'C:\BUILD\Logs\transcript_Add-SqlAcl.log'

foreach ($sqlcluster_name in $sqlcluster_names) {
    # Test the network connection to the specified domain name and port
    Test-NetConnection -ComputerName $domain_name -Port 9389
    # Retrieve the Active Directory computer object for the specified SQL cluster name
    $Computer = Get-ADComputer $sqlcluster_name
    # Convert the computer's SID to a SecurityIdentifier object
    $ComputerSID = [System.Security.Principal.SecurityIdentifier] $Computer.SID
    # Get the Access Control List (ACL) for the specified AD path
    $ACL = Get-Acl -Path "AD:$servers_ou_path"
    # Create an IdentityReference object from the computer's SID
    $Identity = [System.Security.Principal.IdentityReference] $ComputerSID
    # Define the Active Directory rights to be granted (GenericAll allows all permissions)
    $ADRight = [System.DirectoryServices.ActiveDirectoryRights] 'GenericAll'
    # Set the access control type to 'Allow'
    $Type = [System.Security.AccessControl.AccessControlType] 'Allow'
    # Specify that the inheritance type is 'All'
    $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] 'All'
    # Create a new access rule with the specified parameters
    $Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type, $InheritanceType)
    # Add the new access rule to the ACL
    $ACL.AddAccessRule($Rule)
    # Apply the updated ACL to the specified AD path
    Set-Acl -Path "AD:$servers_ou_path" -AclObject $ACL -Verbose
}

# Stop the transcript
Stop-Transcript
