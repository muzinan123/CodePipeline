#!/bin/bash

InstanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
if [ "$InstanceId" == "" ]
then
    echo "Error: Could not fetch instance Id of the current instance for hostname updation. Please check Instance's Security Groups for accessing 169.254.169.254 on default http port. "
    exit 1
fi
echo "Instance ID: $InstanceId"

InstanceName=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$InstanceId" --output=text | grep 'Name' | cut -f5)
if [ "$InstanceName" == "" ]
then
    echo "Error: Could not fetch Name (tag) of the current instance for hostname updation. Please check if instance's Name tag has been set and Instance profile role allows aws ec2 describe-tags operations."
    exit 1
fi
echo "Instance Name: $InstanceName"

Hostname=${InstanceName,,}
echo "Hostname: $Hostname"

AWSHostname=$(cat /etc/hostname | cut -d '.' -f 1)
if [ "$AWSHostname" == "" ]
then
    echo "Warning: No hostname has been pre-assigned to the instance. "
    sed -i -e s/^/$Hostname/g /etc/hostname
else
    echo "AWS Provided Hostname: $AWSHostname"
    sed -i -e s/$AWSHostname/$Hostname/g /etc/hostname
fi

NewHostname=$(cat /etc/hostname)

if [ $HOSTNAME == $NewHostname ]
then
    echo 'The hostname has already been updated'
    systemctl restart SplunkForwarder.service
else
    hostnamectl set-hostname $NewHostname
    hostname $NewHostname
    echo "Hostname set to $NewHostname"
    #reboot
fi