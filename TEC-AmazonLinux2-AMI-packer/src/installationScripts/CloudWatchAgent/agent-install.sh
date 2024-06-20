#/bin/sh
 
# Exit the immediately upon a non-zero exit code
#set -e
# Every command is printed as it is executed
set -x


# Download the binaries for the AWS CloudWatch Agent
echo "Downloading CloudWatch Agent binaries..."
echo ""
# Trust the repository signing key:
echo "Importing the repository signing key..."
sudo yum install amazon-cloudwatch-agent -y
echo ""

# Setting default config file
echo "Configuring the CloudWatch Agent..."
sudo cp /tmp/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent.json
echo ""

echo "Reloading the CloudWatch Agent with the new config..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent.json -s
echo ""

echo "CloudWatch Agent status:"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
echo ""