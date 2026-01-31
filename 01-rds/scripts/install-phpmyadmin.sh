#!/bin/bash
# ================================================================================
# File: install-phpmyadmin.sh
#
# Purpose:
#   Fully non-interactive installation of phpMyAdmin on Ubuntu 24.04
#   configured for MySQL
#
# Notes:
#   - NO local MySQL/MariaDB installation
#   - dbconfig-common explicitly disabled
#   - Apache exposed normally (no IP restrictions)
# ================================================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------------------------
# Update system
# --------------------------------------------------------------------------------
sudo apt update -y

# --------------------------------------------------------------------------------
# Install Apache + PHP + required extensions
# --------------------------------------------------------------------------------
sudo apt install -y \
  apache2 \
  php \
  libapache2-mod-php \
  php-mysql \
  php-mbstring \
  php-zip \
  php-gd \
  php-json \
  php-curl \
  unzip \
  mysql-client

# --------------------------------------------------------------------------------
# Preseed phpMyAdmin debconf answers (NO PROMPTS)
# --------------------------------------------------------------------------------
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

# --------------------------------------------------------------------------------
# Install phpMyAdmin non-interactively
# --------------------------------------------------------------------------------
sudo apt install -y phpmyadmin

# --------------------------------------------------------------------------------
# Configure phpMyAdmin for Aurora
# --------------------------------------------------------------------------------
sudo tee /etc/phpmyadmin/config.inc.php >/dev/null <<EOF
<?php
\$cfg['blowfish_secret'] = '$(openssl rand -hex 16)';

\$i = 1;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = '${DB_ENDPOINT}';
\$cfg['Servers'][\$i]['port'] = '${DB_PORT}';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
EOF

# --------------------------------------------------------------------------------
# Enable required Apache modules
# --------------------------------------------------------------------------------
sudo a2enmod php8.3 rewrite

# --------------------------------------------------------------------------------
# Restart Apache
# --------------------------------------------------------------------------------
sudo systemctl restart apache2

# --------------------------------------------------------------------------------
# Final status
# --------------------------------------------------------------------------------
echo "=================================================================="
echo "phpMyAdmin installed and configured (NO PROMPTS)"
echo "Database endpoint : ${DB_ENDPOINT}"
echo "Access URL        : http://<INSTANCE_IP>/phpmyadmin"
echo "=================================================================="

# --------------------------------------------------------------------------------
# Load the sample database
# --------------------------------------------------------------------------------

cd /tmp
wget -q https://downloads.mysql.com/docs/sakila-db.zip
unzip sakila-db.zip
cd sakila 

USER=${DB_USER}
PASSWORD=${DB_PASSWORD}
ENDPOINT=${DB_ENDPOINT}

# Log endpoint information.
echo "NOTE: Primary RDS Endpoint: $ENDPOINT"
echo "NOTE: Loading 'sakila' data into RDS"

# Create the Sakila database if it does not already exist.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS sakila;"

# Load Sakila schema.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < sakila-schema.sql

# Load Sakila data.
mysql -h "$ENDPOINT" -u "$USER" -p"$PASSWORD" sakila \
  < sakila-data.sql