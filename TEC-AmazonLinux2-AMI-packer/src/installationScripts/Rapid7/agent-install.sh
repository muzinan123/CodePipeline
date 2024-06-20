#/bin/sh

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x


# Download the packages from Artifactory (Jfrog)
echo "Downloading Rapid7 files..."
sudo curl -v -L -u "$user:$password" https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Rapid7/Linux/agent_installer.sh -o agent_installer.sh
echo "" 

# Modify permissions to enable Rapid7
echo "Modifying permissions of downloaded files..."
sudo chmod u+x agent_installer.sh
echo ""

# Install Rapid 7, using tokens 
echo "Install Rapid7..."
sudo ./agent_installer.sh install_start --token $token
echo ""
