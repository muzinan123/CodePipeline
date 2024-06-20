#/bin/sh

# Exit the immediately upon a non-zero exit code
set -e
# Every command is printed as it is executed
set -x


# Download CrowdStrike from JFrog Artifactory
echo "Downloading CrowdStrike..."
curl -L -u "$user:$password" https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Crowdstrike/AmazonLinux2/falcon-sensor-5.23.0-8703.amzn2.x86_64.rpm -o falcon-sensor-5.23.0-8703.amzn2.x86_64.rpm
echo ""

# install Crowdstrike
echo "Install CrowdStrike..."
sudo yum localinstall -y falcon-sensor-5.23.0-8703.amzn2.x86_64.rpm
echo ""

# Configure and set CID
echo "Set the CID for CrowdStrike..."
sudo /opt/CrowdStrike/falconctl -s --cid=$crowdstrike_id
echo ""

# Start the service
echo "Starting CrowdStrike..."
sudo systemctl start falcon-sensor
echo ""

# Enable the service
echo "Enabling CrowdStrike..."
sudo systemctl enable falcon-sensor
echo ""

# Status
echo "CrowdStrike status:"
sudo systemctl is-active falcon-sensor
echo ""