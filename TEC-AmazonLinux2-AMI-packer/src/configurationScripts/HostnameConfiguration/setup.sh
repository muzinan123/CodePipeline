#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Move service files to systemd/system
echo "Moving service files to /etc/systemd/system..."
sudo mv /tmp/update-hostname.service /etc/systemd/system/
echo ""

# Configure/Prepare update-hostname script
echo "Moving update-hostname script..."
sudo mkdir /opt/utilities
sudo mv /tmp/update-hostname.sh /opt/utilities
echo ""


echo "Ensure update-hostname script is executable..."
sudo chmod +x /opt/utilities/update-hostname.sh
sudo chown root:root /opt/utilities/update-hostname.sh
echo ""


# Reload configurations
echo "Executing dameon-reload..."
sudo systemctl daemon-reload
echo ""

echo "Enabling services..."
sudo systemctl enable update-hostname.service
