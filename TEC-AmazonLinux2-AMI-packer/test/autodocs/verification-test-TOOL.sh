#!/bin/bash

#Contains Tool Verification steps 
#(includes agent status + versions)

##amazon-ssm-agent
##amazon-cloudwatch-agent
##CrowdStrike-Falcon-Sensor
##Rapid7-Insight-Agent
##Splunk-Universal-Forwarder
##ScaleFT-Daemon

# Variables used throughout script
echo "Configuring environment..."
echo "  Setting varibles..."
serviceStatusFile="serviceStatus-TOOL.txt"
serviceVersionFile="serviceVersion-TOOL.txt"
serviceConfigFile="serviceConfig-TOOL.txt"
verifiedSplunkURI="splunk-ds.onetakeda.com:8089"
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

#--------------- Amazon Systems Manager Agent -------------------------#
# Get Status
echo "Amazon Systems Manager Agent Validation"
echo "  Checking amazon-ssm-agent status..."

# Validate Status
ssmStatus=$(systemctl is-active amazon-ssm-agent)

if [[ "$ssmStatus" == "active" ]]; then
  echo "    Systems Manager agent active"
  echo "amazon-ssm-agent: PASS" >> $serviceStatusFile

  echo "  Getting version..."
  ssmVersion=$(rpm -qa | grep amazon-ssm-agent | cut -f 4-5 -d '-')

  echo "amazon-ssm-agent: $ssmVersion" >> $serviceVersionFile
else
  echo "    Systems Manager agent not configured"
  echo "      systemctl is-active amazon-ssm-agent"
  echo "      $ssmStatus"
  echo "amazon-ssm-agent: FAIL" >> $serviceStatusFile

  echo "amazon-ssm-agent: Unknown" >> $serviceVersionFile
fi

echo ""


#--------------- Okta ASA -------------------------#
# Get Status
echo "Okta ASA Validation"
echo "  Checking Okta ASA status..."

# Check Status
oktaStatus=$(systemctl is-active sftd)

if [[ "$oktaStatus" == "active" ]]; then
  echo "    Okta ASA active"
  echo "ScaleFT-Daemon: PASS" >> $serviceStatusFile

  echo "  Checking auto-enrollment setting..."
  oktaEnrollment=$(sudo stat /etc/sftd/disable-autostart 2> /dev/null)

  if [[ "$oktaEnrollment" ]]; then
    echo "    Okta ASA is not properly configured"
    echo "ScaleFT-Daemon: FAIL" >> $serviceStatusFile
  else
    echo "    Okta ASA is properly configured"
  fi

  echo "  Getting version..."
  oktaVersion=$(rpm -qa | grep scaleft-server-tools | cut -f 4-5 -d '-')

  echo "ScaleFT-Daemon: $oktaVersion" >> $serviceVersionFile
else
  echo "    Okta ASA not configured"
  echo "      systemctl is-active sftd"
  echo "      $oktaStatus"
  echo "ScaleFT-Daemon: FAIL" >> $serviceStatusFile
  echo "ScaleFT-Daemon: Unknown" >> $serviceVersionFile
fi

echo ""


#--------------- Rapid7-Insight-Agent -------------------------#
# Get status
echo "Rapid7 Validation"
echo "  Checking Rapid7 status..."
rapid7Status=$(systemctl is-active ir_agent)

if [[ "$rapid7Status" == "active" ]]; then
  echo "    Rapid7 is active"
  echo "Rapid7-Insight-Agent: PASS" >> $serviceStatusFile

  echo "  Gettting version..."
  rapid7Agent=$(sudo cat /etc/systemd/system/ir_agent.service | grep ExecStart | cut -f2 -d'=')
  rapid7Version=$(sudo $rapid7Agent --version | grep SemanticVersion | cut -d':' -f2 | cut -d '"' -f2)

  echo "Rapid7-Insight-Agent: $rapid7Version" >> $serviceVersionFile
else
  echo "    Rapid7 is not active"
  echo "      systemctl is-active ir_agent"
  echo "      $rapid7Status"
  echo "Rapid7-Insight-Agent: FAIL" >> $serviceStatusFile
fi

echo ""


#--------------- Splunk Forwarder -------------------------#
# Get Status
echo "Splunk Validation"
echo "  Checking Splunk Forwarder status..."
splunkStatus=$(systemctl is-active SplunkForwarder)

if [[ "$splunkStatus" == "active" ]]; then
  echo "    Splunk Forwarder is active"

  echo "  Checking Splunk configuration..."
  splunkVersion=$(sudo cat /opt/splunkforwarder/etc/splunk.version | grep "VERSION" | cut -d'=' -f2)
  splunkURI=$(sudo cat /opt/splunkforwarder/etc/system/local/deploymentclient.conf | grep "targetUri" | cut -f 3 -d " ")

  echo "Splunk-Universal-Forwarder: $splunkVersion" >> $serviceVersionFile
  echo "SplunkURI: $splunkURI" >> $serviceConfigFile

  if [[ "$splunkURI" == "$verifiedSplunkURI" ]]; then
    echo "  Splunk configuration is valid"
    echo "Splunk-Universal-Forwarder: PASS" >> $serviceStatusFile
  else
    echo "  Splunk configuration is not valid"
    echo "Splunk-Universal-Forwarder: FAIL" >> $serviceStatusFile
  fi

else
  echo "    Splunk Forwarder not running"
  echo "      systemctl is-active SplunkForwarder"
  echo "      $splunkStatus"
  echo "Splunk-Universal-Forwarder: FAIL" >> $serviceStatusFile
  echo "Splunk-Universal-Forwarder: Unknown" >> $serviceVersionFile
  echo "SplunkURI: Unknown" >> $serviceConfigFile
fi

echo ""

#--------------- Amazon CloudWatch agent -------------------------#
echo "Amazon CloudWatch Agent"
echo "  Checking Amazon CloudWatch status..."
cwStatus=$(sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status | grep '"status": "running"')
if [[ "$cwStatus" == *"running"* ]]; then
  echo "    CloudWatch agent running"
  echo "  Confirming Amazon CloudWatch configuration..."
  cwConfig=$(sudo more /opt/aws/amazon-cloudwatch-agent/logs/configuration-validation.log | grep "cloudwatch-agent.toml is valid")
  
  if [[ "$cwConfig" == *"valid"* ]]; then
      echo "    CloudWatch configuration is valid"
      echo "CloudWatchConfigurationValidation: Valid" >> $serviceConfigFile
      echo "amazon-cloudwatch-agent: PASS" >> $serviceStatusFile
    else
      echo "    CloudWatch agent not configured properly"
      echo "CloudWatchConfigurationValidation: Invalid" >> $serviceStatusFile
      echo "amazon-cloudwatch-agent: FAIL" >> $serviceStatusFile
    fi

  echo "    Checking version..."
  cwVersion=$(rpm -qa|grep -I cloudwatch | cut -d'-' -f4-)
  echo "amazon-cloudwatch-agent: $cwVersion" >> $serviceVersionFile
  
else
  echo "    CloudWatch agent not running"
  echo "amazon-cloudwatch-agent: FAIL" >> $serviceStatusFile
fi

echo ""


#--------------- CrowdStrike-Falcon-Sensor agent -------------------------#
echo "CrowdStrike Validation"
echo "  Checking CrowdStrike status..."
crowdStrikeStatus=$(systemctl is-active falcon-sensor)

if [[ "$crowdStrikeStatus" == "active" ]]; then
  echo "    CrowdStrike agent running"
  echo "CrowdStrike-Falcon-Sensor: PASS" >> $serviceStatusFile
  echo "    Getting version..."
  crowdStrikeVersion=$(sudo /opt/CrowdStrike/falconctl -g --version | cut -d'=' -f2 | cut -c 2-)
  # crowdStrikeVersion=$(rpm -qa|grep -I falcon-sensor | cut -d'-' -f3-)
  echo "CrowdStrike-Falcon-Sensor: $crowdStrikeVersion" >> $serviceVersionFile

else
  echo "    CrowdStrike agent is not running"
  echo "      systemctl is-active falcon-sensor"
  echo "      $crowdStrikeStatus"
  echo "CrowdStrike-Falcon-Sensor: FAIL" >> $serviceStatusFile
fi

echo ""

#TODO: print an extra line in the file for the wordcount command function in generate report
echo " " >> $serviceStatusFile


echo "Test results"
cat $serviceStatusFile
echo ""
echo "Versions"
cat $serviceVersionFile
echo ""
echo "Configurations"
cat $serviceConfigFile