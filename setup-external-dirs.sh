#!/bin/bash

# Create necessary external directories for WordPress setup
# These will persist even after project folder is deleted
# Complete separation of live and staging environments

set -e

echo "Creating external directories for Acme Revival WordPress setup..."
echo "Ensuring complete separation of live and staging environments..."

# Create system directories for live configuration
sudo mkdir -p /etc/wordpress/live/config/mariadb
sudo mkdir -p /etc/wordpress/live/config/php

# Create system directories for staging configuration
sudo mkdir -p /etc/wordpress/staging/config/mariadb
sudo mkdir -p /etc/wordpress/staging/config/php

# Create directories for WordPress content - completely separate
sudo mkdir -p /var/www/wordpress-live/wp-content
sudo mkdir -p /var/www/wordpress-staging/wp-content

# Create separate log directories for live and staging
sudo mkdir -p /var/log/wordpress/live
sudo mkdir -p /var/log/wordpress/staging
sudo mkdir -p /var/log/wordpress/mysql

# Create SSL directory
sudo mkdir -p /etc/ssl/certs

# Create WordPress config directories if they don't exist
sudo mkdir -p /etc/wordpress/live/config/nginx
sudo mkdir -p /etc/wordpress/staging/config/nginx

# Set proper permissions for live environment
sudo chown -R www-data:www-data /var/www/wordpress-live/
sudo chown -R www-data:www-data /var/log/wordpress/live/
sudo chown -R www-data:www-data /etc/wordpress/live/config/php/
# MariaDB needs specific ownership (usually 999:999)
sudo chown -R 999:999 /etc/wordpress/live/config/mariadb/
sudo chown -R 999:999 /var/log/wordpress/mysql/

# Set proper permissions for staging environment
sudo chown -R www-data:www-data /var/www/wordpress-staging/
sudo chown -R www-data:www-data /var/log/wordpress/staging/
sudo chown -R www-data:www-data /etc/wordpress/staging/config/php/
sudo chown -R 999:999 /etc/wordpress/staging/config/mariadb/

# Copy configuration files to separate locations for live and staging
sudo cp -f config/php/php.ini /etc/wordpress/live/config/php/php.ini
sudo cp -f config/php/www.conf /etc/wordpress/live/config/php/www.conf
sudo cp -f config/mariadb/custom.cnf /etc/wordpress/live/config/mariadb/custom.cnf

# Copy staging configuration files separately
sudo cp -f config/php/php.ini /etc/wordpress/staging/config/php/php.ini
sudo cp -f config/php/www.conf /etc/wordpress/staging/config/php/www.conf
sudo cp -f config/mariadb/custom.cnf /etc/wordpress/staging/config/mariadb/custom.cnf

# Ensure configs are readable
sudo chmod 644 /etc/wordpress/live/config/mariadb/custom.cnf
sudo chmod 644 /etc/wordpress/staging/config/mariadb/custom.cnf

echo "External directories created successfully!"
echo "Complete separation of live and staging environments:"
echo "  - /etc/wordpress/live/config/mariadb"
echo "  - /etc/wordpress/live/config/php"
echo "  - /var/www/wordpress-live/wp-content"
echo "  - /var/log/wordpress/live"
echo "  - /etc/wordpress/staging/config/mariadb"
echo "  - /etc/wordpress/staging/config/php"
echo "  - /var/www/wordpress-staging/wp-content"
echo "  - /var/log/wordpress/staging"
echo "  - /var/log/wordpress/mysql"
echo "  - /etc/ssl/certs"
echo ""
echo "Configuration files copied to separate locations for live and staging."
echo "These directories will persist even after the project folder is deleted."
echo "Live and staging environments are completely isolated from each other."