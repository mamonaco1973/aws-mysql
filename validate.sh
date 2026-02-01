#!/bin/bash
# ==============================================================================
# FILE: validate.sh
# ==============================================================================
# PURPOSE:
#   Resolves and prints the public phpMyAdmin endpoints for two EC2 instances:
#   one backing an RDS MySQL deployment and one backing an Aurora MySQL
#   deployment.
#
# WHAT THIS SCRIPT DOES:
#   1) Looks up running EC2 instances by their Name tag.
#   2) Extracts each instance's PublicDnsName.
#   3) Fails fast if either instance has no public DNS (or isn't found).
#   4) Prints the resulting phpMyAdmin URLs for quick validation.
#
# PREREQUISITES:
#   - AWS CLI installed and configured with permissions for ec2:DescribeInstances
#   - Both target instances exist, are running, and have a public DNS name
#     (i.e., they are in a public subnet with a public IPv4 / EIP).
#
# NOTES:
#   - This script assumes phpMyAdmin is served at: /phpmyadmin/
#   - If multiple instances share the same Name tag, the first match is used.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------------------------
# AWS region where the phpMyAdmin EC2 instances are running.
AWS_REGION="us-east-2"

# ------------------------------------------------------------------------------
# RESOLVE phpMyAdmin ENDPOINTS
# ------------------------------------------------------------------------------
# Expected EC2 Name tag values for each phpMyAdmin host.
RDS_INSTANCE_NAME="phpmyadmin-rds"
AURORA_INSTANCE_NAME="phpmyadmin-aurora"

# ------------------------------------------------------------------------------
# FUNCTION: get_public_dns
# ------------------------------------------------------------------------------
# Returns the public DNS name for the first running EC2 instance whose Name tag
# matches the provided value.
#
# Args:
#   $1: instance_name  (value of the Name tag)
#
# Output:
#   Writes the PublicDnsName to stdout (or "None" if not present).
get_public_dns() {
  local instance_name="$1"

  aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --filters \
      "Name=tag:Name,Values=${instance_name}" \
      "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text
}

# Resolve public DNS names for each phpMyAdmin host.
RDS_PUBLIC_DNS=$(get_public_dns "${RDS_INSTANCE_NAME}")
AURORA_PUBLIC_DNS=$(get_public_dns "${AURORA_INSTANCE_NAME}")

# ------------------------------------------------------------------------------
# VALIDATION
# ------------------------------------------------------------------------------
# Fail fast if either instance is missing a public DNS name (not found, stopped,
# or running without a public interface).
if [[ -z "${RDS_PUBLIC_DNS}" || "${RDS_PUBLIC_DNS}" == "None" ]]; then
  echo "ERROR: ${RDS_INSTANCE_NAME} has no public DNS name"
  exit 1
fi

if [[ -z "${AURORA_PUBLIC_DNS}" || "${AURORA_PUBLIC_DNS}" == "None" ]]; then
  echo "ERROR: ${AURORA_INSTANCE_NAME} has no public DNS name"
  exit 1
fi

# ------------------------------------------------------------------------------
# DISPLAY RESULTS
# ------------------------------------------------------------------------------
# Print both endpoints in a consistent, copy/paste-friendly format.
echo "=========================================================================="
echo " phpMyAdmin Endpoints"
echo "=========================================================================="
echo
echo " RDS phpMyAdmin URL:"
echo "   http://${RDS_PUBLIC_DNS}/phpmyadmin/"
echo
echo " Aurora phpMyAdmin URL:"
echo "   http://${AURORA_PUBLIC_DNS}/phpmyadmin/"
echo
echo "=========================================================================="
