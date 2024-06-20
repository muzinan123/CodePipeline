## Automated Testing

For an AMI to be approved for use as a Golden, or Base image it is required that the
following tests must be performed to ensure the Endpoint Security agents and required
configurations a present and configured properly.

## Tests Performed

Tool Verification

### Tool Verification script

test/autodocs/verification-test-TOOL.sh

#### Tools being tested:

AWS Systems Manager Agent
AWS CloudWatch Agent
CrowdStrike Agent
Rapid7 Agent
Splunk Forwarder
ScaleFT Server Tools (Okta ASA)

All tools are examined to validate whether a process is installed/active.
All tools are examined to determine which version is being run.

#### For installation instructions: refer to main README.md file

#### Future enhancement(s):
- Compare agent installed version to expected version

### OS Configuration script

test/autodocs/verification-test-OS.sh

#### Configurations being verified:

Hardening Script was run
Hostname check: modification complete

SSH Connectivity check: verify SSH is enabled
IPV6 check: verify ipv6 is disabled
ECN check: verify ecn is disabled
Sudo check: enabled

SELinux check: active process
MOTD check : ensure MOTD is configured

NTP check: active process, valid server config
Timezone check: verify UTC time zone, check time synchronization
Chrony check: active process

All tools are examined to validate whether configuration is as expected.

#### Future enhancement(s):

For Linux and Windows:
- Domain Join: validate instance has joined onetakeda.com domain
- Reboot check: validate health status after instance reboot

Windows-specific
- RDP connectivity: validate instance has RDP
- Windows Defender Disabled: validate Explicit Congestion Notification (ECN) is disabled/uninstalled
- Windows Firewall Disabled: validate Windows Firewall is disabled/uninstalled
- Auto-Update Disabled: validate that Windows auto-update capability is disabled
- Japanese Language Pack: validate Windows AMIs have language pack installed

## Future Enhancements

### Build Verification - Future Enhancement

#### Test Cases:
Approved Packer version: validate version of Packer leveraged
Packer Build succeeded: validate Packer is built without errors

E.Saldivar comment: Pipeline will abandon build if Packer build is not completed successfully. Packer version is also printed out, but not validated.

### AMI Verification - Future Enhancement

#### Test Cases:
Encrypted AMI: validate all AMIs generated are encrypted
AMI shared to Supported Region(s): Validate that an AMI with a tag AWS_COMMIT_ID and a value of the CommitID exists in each supported region
Required AMI Tags: Validate the AMI has all required tags per TSD

### Release Preparation Verification - Future Enhancement

#### Test Cases:
Message Delivered to SNS topic: validate that the SNS topic(s) received the message
DynamoDB Entry: validate that a DynamoDB entry was created for this commit and AMI ID

### Release Verification - Future Enhancement

#### Test Cases:
Parameter store key/value pair: Validate that the SSM key has only one version and the value equals AMI ID generated

### Autodocs Validation - Future Enhancement

#### Test Cases:
Validate expected results against actual results: Send the JSON with actual values to AutoDocs to verify against expected values