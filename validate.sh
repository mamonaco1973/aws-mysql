# #!/bin/bash

# # Set your region if needed
AWS_REGION="us-east-2"

echo "NOTE: Downloading sakila sample data."
cd 01-rds
cd data
rm -f -r sakila-db
rm -f -r sakila*.zip*
wget -q https://downloads.mysql.com/docs/sakila-db.zip
unzip sakila-db.zip
cd ..
cd ..

# echo "NOTE: Primary Aurora Endpoint: $PRIMARY_ENDPOINT"

# Name of the secret created in Terraform
SECRET_NAME="mysql-credentials"

# Retrieve and parse the secret
SECRET_JSON=$(aws secretsmanager get-secret-value \
   --region "$AWS_REGION" \
   --secret-id "$SECRET_NAME" \
   --query 'SecretString' \
   --output text)

# Extract user and password using jq
USER=$(echo "$SECRET_JSON" | jq -r .user)
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

echo "NOTE: Primary RDS Endpoint: $ENDPOINT"
echo "NOTE: Loading 'sakila' data into RDS"

mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS sakila;"
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-schema.sql
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-data.sql

# Name of the secret created in Terraform

SECRET_NAME="aurora-credentials"

# Retrieve and parse the secret
SECRET_JSON=$(aws secretsmanager get-secret-value \
   --region "$AWS_REGION" \
   --secret-id "$SECRET_NAME" \
   --query 'SecretString' \
   --output text)

# Extract user and password using jq
USER=$(echo "$SECRET_JSON" | jq -r .user)
PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
ENDPOINT=$(echo "$SECRET_JSON" | jq -r .endpoint)

echo "NOTE: Loading 'sakila' data into Aurora"
echo "NOTE: Primary Auroa Endpoint: $ENDPOINT"

mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" -e "CREATE DATABASE IF NOT EXISTS sakila;"
sed -i 's/^\(.*default_storage_engine.*\)/-- \1/' ./01-rds/data/sakila-db/sakila-schema.sql
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-schema.sql
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila < ./01-rds/data/sakila-db/sakila-data.sql

