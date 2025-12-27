#!/bin/bash

# Initialize WordPress for Staging Environment
# This script is executed inside the staging-php-fpm container

set -e

echo "Initializing WordPress for Staging Environment..."

# Wait a bit more for database to be fully ready
sleep 10

# Check if WordPress is already installed
if [ -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress is already installed in Staging environment."
    exit 0
fi

# Download WordPress
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root --path=/var/www/html
fi

# Create wp-config.php
echo "Creating wp-config.php for Staging environment..."
wp config create --allow-root \
    --path=/var/www/html \
    --dbname="${STAGING_DB_NAME}" \
    --dbuser="${STAGING_DB_USER}" \
    --dbpass="${STAGING_DB_PASSWORD}" \
    --dbhost="staging-db:3306" \
    --dbprefix="wp_" \
    --force

# Add security keys
wp config shuffle-salts --allow-root --path=/var/www/html

# Add Redis configuration
echo "Adding Redis configuration..."
wp config set WP_CACHE true --allow-root --path=/var/www/html
wp config set WP_REDIS_HOST staging-redis --allow-root --path=/var/www/html
wp config set WP_REDIS_PORT 6379 --allow-root --path=/var/www/html

# Install WordPress
echo "Installing WordPress for Staging environment..."
wp core install --allow-root \
    --path=/var/www/html \
    --url="http://199.19.74.239" \
    --title="Acme Revival - Staging" \
    --admin_user="admin" \
    --admin_password="SecureStagingPassword123!" \
    --admin_email="staging@acmerevival.com" \
    --skip-email

# Set site URL
wp option update siteurl "http://199.19.74.239" --allow-root --path=/var/www/html
wp option update home "http://199.19.74.239" --allow-root --path=/var/www/html

# Set timezone
wp option update timezone_string "America/New_York" --allow-root --path=/var/www/html

# Update permalink structure
wp rewrite structure '/%postname%/' --allow-root --path=/var/www/html

# Install and activate recommended plugins
wp plugin install redis-cache --allow-root --path=/var/www/html --activate
wp plugin install wordpress-seo --allow-root --path=/var/www/html --activate
wp plugin install wp-optimize --allow-root --path=/var/www/html --activate

# Optimize database
wp db optimize --allow-root --path=/var/www/html

# Clean up
wp cache flush --allow-root --path=/var/www/html

echo "WordPress Staging environment initialized successfully!"