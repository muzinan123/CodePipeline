#/bin/sh

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Update all packages except for kernel
# kernel is excluded to ensure the instance remains at the OS version provided in the Packer configuration
echo "Updating yum repos..."
echo "Excluding kernel*..."
sudo yum update --exclude=kernel* -y

# Installing Python3 if not already present
echo "Confirming Python3 is installed..."
if which python3; then
  echo "Python is installed"
else
  sudo yum install python3 -y
fi

# bind-utils enables the instance to ....
sudo yum install bind-utils -y

# wget enables the instance to download necessary packages and artifacts
echo "Installing wget package..."
sudo yum install wget -y
# perl packages enable the instance to ... 
echo "Installing perl packages..."
sudo yum install  -y perl perl-Sys-Syslog perl-DateTime perl-LWP-Protocol-https perl-Digest-SHA perl-Switch
