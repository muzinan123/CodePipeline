#!/bin/bash

# # Exit the immediately upon a non-zero exit code
# set -e
# Every command is printed as it is executed
set -x

# Install AWS Systems Manager Agent
echo "Downloading the AWS Systems Manager Agent..."
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
echo "" 

# Enable Systems Manager Agent
echo "Enabling Systems Manager Agent service..."
sudo systemctl enable amazon-ssm-agent
echo ""

# Restart Systems Manager Agent
echo "Restarting Systems Manager Agentservice..."
sudo systemctl restart amazon-ssm-agent
echo ""

# Validate installation
echo "Systems Manager Agent status:"
sudo systemctl status amazon-ssm-agent
echo ""
