#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Download the packages
echo "Downloading the ScaLeft repository & packages..."
sudo curl -C - https://pkg.scaleft.com/scaleft_yum.repo | sudo tee /etc/yum.repos.d/scaleft.repo
echo ""

# Trust the repository signing key:
echo "Importing the repository signing key..."
sudo rpm --import https://dist.scaleft.com/pki/scaleft_rpm_key.asc
echo ""

# By default, the scaleft-server-tools packages on Red Hat- and Debian-derived distributions will automatically start sftd after installation. 
# In most circumstances, this causes the agent to automatically enroll in Advanced Server Access and 
# create local users, and remove the enrollment token from disk.
# If a disable-autostart file exists at the time of installation, the packages will not automatically start the agent. 
# This can be useful when building OS images using a tool like Packer. 
# Under these circumstances, it is typically preferable to remove the disable-autostart file once the package has been installed.
# An empty file /etc/sftd/disable-autostart needs to be added. 
# When the AMI needs to be enrolled, remove this file and restart the sftd service.
# Source: https://support.okta.com/help/s/article/Okta-ASA-Server-trying-to-enroll-even-when-AutoEnroll-is-false?language=en_US

echo "Adding empty file, /etc/sftd/disable-autostart, to disable autostart of sftd..."
sudo mkdir -p /etc/sftd
sudo touch /etc/sftd/disable-autostart
echo ""

# Install the agent
echo "Install ScaLeft server tools..."
sudo yum install scaleft-server-tools -y
echo ""

# Cleanup any Okta device token
echo "Stopping ScaLeft service..."
sudo systemctl stop sftd
echo ""

echo "Removing enrollment token and residual artifacts..."
sudo rm -rf /var/lib/sftd/*
echo ""

# Enable the STFD service so it starts on boot
echo "Enabling the SFTD service..."
sudo systemctl enable sftd
echo ""

# Post-Installation Steps
#  Create the dependency between the Okta service file and hostname update
echo "Updating the service file for ScaLeft..."
sudo sed -i '2a After=update-hostname.service' /etc/systemd/system/sftd.service
echo "" 

# Remove the empty file, /etc/sftd/disable-autostart
echo "Removing /etc/sftd/disable-autostart..." 
sudo rm -rf /etc/sftd/disable-autostart
echo "Upon boot, the sftd service will start and register with Okta..."
echo ""

# Update the service file
echo "Moving service file to /etc/systemd/system..."
sudo mv /tmp/sftd.service /etc/systemd/system/sftd.service
echo ""
