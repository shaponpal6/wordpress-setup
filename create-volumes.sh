#!/bin/bash

# Create necessary volume directories for WordPress setup
set -e

echo "Creating volume directories for Acme Revival WordPress setup..."

# Create volume directories
mkdir -p volumes/live-db-data
mkdir -p volumes/live-wp-data
mkdir -p volumes/staging-db-data
mkdir -p volumes/staging-wp-data

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

# Set proper permissions
chown -R 1000:1000 volumes/
chown -R 1000:1000 wp-content-live/
chown -R 1000:1000 wp-content-staging/
chown -R 1000:1000 logs/

echo "Volume directories created successfully!"
echo "Directories created:"
echo "  - volumes/live-db-data"
echo "  - volumes/live-wp-data"
echo "  - volumes/staging-db-data"
echo "  - volumes/staging-wp-data"
echo "  - logs/nginx, logs/php-live, logs/php-staging, logs/mysql"
echo "  - wp-content-live, wp-content-staging"
echo "  - ssl"