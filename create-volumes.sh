#!/bin/bash

# Create necessary volume directories for WordPress setup
set -e

echo "Creating volume directories for Acme Revival WordPress setup..."

# Create log directories
mkdir -p logs/nginx
mkdir -p logs/php-live
mkdir -p logs/php-staging
mkdir -p logs/mysql

# Create wp-content directories
mkdir -p wp-content-live
mkdir -p wp-content-staging

# Create SSL directory
mkdir -p ssl

# Create config directories if they don't exist
mkdir -p config/nginx
mkdir -p config/php
mkdir -p config/mariadb
mkdir -p config/security

echo "Volume directories created successfully!"
echo "Directories created:"
echo "  - logs/nginx, logs/php-live, logs/php-staging, logs/mysql"
echo "  - wp-content-live, wp-content-staging"
echo "  - ssl"
echo "  - config directories"
echo ""
echo "Note: Docker named volumes will be created automatically when containers start."