# Hostname Configuration Overview

## Purpose

The script is used to update the instance's hostname to match the instance's EC2 tag, `Name`.

## Assumptions

- The instance has EC2 read-only access
- The EC2 instance is tagged with a key, `Name`, that has a value matching Takeda naming standards.

## Requirements

- The script will be run upon boot
- The script will be run as a systemd service
- The script can also be run stand-alone

## Dependencies

- AWS CLI

## Script Overview

1. The Bash script calls the instance metadata to identify the EC2 instance ID.
1. The AWS CLI is called to run AWS APIs to identify the tag, `Name`, and capture the value.
    - If there is no tag (or the instance does not have sufficient permissions), the script stops
1. The tag value is compared against the existing hostname
    - If the instance tag value and the hostname do not match, the hostname is updated and the instance is rebooted
    - If the instance tag value and the hostname do match, the Splunk Forwarder is restarted to ensure theh latest hostname appears in Splunk

### Packer Integration

To upload the script & service file on the AMI, execute within the Packer provisioner section via a [file provisioner](https://www.packer.io/docs/provisioners/file):

```json
{
  "type": "file",
  "source": "src/configurationScripts/HostnameConfiguration/update-hostname.service",
  "destination": "/tmp/update-hostname.service"
},
{
  "type": "file",
  "source": "src/configurationScripts/HostnameConfiguration/update-hostname.sh",
  "destination": "/tmp/update-hostname.sh"
}
```

The service file and shell script need to be moved the appropriate location. A `setup.sh` script was developed to make the necessary modifications prior to baking the AMI. To execute this within the Packer provisioner section via a [shell provisioner](https://www.packer.io/docs/provisioners/shell):

```json
{
  "type": "shell",
  "script": "src/configurationScripts/HostnameConfiguration/setup.sh"
}
```

### Execution

To execute the script standalong, run the commands below:

```bash
/opt/update-hostname.sh
```

## Tests

- TBD
