#!/bin/bash
# ==============================================================================
# SCRIPT: ENVIRONMENT VALIDATION
# ==============================================================================
# Validates that all required command-line tools are available and that the
# AWS CLI is properly authenticated.
#
# Validation checks:
#   - Required commands exist in the current PATH.
#   - AWS CLI can successfully authenticate to the active account.
#
# Notes:
# - This script is designed to fail fast.
# - Intended to be run before Terraform or deployment scripts.
# ==============================================================================

echo "NOTE: Validating that required commands are found in your PATH."

# ==============================================================================
# REQUIRED COMMANDS
# ==============================================================================
# List of CLI tools required for this project.
# ==============================================================================
commands=("aws" "terraform" "jq" "mysql")

# Track overall validation status.
all_found=true

# ------------------------------------------------------------------------------
# COMMAND AVAILABILITY CHECK
# ------------------------------------------------------------------------------
# Verify that each required command is available in PATH.
# ------------------------------------------------------------------------------
for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

# ------------------------------------------------------------------------------
# COMMAND CHECK RESULT
# ------------------------------------------------------------------------------
if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more required commands are missing."
  exit 1
fi

# ==============================================================================
# AWS AUTHENTICATION CHECK
# ==============================================================================
# Validate that the AWS CLI can authenticate using the current credentials.
# ==============================================================================
echo "NOTE: Checking AWS CLI connection."

# Attempt to retrieve caller identity (suppresses output).
aws sts get-caller-identity --query "Account" --output text > /dev/null

# Check the exit status of the AWS CLI command.
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to connect to AWS."
  echo "ERROR: Verify credentials, region, and environment variables."
  exit 1
else
  echo "NOTE: Successfully authenticated with AWS."
fi
