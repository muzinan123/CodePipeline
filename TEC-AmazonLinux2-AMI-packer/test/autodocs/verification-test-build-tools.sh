#!/bin/bash
set -e

# This script contains AMI Build Verification tests

##Ansible
# Identify the version of Ansible being leveraged
# Identify the version of Ansible Lint being leveraged

##AnsiblePlaybook
# Review Ansible Lint results

##Bash
# Identify the version of Bash being leveraged

##Packer
# Identify the version of Packer being leveraged
# Confirm `packer validate` returns successfully
# TODO: Consider incorporating `packer inspect`

# Variables used throughout script
echo "Configuring environment..."
echo "  Setting varibles..."
buildUtilsStatusFile="serviceStatus-Build.txt"
buildUtilsVersionFile="serviceVersion-Build.txt"

# Check for existing test results
if [ -e "$buildUtilsStatusFile" ]; then
  echo "  Removing old test results"
  sudo rm $buildUtilsStatusFile -f
else
  echo "  No old test results to remove"
fi
touch $buildUtilsStatusFile

if [ -e "$buildUtilsVersionFile" ]; then
  echo "  Removing old version results"
  sudo rm $buildUtilsVersionFile -f
else
  echo "  No old version results to remove"
fi
touch $buildUtilsVersionFile

echo 'Printing versions of software used for compliance...'

# ------------- Ansible ------------- #
ansibleVersion=$(ansible --version | head -n 1 | cut -d ' ' -f 2)
echo "Ansible: $ansibleVersion" >> $buildUtilsVersionFile

if [[ $ansibleVersion == '2.10.10' ]]; then
  echo "Ansible: PASS" >> $buildUtilsStatusFile
else
  echo "Ansible: FAIL" >> $buildUtilsStatusFile
fi

ansiblePlaybookVersion=$(ansible-playbook --version | head -n 1 | cut -d ' ' -f 2)
echo "AnsiblePlaybook: $ansiblePlaybookVersion" >> $buildUtilsVersionFile

if [[ $ansiblePlaybookVersion == '2.10.10' ]]; then
  echo "AnsiblePlaybook: PASS" >> $buildUtilsStatusFile
else
  echo "AnsiblePlaybook: FAIL" >> $buildUtilsStatusFile
fi

echo "Validating Ansible playbooks..."
echo "Skipping linting for now..."
# ansible-lint -vvv src/configurationScripts/OSHardening/ansible/RHEL8-CIS_Benchmark_L1.yml -x 303,305,306,602 > ansibleLintingResults.log

if [ -f "ansibleLintingResults.log" ]; then
  while IFS= read -r line
  do
    lintMessage=$(echo $line | cut -d ":" -f 3)
    errorCode=${lintMessage:2:4}
    errorMessage=$(echo $lintMessage | cut -d "]" -f 2)

    echo $lintMessage
  done < ansibleLintingResults.log
else
  echo "linting not completed"
fi

# -------------  Bash   ------------- #
bashVersion=$(bash --version | head -1 | cut -d ' ' -f 4 | cut -d '(' -f 1)
echo "Bash: $bashVersion" >> $buildUtilsVersionFile

if [[ $bashVersion == '5.0.17' ]]; then
  echo "Bash: PASS" >> $buildUtilsStatusFile
else
  echo "Bash: FAIL" >> $buildUtilsStatusFile
fi

# ------------- Packer  ------------- #
packerVersion=$(./packer --version)
echo "Packer: $packerVersion" >> $buildUtilsVersionFile

if [[ $packerVersion == '1.6.2' ]]; then
  echo "Packer: PASS" >> $buildUtilsStatusFile
else
  echo "Packer: FAIL" >> $buildUtilsStatusFile
fi

# Prints the various components a template defines
# This can help you quickly learn about a template without having to dive into the config itself
echo "Inspecting Packer template..."
./packer inspect $CONFIG_FILE

# Validates the syntax and configuration of a template. 
# The command will return a zero exit status on success, and a non-zero exit status on failure. 
# Additionally, if a template doesn't validate, any error messages will be outputted.
echo "Validating Packer template..."
./packer validate $CONFIG_FILE

echo "Versions"
cat $buildUtilsVersionFile
