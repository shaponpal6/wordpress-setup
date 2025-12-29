#!/bin/bash

# Production WordPress Start Script
# Starts WordPress with MariaDB and phpMyAdmin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Production WordPress Start Script${NC}"
echo -e "${BLUE}================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create external directories if they don't exist
print_status "Ensuring external directories exist..."
sudo mkdir -p /var/www/wordpress-live/wp-content
sudo mkdir -p /var/www/wordpress-staging/wp-content
sudo mkdir -p /var/log/wordpress/live
sudo mkdir -p /var/log/wordpress/staging
sudo mkdir -p /var/log/wordpress/mysql
sudo mkdir -p /etc/wordpress/live/config/mariadb
sudo mkdir -p /etc/wordpress/live/config/php
sudo mkdir -p /etc/wordpress/staging/config/mariadb
sudo mkdir -p /etc/wordpress/staging/config/php

# Set proper permissions
sudo chown -R www-data:www-data /var/www/wordpress-live/ 2>/dev/null || true
sudo chown -R www-data:www-data /var/www/wordpress-staging/ 2>/dev/null || true
sudo chown -R www-data:www-data /var/log/wordpress/live/ 2>/dev/null || true
sudo chown -R www-data:www-data /var/log/wordpress/staging/ 2>/dev/null || true
sudo chown -R 999:999 /var/log/wordpress/mysql/ 2>/dev/null || true

# Build PHP image if needed
print_status "Building PHP-FPM image with PHP 7.4.33..."
docker build -t wordpress-php:7.4.33 -f Dockerfile.php . || {
    print_error "Failed to build PHP image"
    exit 1
}

# Start the services
print_status "Starting WordPress production stack..."

# Start live environment first
print_status "Starting Live WordPress environment..."
docker-compose -f docker-compose.live.yml up -d --build

# Start staging environment
print_status "Starting Staging WordPress environment..."
docker-compose -f docker-compose.staging.yml up -d --build

# Wait for databases to be healthy
print_status "Waiting for databases to be healthy..."
for i in {1..30}; do
    LIVE_DB_STATUS=$(docker-compose -f docker-compose.live.yml ps --health live-db 2>/dev/null | grep -v "health\|CONTAINER" | awk '{print $NF}' || echo "unknown")
    STAGING_DB_STATUS=$(docker-compose -f docker-compose.staging.yml ps --health staging-db 2>/dev/null | grep -v "health\|CONTAINER" | awk '{print $NF}' || echo "unknown")
    
    if [[ "$LIVE_DB_STATUS" == "healthy" ]] && [[ "$STAGING_DB_STATUS" == "healthy" ]]; then
        print_status "Both databases are healthy"
        break
    fi
    
    echo "Waiting for databases to be healthy... ($i/30)"
    sleep 10
done

# Install WordPress if not already installed
if [ ! -f "/var/www/wordpress-live/wp-config.php" ]; then
    print_status "Installing WordPress for Live environment..."
    # Wait a bit more for the database to be fully ready
    sleep 15
    
    # Run the initialization script
    docker-compose -f docker-compose.live.yml exec -T live-php-fpm bash -c 'wp core download --allow-root --path=/var/www/html' || true
    docker-compose -f docker-compose.live.yml exec -T live-php-fpm bash -c 'wp config create --allow-root --path=/var/www/html --dbname="${LIVE_DB_NAME}" --dbuser="${LIVE_DB_USER}" --dbpass="${LIVE_DB_PASSWORD}" --dbhost="live-db:3306"' || true
    docker-compose -f docker-compose.live.yml exec -T live-php-fpm bash -c 'wp core install --allow-root --path=/var/www/html --url="http://199.19.74.239" --title="Live WordPress Site" --admin_user="admin" --admin_password="SecureAdminPassword123!" --admin_email="admin@example.com"' || true
fi

if [ ! -f "/var/www/wordpress-staging/wp-config.php" ]; then
    print_status "Installing WordPress for Staging environment..."
    # Wait a bit more for the database to be fully ready
    sleep 15
    
    # Run the initialization script
    docker-compose -f docker-compose.staging.yml exec -T staging-php-fpm bash -c 'wp core download --allow-root --path=/var/www/html' || true
    docker-compose -f docker-compose.staging.yml exec -T staging-php-fpm bash -c 'wp config create --allow-root --path=/var/www/html --dbname="${STAGING_DB_NAME}" --dbuser="${STAGING_DB_USER}" --dbpass="${STAGING_DB_PASSWORD}" --dbhost="staging-db:3306"' || true
    docker-compose -f docker-compose.staging.yml exec -T staging-php-fpm bash -c 'wp core install --allow-root --path=/var/www/html --url="http://199.19.74.239" --title="Staging WordPress Site" --admin_user="admin" --admin_password="SecureStagingPassword123!" --admin_email="staging@example.com"' || true
fi

print_status "WordPress production stack started successfully!"
echo ""
echo -e "${GREEN}Services are now running:${NC}"
echo -e "  Live WordPress: http://199.19.74.239"
echo -e "  Staging WordPress: http://199.19.74.239"
echo -e "  Live phpMyAdmin: http://127.0.0.1:8081"
echo -e "  Staging phpMyAdmin: http://127.0.0.1:8082"
echo ""
print_status "Use 'docker-compose -f docker-compose.live.yml logs -f' to view live logs"
print_status "Use 'docker-compose -f docker-compose.staging.yml logs -f' to view staging logs"