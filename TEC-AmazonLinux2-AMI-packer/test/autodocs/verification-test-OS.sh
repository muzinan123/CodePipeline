#!/bin/bash

#Contains OS Verification steps - Linux ver.
#(includes agent status + versions)
#does not include volume encryption checks - future enhancement?

##SecuredShellDaemon
##HardeningScriptRunCheck
##IPv6DisableCheck
##ExplicitCongestionNotificationDisableCheck
##HostnameValidity
##SudoerConfigCheck
##NetworkTimeChronyDaemon
##NetworkTimeConfigStatus
##TimeZoneValidity
##NetworkTimeClockSynch
##MessageOfTheDay

# Variables used throughout script
echo "Configuring environment..."
echo "  Setting varibles..."
serviceStatusFile="serviceStatus-OS.txt"
serviceVersionFile="serviceVersion-OS.txt"
serviceConfigFile="serviceConfig-OS.txt"
NTPServer="169.254.169.123"
echo ""


# Check for existing test results
if [ -e "$serviceStatusFile" ]; then
  echo "  Removing old test results"
  sudo rm $serviceStatusFile -f
else
  echo "  No old test results to remove"
fi
touch $serviceStatusFile

echo ""

if [ -e "$serviceVersionFile" ]; then
  echo "  Removing old version results"
  sudo rm $serviceVersionFile -f
else
  echo "  No old version results to remove"
fi
touch $serviceVersionFile

echo ""


if [ -e "$serviceConfigFile" ]; then
  echo "  Removing old config results"
  sudo rm $serviceConfigFile -f
else
  echo "  No old config results to remove"
fi
touch $serviceConfigFile

echo ""


#--------------- Metadata & Derived Variables -------------------------#

echo "  Getting instance metadata..."

echo "    Fetching instance ID..."
InstanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)

echo "    Fetching region..."
Region=$(curl http://169.254.169.254/latest/meta-data/placement/region)

echo "    Fetching EC2 tag - Name..."
InstanceName=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$InstanceId" --output=text | grep 'Name' | cut -f5)

Hostname=${InstanceName,,}

CurrentHostname=$(hostname)

echo "    Fetching attached EBS volumes..."
EbsVolumeList=$(/usr/local/bin/aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$InstanceId" --query "Volumes[*].{ID:VolumeId}" --output=text)

echo ""

#--------------- Update Hostname Test -------------------------#
# Check to see if hostname was updated
echo "Hostname Validation"
echo ""

echo "  Instance ID: $InstanceId"
echo "  Instance Name: $InstanceName"
echo "  Expected Hostname: $Hostname"

# Local hostname
echo "  System Hostname: $CurrentHostname"
echo ""

# Check Hostname
if [[ "$CurrentHostname" == *"$Hostname"* ]]; then
  echo "  Hostname is correct"
  echo "HostnameValidity: PASS" >> $serviceStatusFile
else
  echo "  Hostname was not updated"
  echo "HostnameValidity: FAIL" >> $serviceStatusFile
fi

echo ""

#--------------- Hardening agent -------------------------#
echo "OS Hardening Validation"
echo "  Checking OS Hardening status..."

if systemctl list-units --full -all | grep -Fq "hardening.service" ; then
  echo "HardeningScriptRunCheck: PASS" >> $serviceStatusFile
else
  echo "HardeningScriptRunCheck: FAIL" >> $serviceStatusFile
fi

echo ""

#--------------- OS Configurations -------------------------#
echo "OS Configuration Validation"

# Message of the Day
echo "  MOTD Validation"
echo "    Checking message of the day..."
motdStatus=$(cat /etc/motd | grep "This system is for the use of Takeda authorized users only")

if [[ "$motdStatus" ]]; then
  echo "      Message of the Day configured"
  echo "MessageOfTheDay: PASS" >> $serviceStatusFile
else
  echo "      Message of the Day not configured"
  echo "        cat /etc/motd | grep 'This system is for the use of Takeda authorized users only'"
  echo "        $motdStatus"
  echo "MessageOfTheDay: FAIL" >> $serviceStatusFile
fi

echo ""


# SecuredShellDaemon
echo "  SSHD Validation"
echo "    Checking SSHD status..."
sshdStatus=$(systemctl is-active sshd)
sshdListen=$(sudo ss -tulwn | grep LISTEN | grep 22)

if [[ "$sshdStatus" == "active" ]]; then
  echo "      SSHD is enabled"
  echo "SecuredShellDaemon: PASS" >> $serviceStatusFile
else
  echo "      SSHD is disabled"
  echo "        systemctl is-active sshd"
  echo "        $sshdStatus"
  echo "SecuredShellDaemon: FAIL" >> $serviceStatusFile
fi

echo ""

# NetworkTimeChronyDaemon
echo "  NTP Validation"
echo "    Checking Chrony status..."
cStatus=$(systemctl is-active chronyd)

if [[ "$cStatus" == "active" ]]; then
  echo "      Chrony is enabled"
  echo "NetworkTimeChronyDaemon: PASS" >> $serviceStatusFile
else
  echo "      Chrony is disabled"
  echo "        systemctl is-active chronyd:"
  echo "        $cStatus"
  echo "NetworkTimeChronyDaemon: FAIL" >> $serviceStatusFile
fi

echo ""


# NetworkTimeConfigStatus
echo "    Checking NTP..."
NTPStatus=$(timedatectl | grep "NTP enabled: yes")
NTPConfig=$(cat /etc/chrony.conf | grep server | grep -v '#server' | grep -v 'servers' | cut -f 2 -d ' ')

if [[ "$NTPStatus" == *"yes"* ]]; then
  echo "      NTP enabled"
  echo "      Checking NTP server config..."

  if [[ "$NTPConfig" == "$NTPServer" ]]; then
    echo "    NTP server config valid"
    echo "NTPServer: $NTPConfig" >> $serviceConfigFile
    echo "NetworkTimeConfigStatus: PASS" >> $serviceStatusFile
  else
    echo "    NTP server config not valid"
    echo "NetworkTimeConfigStatus: FAIL" >> $serviceStatusFile
  fi

else
  echo "      NTP disabled"
  echo "        timedatectl | grep 'NTP service:'"
  echo "        $NTPStatus"
  echo "NetworkTimeConfigStatus: FAIL" >> $serviceStatusFile
fi

echo ""

# TimeZoneValidity
# Time zone check to see if correct
echo "    Checking timezone..."
TZStatus=$(timedatectl | grep "Time zone: UTC")

if [[ "$TZStatus" == *"$TZ"* ]]; then
  echo "      Timezone set to UTC"
  echo "TimeZoneValidity: PASS" >> $serviceStatusFile
else
  echo "      Timezone incorrectly set"
  echo "        timedatectl | grep 'Time zone: UTC': "
  echo "        $TZStatus"
  echo "TimeZoneValidity: FAIL" >> $serviceStatusFile
fi

echo ""

# NetworkTimeClockSynch

echo "    Checking time synchronization..."
SyncStatus=$(timedatectl | grep "NTP synchronized: yes")
if [[ "$SyncStatus" == *"yes"* ]]; then
  echo "      System clock is synchronized"
  echo "NetworkTimeClockSynch: PASS" >> $serviceStatusFile
else
  echo "      System clock not sychronized"
  echo "        timedatectl | grep 'Time zone: UTC': "
  echo "        $SyncStatus"
  echo "NetworkTimeClockSynch: FAIL" >> $serviceStatusFile
fi

echo ""


# SudoerConfigCheck
echo "  sudoers Validation"
sudoersStatus=$(sudo visudo -c | grep 'error')

echo "    Validating /etc/sudoers..."
if [[ "$sudoersStatus" ]]; then
  echo "      Sudoers file is corrupted"
  echo "        sudo visudo -c | grep 'error'"
  echo "        $sudoersStatus"
  echo "SudoerConfigCheck: FAIL" >> $serviceStatusFile
else
  echo "      Sudoers file is valid"
  echo "SudoerConfigCheck: PASS" >> $serviceStatusFile
fi

echo ""


# IPv6DisableCheck Validation
echo "  IPv6 Validation"
ipv6Status=$(sudo cat /proc/sys/net/ipv6/conf/all/disable_ipv6)

echo "    Getting IPv6 status..."
if [[ "$ipv6Status" != 1 ]]; then
  echo "      IPv6 is not disabled"
  echo "        /proc/sys/net/ipv6/conf/all/disable_ipv6 is $ipv6Status"
  echo "IPv6DisableCheck: FAIL" >> $serviceStatusFile
else
  echo "      IPv6 is disabled"
  echo "IPv6DisableCheck: PASS" >> $serviceStatusFile
fi

echo ""


# ExplicitCongestionNotificationDisableCheck Validation
echo "  ECN Validation"
ecnStatus=$(sudo cat /proc/sys/net/ipv4/tcp_ecn)

echo "    Getting ECN status..."
if [[ "$ecnStatus" != 0 ]]; then
  echo "      ECN is not disabled"
  echo "        /proc/sys/net/ipv4/tcp_ecn is $ecnStatus"
  echo "ExplicitCongestionNotificationDisableCheck: FAIL" >> $serviceStatusFile
else
  echo "      ECN is disabled"
  echo "ExplicitCongestionNotificationDisableCheck: PASS" >> $serviceStatusFile
fi

echo ""


echo "Test results"
cat $serviceStatusFile
echo ""
echo "Versions"
cat $serviceVersionFile
echo ""
echo "Configurations"
cat $serviceConfigFile