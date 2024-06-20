# Endpoint Security Agents

For an AMI to be approved for use as a Golden, or Base image it is required that the following agents be installed and configured for security to have the the ability to detect, protect and respond to security issues and incidents.

## Endpoint Protection

CrowdStrike

### Installing Crowdstrike

Artifactory download link: 

| Operating System | Artifactory Url |
|---- |---- |
| Linux / MacOS | https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Crowdstrike/LinuxRHELCentOSOracle8/falcon-sensor-5.23.0-8703.el8.x86_64.rpm |
| Windows 20XX | https://takedaawsuseast.jfrog.io/artifactory/endpoint-security-generic-local/Crowdstrike/windows/WindowsSensor.exe |

Install Instructions:
The automated script is located in the Crowdstike above, also the recipe book can be found in the link below
 https://mytakeda.sharepoint.com.rproxy.goskope.com/:w:/r/sites/FujiWorkstreamLeaders/_layouts/15/Doc.aspx?sourcedoc=%7BE821137D-F863-4C74-9346-09EB6B84B070%7D&file=Secure%20agent%20Recipe_Draft.docx&wdOrigin=OFFICECOM-WEB.MAIN.REC&action=default&mobileredirect=true&cid=ea536e12-044c-4350-8e64-9af76b207edf

## Security Operations - Forensics

Encase

### Installing Encase

Artifactory download link: 

Install Instructions:


## Vulnerability Detection

Rapid7 

### Installing Rapid7

Artifactory download link:

| Operating System | Artifactory Url |
|---- |---- |
| Linux / MacOS | https://takeda.jfrog.io/artifactory/endpoint-security-generic-local/Rapid7/Linux/agent_installer.sh |
| Windows 20XX | https://takeda.jfrog.io/artifactory/endpoint-security-generic-local/Rapid7/Windows/agentInstaller-x86_64.msi |

Install Instructions:

Refer to the Rapid7 documentation for installation procedures https://insightagent.help.rapid7.com/docs/virtualization 

Linux Install Command

``` shell
./agent_Installer.sh install_start --token ${rapid7-install-token}
```

Windows Install command

``` ps1
msiexec /i agentInstaller-x86_64.msi /l*v insight_agent_install_log.log /quiet CUSTOMTOKEN=${rapid7-install-token}
```

## Security Logging

Splunk

### Installing Splunk logging agent

Artifactory download link:

Install Instructions:

## Patch Management

SSM Agent

### Installing SSM Agent

AWS download link:

Install Instructions: