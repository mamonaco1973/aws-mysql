#!/bin/bash
# ==============================================================================
# FILE: validate.sh
# ==============================================================================
# ORCHESTRATION SCRIPT: SAKILA SAMPLE DATA LOAD AND VALIDATION
# ==============================================================================
# Downloads the MySQL Sakila sample database and loads it into:
#   - A standalone MySQL RDS instance
#   - An Aurora MySQL cluster
#
# High-level flow:
#   1) Download and unpack the Sakila sample dataset.
#   2) Load schema and data into MySQL RDS using Secrets Manager credentials.
#   3) Load schema and data into Aurora MySQL (Aurora-compatible adjustments).
#   4) Resolve and print phpMyAdmin App Runner service URLs.
#
# Notes:
# - Credentials and endpoints are retrieved from AWS Secrets Manager.
# - Endpoints are expected to be stored as hostnames (no port).
# - Requires: aws CLI, jq, mysql client, wget, unzip.
# ==============================================================================
# Enable strict shell behavior:
#   -e  Exit immediately on error
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail

# ==============================================================================
# SETUP: AWS REGION
# ==============================================================================
# AWS region where Secrets Manager, RDS, Aurora, and App Runner are deployed.
# ==============================================================================
AWS_REGION="us-east-2"

# ==============================================================================
# STEP 1: DOWNLOAD SAKILA SAMPLE DATABASE
# ==============================================================================
echo "NOTE: Downloading sakila sample data."

# Move into the Terraform RDS project directory.
cd 01-rds

# Move into the data directory used for sample assets.
cd data

# Remove any existing Sakila directory to avoid conflicts.
rm -rf sakila-db

# Remove any previously downloaded Sakila archives.
rm -rf sakila*.zip*

# Download the Sakila sample database archive.
wget -q https://downloads.mysql.com/docs/sakila-db.zip

# Unpack the archive into the current directory.
unzip sakila-db.zip

# Return to the project root directory.
cd ..
cd ..

# ==============================================================================
# STEP 2: LOAD SAKILA DATA INTO MYSQL RDS
# ==============================================================================
# Retrieve MySQL RDS credentials and endpoint from Secrets Manager.
# ==============================================================================
SECRET_NAME="mysql-credentials"

# Fetch the secret payload (JSON).
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text)

# Extract connection details.
USER=$(echo "$SECRET_JSON" | jq -r .user)
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

# Log endpoint information.
echo "NOTE: Primary RDS Endpoint: $ENDPOINT"
echo "NOTE: Loading 'sakila' data into RDS"

# Create the Sakila database if it does not already exist.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS sakila;"

# Load Sakila schema.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila data.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < ./01-rds/data/sakila-db/sakila-data.sql

# ==============================================================================
# STEP 3: LOAD SAKILA DATA INTO AURORA MYSQL
# ==============================================================================
# Retrieve Aurora credentials and endpoint from Secrets Manager.
# ==============================================================================
SECRET_NAME="aurora-credentials"

# Fetch the secret payload (JSON).
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text)

# Extract connection details.
USER=$(echo "$SECRET_JSON" | jq -r .user)
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

# Log endpoint information.
echo "NOTE: Loading 'sakila' data into Aurora"
echo "NOTE: Primary Aurora Endpoint: $ENDPOINT"

# Create the Sakila database if it does not already exist.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS sakila;"

# Comment out default_storage_engine for Aurora compatibility.
sed -i 's/^\(.*default_storage_engine.*\)/-- \1/' \
  ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila schema into Aurora.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila data into Aurora.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < ./01-rds/data/sakila-db/sakila-data.sql

# ==============================================================================
# STEP 4: PRINT PHPMYADMIN SERVICE URLS
# ==============================================================================
# Resolve App Runner service URLs for phpMyAdmin frontends.
# ==============================================================================

# Retrieve phpMyAdmin URL for MySQL RDS.
rds_url=$(aws apprunner list-services \
  --region "$AWS_REGION" \
  --query "ServiceSummaryList[?ServiceName=='phpmyadmin-rds'].ServiceArn" \
  --output text | \
  xargs -I {} aws apprunner describe-service \
    --region "$AWS_REGION" \
    --service-arn {} \
    --query "Service.ServiceUrl" \
    --output text)

# Retrieve phpMyAdmin URL for Aurora.
aurora_url=$(aws apprunner list-services \
  --region "$AWS_REGION" \
  --query "ServiceSummaryList[?ServiceName=='phpmyadmin-aurora'].ServiceArn" \
  --output text | \
  xargs -I {} aws apprunner describe-service \
    --region "$AWS_REGION" \
    --service-arn {} \
    --query "Service.ServiceUrl" \
    --output text)

# Output resolved URLs.
echo "NOTE: phpMyAdmin RDS URL:     https://$rds_url"
echo "NOTE: phpMyAdmin Aurora URL:  https://$aurora_url"
