#!/bin/bash

# Create necessary external directories for WordPress setup
# These will persist even after project folder is deleted

set -e

echo "Creating external directories for Acme Revival WordPress setup..."

# Create system directories for configuration
sudo mkdir -p /etc/wordpress/config/mariadb
sudo mkdir -p /etc/wordpress/config/php

# Create directories for WordPress content
sudo mkdir -p /var/www/wordpress-live/wp-content
sudo mkdir -p /var/www/wordpress-staging/wp-content

# Create log directories
sudo mkdir -p /var/log/wordpress/php-live
sudo mkdir -p /var/log/wordpress/php-staging
sudo mkdir -p /var/log/wordpress/mysql

# Create SSL directory
sudo mkdir -p /etc/ssl/certs

# Create WordPress config directories if they don't exist
sudo mkdir -p /etc/wordpress/config/nginx

# Set proper permissions
sudo chown -R www-data:www-data /var/www/wordpress-live/
sudo chown -R www-data:www-data /var/www/wordpress-staging/
sudo chown -R www-data:www-data /var/log/wordpress/
sudo chown -R www-data:www-data /etc/wordpress/config/php/
sudo chown -R www-data:www-data /etc/wordpress/config/mariadb/

# Copy configuration files to external locations
sudo cp -f config/php/php.ini /etc/wordpress/config/php/php.ini
sudo cp -f config/php/www.conf /etc/wordpress/config/php/www.conf
sudo cp -f config/mariadb/custom.cnf /etc/wordpress/config/mariadb/custom.cnf

echo "External directories created successfully!"
echo "Directories created:"
echo "  - /etc/wordpress/config/mariadb"
echo "  - /etc/wordpress/config/php"
echo "  - /var/www/wordpress-live/wp-content"
echo "  - /var/www/wordpress-staging/wp-content"
echo "  - /var/log/wordpress/php-live, php-staging, mysql"
echo "  - /etc/ssl/certs"
echo ""
echo "Configuration files copied to external locations."
echo "These directories will persist even after the project folder is deleted."