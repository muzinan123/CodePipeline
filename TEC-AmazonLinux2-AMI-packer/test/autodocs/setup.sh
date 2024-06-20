# TODO: Consider renaming/moving as it's used within the Packer build process
# Configure/Prepare verification test scripts
echo "Making subdirectory for amiTestSuite..."
sudo mkdir /opt/amiTestSuite
echo ""

echo "Moving verification-test-tool script..."
sudo mv /tmp/verification-test-tool.sh /opt/amiTestSuite
echo ""

echo "Ensure verification-test-tool script is executable..."
sudo chmod +x /opt/amiTestSuite/verification-test-tool.sh
echo ""

echo "Moving verification-test-osconfig script..."
sudo mv /tmp/verification-test-osconfig.sh /opt/amiTestSuite
echo ""

echo "Ensure verification-test-tool script is executable..."
sudo chmod +x /opt/amiTestSuite/verification-test-osconfig.sh
echo ""