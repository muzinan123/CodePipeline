#!/bin/bash

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x

# Generate random password
echo "Generating random password..."
randompasswd=$(openssl rand -base64 16)
echo ""

#hashed seed cred
echo "Creating hashed seed credentials"
hashedcred='$6$HM9WOSemlebTlNrw$hxz.gGM6xx85SjCwTR25WbFZ5T.mAaZVsPbegCGUikxfxGaZNwmv4BiiZl2refH8oHty5Z0JcAJpkReOWOY1p1'
echo ""

# Create a user for Splunk
echo "Creating user for splunk..."
sudo useradd -m -d /opt/splunkforwarder splunk
echo ""

## Download Splunk from JFrog Artifactory
echo "Downloading Splunk..."
curl -L  -u "$user:$password" https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Splunkforwarder/linux/splunkforwarder-Linux-x86_64.tgz -o splunkforwarder-Linux-x86_64.tgz
echo ""

echo "Decompressing download..."
sudo tar xzf splunkforwarder-Linux-x86_64.tgz -C /opt
echo ""

# Modify permissions to enable Splunk
echo "Modifying permissions of downloaded files..."
sudo chown -R splunk /opt/splunkforwarder
echo ""

# Start first time run
sudo -H -u splunk /opt/splunkforwarder/bin/splunk start --accept-license --no-prompt --auto-ports  --seed-passwd $hashedcred

sudo /opt/splunkforwarder/bin/splunk stop

# enable forwarder to start at boot up
sudo /opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 1

# Switch user and set splunk deployment server
sudo -H -u splunk /opt/splunkforwarder/bin/splunk set deploy-poll splunk-ds.onetakeda.com:8089 -auth admin:$hashedcred

#sudo echo -e '[target-broker:deploymentServer]\ntargetUri = splunk-ds.onetakeda.com:8089' > sudo  /opt/splunkforwarder/etc/system/local/deploymentclient.conf
sudo chmod 600 /opt/splunkforwarder/etc/system/local/deploymentclient.conf
sudo chown splunk /opt/splunkforwarder/etc/system/local/deploymentclient.conf

# Ensure the file handling limits are properly set
cat /etc/security/limits.conf

# update audit log_group
sudo sed -i 's/log_group = root/log_group = splunk/' /etc/audit/auditd.conf

# Add Splunk_ACLs file
sudo setfacl -R -m u:splunk:rX /var/log
sudo setfacl -R -d -m u:splunk:rX /var/log

# replace "create" in /etc/logrotate.conf with copytruncate
sudo sed -i 's/create/copytruncate/g' /etc/logrotate.conf
# check that changes was made succesfully
sudo cat /etc/logrotate.conf | grep copytruncate

# update deployment server 
#sudo sed -i "s/usqasspdp002.onetakeda.com/splunk-ds.onetakeda.com/i" /opt/splunkforwarder/etc/system/local/deploymentclient.conf

# restart splunk agent
# sudo /opt/splunkforwarder/bin/splunk stop
#sudo systemctl stop SplunkForwarder

# clear prep-config
sudo /opt/splunkforwarder/bin/splunk clone-prep-clear-config

# fixed splunk permission issue
sudo sed -i -e 's#init.scope/##g' /etc/systemd/system/SplunkForwarder.service

# Reload Splunk to get the latest configuration
echo "Reloading Splunk with the latest configurations..."
sudo systemctl daemon-reload
echo "" 

# Status
echo "Upon boot, the SplunkForwarder service will start..."