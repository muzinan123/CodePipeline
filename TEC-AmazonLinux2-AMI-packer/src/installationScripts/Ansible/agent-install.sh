#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Installing Python3
echo -e "Installing Python3"
sudo yum install python3 -y

# Install Python3-pip
echo "Installing Python3-pip"
sudo yum install python3-pip -y

# Create a user for Ansible
echo "Creating Ansible user"
sudo useradd -m -d /opt/ansible ansible
echo ""

# Current disabled due to security. Below should be executed on instance to add the user 'ansible' to sudoers file for sudo access
# sudo echo "ansible        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
# echo ""

# Install ansible
echo "Installing Ansible"
sudo su -c "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py" -l ansible
sudo su -c "python3 get-pip.py --user" -l ansible
sudo su -c "python3 -m pip install ansible --user" -l ansible
echo ""

echo "Ansible Installation Completed"
echo ""
