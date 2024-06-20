#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

echo "Confirming prerequisite package, unzip, is installed..."
if sudo yum list installed | grep unzip; then
  echo "unzip is installed"
else
  echo "Installing prerequisite packages"
  sudo yum install unzip -y
fi
echo ""

echo "Confirming prerequisite package, curl, is installed..."
if sudo yum list installed | grep curl; then
  echo "curl is installed"
else
  echo "Installing prerequisite packages"
  sudo yum install curl -y
fi
echo ""

echo "Downloading AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
echo ""

echo "Installing AWS CLI"
sudo ./aws/install
echo ""
