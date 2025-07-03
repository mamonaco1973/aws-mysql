#!/bin/bash

############################################
# SETUP: Configure AWS Region
############################################

# AWS region where Secrets Manager and RDS/Aurora are deployed
AWS_REGION="us-east-2"

############################################
# STEP 1: Download Sakila Sample Database
############################################

echo "NOTE: Downloading sakila sample data."

# Change directory into the Terraform RDS project folder
cd 01-rds

# Change into the 'data' subfolder where we'll store sample data
cd data

# Remove any existing Sakila data directory to avoid conflicts
rm -f -r sakila-db

# Remove any existing Sakila zip files to ensure a clean download
rm -f -r sakila*.zip*

# Download Sakila sample database zip file silently (-q)
wget -q https://downloads.mysql.com/docs/sakila-db.zip

# Unzip the downloaded archive into the current directory
unzip sakila-db.zip

# Return to the project root directory
cd ..
cd ..

############################################
# STEP 2: Load Sakila Data into MySQL RDS
############################################

# NOTE: You could uncomment this to show Aurora endpoint in logs
# echo "NOTE: Primary Aurora Endpoint: $PRIMARY_ENDPOINT"

# Name of the secret in AWS Secrets Manager that holds RDS credentials
SECRET_NAME="mysql-credentials"

# Retrieve secret JSON string (user/password/endpoint) from Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
   --region "$AWS_REGION" \
   --secret-id "$SECRET_NAME" \
   --query 'SecretString' \
   --output text)

# Extract 'user' field using jq JSON parser
USER=$(echo "$SECRET_JSON" | jq -r .user)

# Extract 'password' field
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)

# Extract 'endpoint' field (RDS endpoint)
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

# Print endpoint info for verification
echo "NOTE: Primary RDS Endpoint: $ENDPOINT"
echo "NOTE: Loading 'sakila' data into RDS"

# Create 'sakila' database if it doesn't exist
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS sakila;"

# Load Sakila schema SQL into the database
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila data SQL into the database
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-data.sql

############################################
# STEP 3: Load Sakila Data into Aurora MySQL
############################################

# Update secret name to reference Aurora credentials
SECRET_NAME="aurora-credentials"

# Retrieve secret JSON for Aurora credentials and endpoint
SECRET_JSON=$(aws secretsmanager get-secret-value \
   --region "$AWS_REGION" \
   --secret-id "$SECRET_NAME" \
   --query 'SecretString' \
   --output text)

# Extract Aurora username
USER=$(echo "$SECRET_JSON" | jq -r .user)

# Extract Aurora password
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)

# Extract Aurora endpoint
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

# Print Aurora endpoint info
echo "NOTE: Loading 'sakila' data into Aurora"
echo "NOTE: Primary Aurora Endpoint: $ENDPOINT"

# Create 'sakila' database in Aurora
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS sakila;"

# COMMENT OUT 'default_storage_engine' line in schema (Aurora compatibility)
sed -i 's/^\(.*default_storage_engine.*\)/-- \1/' ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila schema into Aurora
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-schema.sql

# Load Sakila data into Aurora
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-data.sql


#!/usr/bin/env bash

# Retrieve URL for phpmyadmin-rds
rds_url=$(aws apprunner list-services \
  --region us-east-2 \
  --query "ServiceSummaryList[?ServiceName=='phpmyadmin-rds'].ServiceArn" \
  --output text | \
  xargs -I {} aws apprunner describe-service \
    --region us-east-2 \
    --service-arn {} \
    --query "Service.ServiceUrl" \
    --output text)

# Retrieve URL for phpmyadmin-aurora
aurora_url=$(aws apprunner list-services \
  --region us-east-2 \
  --query "ServiceSummaryList[?ServiceName=='phpmyadmin-aurora'].ServiceArn" \
  --output text | \
  xargs -I {} aws apprunner describe-service \
    --region us-east-2 \
    --service-arn {} \
    --query "Service.ServiceUrl" \
    --output text)

# Output the results
echo "NOTE: phpMyAdmin RDS URL:     https://$rds_url"
echo "NOTE: phpMyAdmin Aurora URL:  https://$aurora_url"
