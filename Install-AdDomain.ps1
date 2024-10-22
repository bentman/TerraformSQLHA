<#
.SYNOPSIS
    This script automates the setup and configuration of an Active Directory Domain Services (AD DS) environment on a Windows server.
.DESCRIPTION
    The script installs and configures AD DS, DNS, and related features, sets up a new AD forest, adjusts firewall settings, and performs other necessary configurations.
.PARAMETER domain_name
    (Mandatory) The fully qualified domain name (FQDN) for the new AD forest.
.PARAMETER domain_netbios_name
    (Mandatory) The NetBIOS name for the new AD forest.
.PARAMETER safemode_admin_pswd
    (Mandatory) The password for the Directory Services Restore Mode (DSRM) administrator.
.EXAMPLE
    .\YourScriptName.ps1 -domain_name "example.com" -domain_netbios_name "EXAMPLE" -safemode_admin_pswd "P@ssw0rd"
.NOTES
    Ensure that the script is run with administrative privileges.
#>

[CmdletBinding()]
param ( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$domain_name,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$domain_netbios_name,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$safemode_admin_pswd
)

# Convert the safe mode administrator password to a secure string
$safe_admin_pswd = ConvertTo-SecureString $safemode_admin_pswd -AsPlainText -Force

# Create directories for setup if they do not exist
foreach ($path in @("$env:SystemDrive\BUILD\Content", "$env:SystemDrive\BUILD\Logs", "$env:SystemDrive\BUILD\Scripts")) {
    if (-not (Test-Path -Path $path)) { New-Item -Path $path -ItemType Directory -Force }
}

# Start transcript logging
Start-Transcript -Path 'c:\BUILD\Logs\Install-AdDomain.log'

# Set the security protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install the NuGet package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Set PowerShell Gallery as a trusted repository
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Install necessary Windows features
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -Verbose
Install-WindowsFeature -Name RSAT-AD-Tools -Verbose

# Import the AD DS Deployment module
Import-Module -Name ADDSDeployment -Verbose

# Install DNS server features
Install-WindowsFeature -Name DNS -IncludeAllSubFeature -Verbose
Install-WindowsFeature -Name RSAT-DNS-Server -Verbose

# Import the DNS Server module
Import-Module -Name DnsServer -Verbose

# Install a new AD DS forest
Install-ADDSForest `
    -DomainName $domain_name `
    -DomainNetBiosName $domain_netbios_name `
    -SafeModeAdministratorPassword $safe_admin_pswd `
    -InstallDns `
    -NoRebootOnCompletion:$true `
    -LogPath 'C:\BUILD\01-DCPromo.log' `
    -Confirm:$false -Force -Verbose

# Disable the firewall for the Domain profile
Set-NetFirewallProfile -Profile Domain -Enabled:false

# Allow SSH through firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any

# Disable NLA for Terminal Server (RDP) user authentication setting
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 0

# Disable the Azure Arc Setup feature
Disable-WindowsOptionalFeature -Online -FeatureName AzureArcSetup -NoRestart -LogPath 'c:\BUILD\disableAzureArcSetup.log' -Verbose

# Stop transcript logging
Stop-Transcript

# Exit the script (escaping possible errors for automation)
exit 0