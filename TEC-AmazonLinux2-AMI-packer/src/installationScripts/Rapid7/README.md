# Rapid7 Overview

## Purpose

Rapid7 is a network vulnerability scanner that prioritizes vulnerabilities based on combination of CVSS score, exploitability, malware exposure, and vulnerability age, helping you weed through thousands of results to focus on the vulnerabilities most likely to be used in an actual attack

## Assumptions

- JFrog credentials stored in Takeda approved vault (i.e. AWS Secrets Manager)
- CodeBuild container has capability to query the Takeda approved vault to get credentials
- The agent-install.sh will not be run as-is outside of Packer

## Requirements

- Rapid7 artifacts are stored in JFrog Artifactory
- Packer configuration has access to credentials with least privilege to download Rapid7 artifact(s)
- Packer environment variables set for JFrog Artifactory credentials

## Dependencies

- Rapid7 artifact(s) are stored in [artifactory/endpoint-security-generic-local/Rapid7/](https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Rapid7/)

## Implementation

The [Rapid7 documentation](https://insightagent.help.rapid7.com/docs/virtualization) documentation is used as a basis for the Takeda installation and configuration.

### Script Overview

### Packer Integration

To install and configure Rapid7, execute within the Packer provisioner section via a [shell provisioner](https://www.packer.io/docs/provisioners/shell):

```json
{
  "type": "shell",
  "script": "src/installationScripts/Rapid7/agent-install.sh",
  "environment_vars": [
    "user={{ user `username` }}",
    "password={{ user `pass` }}",
    "token={{ user `tokenized` }}",
    "AWS_DEFAULT_REGION={{ user `aws_region` }}"
  ]
}
```

## Tests

- TBD