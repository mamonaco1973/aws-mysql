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
# SAFETY: FAIL FAST
# ==============================================================================
# -e: exit on error
# -u: treat unset variables as errors
# -o pipefail: catch failures in pipelines
# ==============================================================================
set -euo pipefail

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

# Return
