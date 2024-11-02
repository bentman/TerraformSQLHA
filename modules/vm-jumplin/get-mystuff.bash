#############################################################

newUsr='bentman'
# add local user (will prompt for password)
sudo adduser $newUsr
# add local user to sudo
sudo usermod -aG sudo $newUsr
# add local user to sudo
su $newUsr
# set timezone
sudo timedatectl set-timezone America/Chicago

#############################################################

# Update Ubuntu
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt -y update

#############################################################

# Enforce SSH
sudo apt install -y ssh
sudo systemctl start ssh
sudo ufw allow ssh
systemctl status ssh
# Lan IP Address (Primary NIC)
sudo apt install net-tools
ifconfig
# Disable Suspend and Hibernation
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates 
sudo apt install -y gdebi alien software-properties-common
sudo apt install -y net-tools wget curl gnupg gnupg-agent
sudo apt install -y openvpn dialog python3-pip python3-setuptools
sudo apt install -y conky conky-all
# Install restricted extras
sudo apt install -y ubuntu-restricted-extras
# Re-Enforce MSFT Fonts
sudo apt install -y --reinstall ttf-mscorefonts-installer
# Install preferred DE
sudo apt -y install cinnamon-desktop-environment
cinnamon --version

#############################################################

# Remove Games & Open Office
sudo apt remove -y --purge xscreensaver gnome-screensaver gnome-games
sudo apt remove -y --purge libreoffice-math libreoffice-writer libreoffice-impress libreoffice-draw libreoffice-calc
sudo apt remove -y --purge libreoffice*
sudo apt autoremove -y

#############################################################

# Use script to install xrdp 
# Check for new versions! https://c-nergy.be/blog/?p=19814
pushd ~
mkdir ~/Downloads
pushd ~/Downloads
wget https://www.c-nergy.be/downloads/xRDP/xrdp-installer-1.5.1.zip
unzip xrdp-installer-1.5.1.zip
chmod +x  ~/Downloads/xrdp-installer-1.5.1.sh
./xrdp-installer-1.5.1.sh -s
popd
# Allow RDP 3389 in firewall
sudo ufw allow 3389
sudo systemctl restart ufw
# now you can use rdp to connect to your linux desktop
sudo reboot

#############################################################

# Refresh Snap library
sudo snap refresh

# Install Snaps
sudo snap install chromium --classic
sudo snap install powershell --classic
sudo snap install code --classic
sudo snap install git-ubuntu --classic
sudo snap install remmina

# Install Azure-CLI (One-Liner)
pushd ~/Downloads
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
popd

#############################################################

# Edge Browser (Stable)
firefox https://www.microsoft.com/en-us/edge
pushd ~/Downloads/
sudo chown 777 microsoft-edge-stable*
sudo apt install -y ./microsoft-edge-stable*.deb
rm ./microsoft-edge-stable*.deb
sudo apt-get update

#############################################################

# Update Ubuntu, again
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt -y update

#############################################################

# Check History and Export
echo $HISTFILE
history | cut -c 8- > ~/bash_history.txt 
