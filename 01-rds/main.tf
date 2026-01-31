# ==============================================================================
# AWS PROVIDER CONFIGURATION
# ==============================================================================
# Configures the AWS provider used by Terraform to authenticate with AWS and
# manage cloud resources.
#
# Notes:
# - The provider must be configured before any AWS resources can be created.
# - Credentials are resolved via the standard AWS provider chain:
#     * Environment variables
#     * Shared credentials file
#     * AWS CLI configuration
#     * Instance / task role (when running in AWS)
# - Always verify the target region to avoid deploying resources into the
#   wrong account or geography.
# ==============================================================================
provider "aws" {
  # ----------------------------------------------------------------------------
  # REGION SELECTION
  # ----------------------------------------------------------------------------
  # AWS region where all resources in this configuration will be created.
  # Example regions:
  # - us-east-1 (N. Virginia)
  # - us-east-2 (Ohio)
  # - us-west-2 (Oregon)
  region = "us-east-2"
}
