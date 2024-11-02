
# Set variables
$new_user = ''
$new_pswd = ''
$new_tz = 'Central Standard Time'

# Reinforce bypass execution policy
Set-ExecutionPolicy -Scope Process Unrestricted -Force

### Create directory for setup if it not exist
New-Item -Path "$env:SystemDrive\BUILD\Content\" -ItemType Directory -Force -ea 0
New-Item -Path "$env:SystemDrive\BUILD\Logs\" -ItemType Directory -Force -ea 0
New-Item -Path "$env:SystemDrive\BUILD\Scripts\" -ItemType Directory -Force -ea 0

# Start transcript logging
Start-transcript -Path 'c:\BUILD\LOGS\00_get_mystuff.log'

# Set Time Zone
Set-TimeZone -Name $new_tz -Confirm:$false

# Allow ICMP ping reply in firewall
Set-NetFirewallRule `
  -ErrorAction SilentlyContinue `
  -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" `
  -Enabled True `
  -Confirm:$false

# Create $new_user
New-LocalUser -Name $new_user -Password (ConvertTo-SecureString $new_pswd -AsPlainText -Force) -PasswordNeverExpires -Verbose
# add local user to administrators group
Add-LocalGroupMember -Group Administrators -Member $new_user -Verbose

# Setup NuGet (no prompt) & trust PowerShellGallery
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Setup Windows Subsystem for Linux (WSL2)
wsl --install

# Install pwsh.exe from winget
winget install --id Microsoft.Powershell --source winget

# WinGet look for VS Code versions (it may prompt to accept terms)
winget search Microsoft.VisualStudioCode

# Install VS Code from winget
winget install --id Microsoft.VisualStudioCode --source winget

# WinGet look for AzureCLI (it may prompt to accept terms)
winget search Microsoft.AzureCLI

# Install AzureCLI from winget
winget install --id Microsoft.AzureCLI --source winget

Stop-Transcript
