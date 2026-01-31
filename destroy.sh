#!/bin/bash

############################################
# SET DEFAULT AWS REGION
############################################

# Export the AWS region to ensure all AWS CLI commands run in the correct context
export AWS_DEFAULT_REGION="us-east-2"

############################################
# STEP 1: DESTROY RDS INSTANCES
############################################

# Navigate into the Terraform directory for EC2 deployment
cd 01-rds

# Initialize Terraform backend and provider plugins (safe for destroy)
terraform init

# Destroy all RDS instances and related resources provisioned by Terraform
terraform destroy -auto-approve  # Auto-approve skips manual confirmation prompts

# Return to root directory after RDS teardown
cd ..

#!/bin/bash
# ==============================================================================
# FILE: destroy.sh
# ==============================================================================
# ORCHESTRATION SCRIPT: RDS TEARDOWN
# ==============================================================================
# Destroys all RDS-related infrastructure provisioned via Terraform.
#
# High-level flow:
#   1) Set the AWS default region for CLI and Terraform.
#   2) Initialize Terraform in the RDS workspace.
#   3) Destroy all managed RDS resources non-interactively.
#
# Notes:
# - This script irreversibly deletes database resources.
# - `terraform destroy -auto-approve` skips confirmation prompts.
# - Intended for labs, demos, and controlled teardown scenarios only.
# ==============================================================================

# ==============================================================================
# STEP 0: SET AWS DEFAULT REGION
# ==============================================================================
# Export the AWS region used by Terraform and AWS CLI commands.
# ==============================================================================
export AWS_DEFAULT_REGION="us-east-2"

# ==============================================================================
# STEP 1: DESTROY RDS INFRASTRUCTURE
# ==============================================================================
# Tear down all RDS resources defined in the Terraform configuration.
# ==============================================================================
cd 01-rds

# Initialize Terraform backend and providers (safe for destroy).
terraform init

# Destroy all Terraform-managed resources without prompting.
terraform destroy -auto-approve

# Return to the project root directory.
cd ..
