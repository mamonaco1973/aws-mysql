#!/bin/bash
# ==============================================================================
# FILE: apply.sh
# ==============================================================================
# ORCHESTRATION SCRIPT: RDS DEPLOYMENT AND VALIDATION
# ==============================================================================
# Drives the end-to-end workflow for provisioning RDS infrastructure and
# validating the resulting environment.
#
# High-level flow:
#   1) Validate local environment prerequisites.
#   2) Set the AWS default region for CLI and Terraform.
#   3) Provision RDS infrastructure using Terraform.
#   4) Run post-deployment validation and data load checks.
#
# Notes:
# - This script is written to fail fast if any prerequisite step fails.
# - Terraform is executed non-interactively using auto-approve.
# ==============================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on error
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail

# ==============================================================================
# STEP 0: ENVIRONMENT VALIDATION
# ==============================================================================
# Verify that all required tools, credentials, and environment variables
# are present before proceeding.
# ==============================================================================
./check_env.sh

# Abort immediately if the environment validation fails.
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ==============================================================================
# STEP 1: SET AWS DEFAULT REGION
# ==============================================================================
# Export the AWS region used by Terraform and AWS CLI commands.
# ==============================================================================
export AWS_DEFAULT_REGION="us-east-2"

# ==============================================================================
# STEP 2: TERRAFORM - BUILD DATABASE INFRASTRUCTURE
# ==============================================================================
# Initialize and apply the Terraform configuration that provisions
# RDS-related resources.
# ==============================================================================
echo "NOTE: Building Database Instances."

# Change into the Terraform working directory.
cd 01-rds

# Initialize Terraform backend and providers.
terraform init

# Apply Terraform configuration non-interactively.
terraform apply -auto-approve

# Return to the project root directory.
cd ..

# ==============================================================================
# STEP 3: POST-DEPLOYMENT VALIDATION
# ==============================================================================
# Validate the deployed infrastructure and load any required sample data.
# ==============================================================================
./validate.sh
