#!/bin/bash

# WordPress Initialization Script
set -e

echo "Starting WordPress initialization..."

# Wait for database to be ready
echo "Waiting for database to be ready..."
until mysql -h db -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; do
    echo "Waiting for database connection..."
    sleep 5
done

echo "Database is ready!"

# Check if WordPress is already installed
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Installing WordPress..."
    
    # Download WordPress if not already present
    if [ ! -f /usr/src/wordpress.tar.gz ]; then
        echo "Downloading WordPress..."
        curl -o /usr/src/wordpress.tar.gz -SL https://wordpress.org/wordpress-6.8.3.tar.gz
    fi
    
    # Extract WordPress
    echo "Extracting WordPress..."
    tar -xzf /usr/src/wordpress.tar.gz -C /tmp/
    cp -a /tmp/wordpress/. /var/www/html/
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Create wp-config.php
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root \
        --path=/var/www/html
    
    # Install WordPress
    echo "Installing WordPress..."
    wp core install \
        --url="$SITE_URL" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_USER" \
        --admin_password="$WORDPRESS_PASSWORD" \
        --admin_email="$WORDPRESS_EMAIL" \
        --allow-root \
        --path=/var/www/html
    
    # Set up basic WordPress configuration
    wp config set WP_DEBUG true --raw --allow-root --path=/var/www/html
    wp config set WP_DEBUG_LOG true --raw --allow-root --path=/var/www/html
    wp config set WP_DEBUG_DISPLAY false --raw --allow-root --path=/var/www/html
    
    # Install and activate Redis Object Cache
    wp plugin install redis-cache --activate --allow-root --path=/var/www/html
    wp plugin update --all --allow-root --path=/var/www/html
    
    # Install a default theme if needed
    wp theme install twentytwentyfour --activate --allow-root --path=/var/www/html
    
    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."
fi

# Ensure proper file permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
find /var/www/html -type f -exec chmod 644 {} \;
find /var/www/html -type d -exec chmod 755 {} \;

# Secure wp-config.php
chmod 644 /var/www/html/wp-config.php

echo "Initialization completed!"