#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Move service files to systemd/system
echo "Moving service files to /etc/systemd/system..."
sudo mv /tmp/hardening.service /etc/systemd/system/
echo ""

# Update Message of the Day
echo "Updating /etc/motd..."
sudo update-motd --disable
sudo cp -f /tmp/motd  /etc/motd
echo ""

# Configure/Prepare hardening script
echo "Copying hardening scripts..."
sudo cp /tmp/tec-security-ami-amzn2-hardening.sh /home/ec2-user
echo ""

echo "Ensure hardening scripts are executable..."
sudo chmod +x /tmp/tec-security-ami-amzn2-hardening.sh
sudo chmod +x /home/ec2-user/tec-security-ami-amzn2-hardening.sh
echo ""

# Reload configurations
echo "Executing dameon-reload..."
sudo systemctl daemon-reload
echo ""

echo "Enabling services..."
sudo systemctl enable hardening.service
sudo systemctl start hardening.service

# # Configure Cron jobs .
# echo "Configuring cron job to execute hardening script upon boot"
# crontab -l > hardening
# echo "@reboot /home/ec2-user/tec-security-ami-amzn2-hardening.sh" >> hardening
# crontab hardening
# crontab -l
# echo ""
