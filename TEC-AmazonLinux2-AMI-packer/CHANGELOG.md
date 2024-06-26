# Changelog

All notable changes to this project will be documented in this file and the summary of each will be stored in DynamoDB

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and all dates are in [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html), YYYY-MM-DD.

#### [1.0] - YYYY-MM-DD
>The AMI release includes several automation efforts around hostname configurations aand DNS records. 
> This AMI release includes fixes around DNS & Route53 and Okta ASA registration bugs. 
>This release includes the refactoring of the OS Hardening script to leverage Ansible and implemented upon backing of the AMI; Updated documentation for README.md and CHANGELOG.md; Disable network configurations (IPv6 and ECN); Updated CrowdStrike version. 
>This release includes the integration of AutoDocs within the Golden AMI pipeline; Enhanced test automation. Release includes sharing to sandbox functional accounts

##### Added
- Shared to Sandbox functional accounts
- Included/updated tags for Golden AMI
- AutoDocs Integration
  - IQOQ verification is done in tec-cpe-shs-prd and a random functional account leveraging AutoDocs
  - Placeholder invocations for DEV & TST environments
- Enhanced Test Automation
  - Operating System Configuration tests
  - Installed Tools tests
  - AMI Release testing (Encryption, SSM, etc)
- Documentation
  - Updated README.md for Golden AMI Pipeline
  - Added README.md for each tool/configuration
  - Added CHANGELOG.md & style.md documents
  - Added automation around documentation for DynamoDB
- OS Hardening script
  - Refactored to leverage Ansible for CIS Level 1 implementation
  - Scripts executed prior to baking AMI

##### Modified
- Automated hostname update to align with provided EC2 instance tag, 'Name'
- Automated DNS record creation in Route53 based on updated hostname

##### Fixed
- Disabled SELinux
- Addressed the bug where the server would enroll with thhe incorrect Okta ASA Project
- Addressed the bug where DNS records in Route53 where not properly updated based on updated hostname when the instance was rebooted
- Disabled ECN
- Disabled IPv6
- Resolved SSHD misconfiguration
- Fixed bug with rsyslog which prevented logs from being writtten to /var/log/*
- Updated CrowdStrike version to 6.12 per Security & CrowdStrike teams' guidance

##### Known Bugs
- Multiple versions of CrowdStrike exist on the instance due to CrowdStike's auto-upgrade process

##### Deprecated
- Deprecated shell script for OS hardening

#### [0.2] - 2020-12-15
>This AMI release includes version upgrades to installed tools & a fix related to NTP configuration

##### Fixed

- Updated NTP server to be synchronized

##### Modified

- Updated version of the following tools:
  - CrowdStrike
  - Rapid7
  - Splunk Universal Forwarder

#### [0.1] - 2020-11-13
> Base Golden AMI pipeline created

##### Modified

- Replaced hardcoded VPC information
- Updated CrowdStrike and OS harddning scripts
- Splunk Deployment

##### Fixed
- Fixed /tmp issues
- AMI Names

##### Added
- Added bind, util, wget utilities
- Added OS Version info
- CloudWatch
- AMI Artifact files


##### Summary

Initial release of the Golden AMI for AMZN2
                                       