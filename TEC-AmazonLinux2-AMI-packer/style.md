# AMZN2 Golden AMI Pipeline Style Guide
#### Contact: [placeholder@takeda.com](mailto:placeholder@takeda.com)

## General

* Versions:
  * Ansible 3.2
  * Packer 1.6.2
* Programming language:
  * Python 3.8 or above
  * Packer HCL
* Do not commit garbage
  * Do not commit system files, hidden folders, IDE settings files
  * Do not commit modules or common libraries that can be pulled via package managers
    or installed via DevOps pipelines
  * Do not commit secrets
  * Do not commit binaries
  * Do not commit large media

## Packer Guide

* Avoid hardcoded values
* Parametrize as much as possible
* Avoid any secrets
* You **MUST** run your Packer configuration through [packer validate](https://www.packer.io/docs/commands/validate) and fix any warnings or errors

## Ansible Guide

* Avoid hardcoded values
* Parametrize as much as possible
* Avoid any secrets

## Shell Scripting Guide

* Avoid hardcoded values
* Parametrize as much as possible
* Avoid any secrets

## Testing Guide
