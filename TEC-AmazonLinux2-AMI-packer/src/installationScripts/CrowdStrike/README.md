# CrowdStrike Overview

## Purpose

CrowdStrike is a cloud-based solution that unifies Next Generation AntiVirus (NGAV), Endpoint Detection and Response (EDR), device control, vulnerability assessment, and IT hygiene

## Assumptions

- JFrog credentials stored in Takeda approved vault (i.e. AWS Secrets Manager)
- CodeBuild container has capability to query the Takeda approved vault to get credentials
- The agent-install.sh will not be run as-is outside of Packer

## Requirements

- CrowdStrike artifacts are stored in JFrog Artifactory
- Packer configuration has access to credentials with least privilege to download CrowdStrike artifact(s)

## Dependencies

- A CrowdStrike ID has been provided
- CrowdStrike artifact(s) are stored in [artifactory/endpoint-security-generic-local/CrowdStrike/](https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/CrowdStrike/)

## Implementation

#TODO: Talk to Abraham
Any links, documents, etc should be prefaced here.

### Script Overview

### Packer Integration

To install and configure CrowdStrike, execute within the Packer provisioner section via a [shell provisioner](https://www.packer.io/docs/provisioners/shell):

```json
{
  "type": "shell",
  "script": "src/installationScripts/CrowdStrike/agent-install.sh",
  "environment_vars": [
    "user={{ user `username` }}",
    "password={{ user `pass` }}",
    "crowdstrike_id={{ user `crowdstrike` }}",
    "AWS_DEFAULT_REGION={{ user `aws_region` }}"
  ]
}
```

## Tests

- TBD