# AWS CLI Overview

## Purpose

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services.

## Assumptions

- AWS CLI is not already installed on the instance
- The script will not be stored on the instance and only run through Packer

## Requirements

- AWS CLI v2
- Public internet access to [https://awscli.amazonaws.com/](https://awscli.amazonaws.com/)

## Dependencies

- Packages
  - curl
  - unzip

## Implementation

1. Install the pre-requisite packages (if necessary)
1. The AWS CLI is downloaded from AWS and decompressed
1. The AWS CLI is installed

### Packer Integration

To install and configure Rapid7, execute within the Packer provisioner section via a [shell provisioner](https://www.packer.io/docs/provisioners/shell):

```json
{
  "type": "shell",
  "script": "src/installationScripts/AWSCli/cli-install.sh"
}
```

## Tests

- TBD
