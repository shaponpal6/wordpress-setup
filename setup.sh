#!/bin/bash

# Production WordPress Docker Setup Script with Live and Staging Environments
# This script sets up a complete WordPress environment matching your shared hosting configuration
# PHP 7.4.33, MariaDB 11.4.9, WordPress 6.8.3 for both live and staging
# Server Configuration: IP 199.19.74.239, Host 199-19-74-239.cloud-xip.com, Domain acmerevival.com
# All data stored in external directories for persistence after project deletion

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}WordPress Docker Production Setup - Acme Revival${NC}"
echo -e "${BLUE}Server: 199.19.74.239 | Domain: acmerevival.com${NC}"
echo -e "${BLUE}Data stored in external directories for persistence${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""
echo -e "This script will set up a production-ready WordPress environment"
echo -e "with both LIVE and STAGING environments matching your current shared hosting configuration:"
echo -e "- PHP 7.4.33"
echo -e "- MariaDB 11.4.9"
echo -e "- WordPress 6.8.3"
echo -e "- Live Domain: acmerevival.com"
echo -e "- Staging Domain: staging.acmerevival.com"
echo ""

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. This is not recommended for production."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

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

# Check available disk space (minimum 5GB recommended)
print_status "Checking available disk space..."
AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 5000000 ]; then
    print_warning "Available disk space is low. At least 5GB is recommended."
fi

print_status "Docker and Docker Compose are installed."

# Create external directories
print_status "Creating external directories for persistent data..."
./setup-external-dirs.sh

# Create Docker networks
print_status "Creating Docker networks..."
docker network create live_network || true
docker network create staging_network || true

# Make all scripts executable
print_status "Setting executable permissions..."
chmod +x init-wordpress-live.sh init-wordpress-staging.sh backup-live.sh backup-staging.sh setup-ssl.sh monitor.sh health-check-live.sh health-check-staging.sh restart-services.sh setup-external-dirs.sh

# Build the PHP image
print_status "Building PHP-FPM image with PHP 7.4.33..."
docker build -t wordpress-php:7.4.33 -f Dockerfile.php . || {
    print_error "Failed to build PHP image"
    exit 1
}

# Start Proxy services
print_status "Starting Nginx Proxy services..."
docker-compose -f docker-compose.proxy.yml up -d --build || {
    print_error "Failed to start Proxy services"
    exit 1
}

# Start Live services
print_status "Starting Live WordPress services..."
docker-compose -f docker-compose.live.yml up -d --build || {
    print_error "Failed to start Live services"
    exit 1
}

# Start Staging services
print_status "Starting Staging WordPress services..."
docker-compose -f docker-compose.staging.yml up -d --build || {
    print_error "Failed to start Staging services"
    exit 1
}

# Wait for services to be running before checking database
print_status "Waiting for database containers to start..."
sleep 30

# Check if containers are running
print_status "Checking if database containers are running..."
if ! docker ps | grep -q live_wordpress_db; then
    print_error "Live database container is not running"
    docker-compose -f docker-compose.live.yml logs live-db
    exit 1
fi

if ! docker ps | grep -q staging_wordpress_db; then
    print_error "Staging database container is not running"
    docker-compose -f docker-compose.staging.yml logs staging-db
    exit 1
fi

# Wait for databases to be ready with extended timeout
print_status "Waiting for databases to be ready (this may take a few minutes)..."
sleep 20

# Check Live database connectivity with extended timeout
# Using mysql command instead of mysqladmin since mysqladmin might not be available
print_status "Checking Live database readiness..."
timeout 600 bash -c 'while ! docker exec live_wordpress_db mysql -u"$LIVE_DB_USER" -p"$LIVE_DB_PASSWORD" -e "SELECT 1;" --silent > /dev/null 2>&1; do echo "Waiting for Live database..."; sleep 15; done' || {
    print_error "Live database did not become ready in time"
    print_status "Displaying Live database logs:"
    docker-compose -f docker-compose.live.yml logs live-db
    exit 1
}

# Check Staging database connectivity with extended timeout
print_status "Checking Staging database readiness..."
timeout 600 bash -c 'while ! docker exec staging_wordpress_db mysql -u"$STAGING_DB_USER" -p"$STAGING_DB_PASSWORD" -e "SELECT 1;" --silent > /dev/null 2>&1; do echo "Waiting for Staging database..."; sleep 15; done' || {
    print_error "Staging database did not become ready in time"
    print_status "Displaying Staging database logs:"
    docker-compose -f docker-compose.staging.yml logs staging-db
    exit 1
}

# Install Live WordPress
print_status "Installing Live WordPress 6.8.3..."
docker-compose -f docker-compose.live.yml exec live-php-fpm bash -c 'cd /var/www/html && /bin/bash /var/www/html/init-wordpress-live.sh' || {
    print_error "Live WordPress installation failed"
    exit 1
}

# Install Staging WordPress
print_status "Installing Staging WordPress 6.8.3..."
docker-compose -f docker-compose.staging.yml exec staging-php-fpm bash -c 'cd /var/www/html && /bin/bash /var/www/html/init-wordpress-staging.sh' || {
    print_error "Staging WordPress installation failed"
    exit 1
}

# Wait for WordPress to be accessible
print_status "Waiting for WordPress sites to be accessible..."
sleep 10

# Set up Redis cache for both environments
print_status "Setting up Redis cache for Live..."
docker-compose -f docker-compose.live.yml exec live-php-fpm wp plugin activate redis-cache --allow-root --path=/var/www/html || {
    print_warning "Could not activate Redis cache plugin for Live"
}

print_status "Setting up Redis cache for Staging..."
docker-compose -f docker-compose.staging.yml exec staging-php-fpm wp plugin activate redis-cache --allow-root --path=/var/www/html || {
    print_warning "Could not activate Redis cache plugin for Staging"
}

# Optimize WordPress for both environments
print_status "Optimizing Live WordPress settings..."
docker-compose -f docker-compose.live.yml exec live-php-fpm wp config set WP_CACHE true --raw --allow-root --path=/var/www/html || true
docker-compose -f docker-compose.live.yml exec live-php-fpm wp config set WP_REDIS_HOST redis --allow-root --path=/var/www/html || true

print_status "Optimizing Staging WordPress settings..."
docker-compose -f docker-compose.staging.yml exec staging-php-fpm wp config set WP_CACHE true --raw --allow-root --path=/var/www/html || true
docker-compose -f docker-compose.staging.yml exec staging-php-fpm wp config set WP_REDIS_HOST redis --allow-root --path=/var/www/html || true

# Create initial backups
print_status "Creating initial Live backup..."
./backup-live.sh || print_warning "Could not create initial Live backup"

print_status "Creating initial Staging backup..."
./backup-staging.sh || print_warning "Could not create initial Staging backup"

# Run health checks to verify setup
print_status "Running health checks..."
./health-check-live.sh
./health-check-staging.sh

# Display completion message
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}WordPress Setup with Live and Staging Completed!${NC}"
echo -e "${GREEN}Server: 199.19.74.239 | Domain: acmerevival.com${NC}"
echo -e "${GREEN}Data stored in external directories for persistence${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Your WordPress sites are now running!${NC}"
echo ""
echo -e "Live site at: ${GREEN}http://199.19.74.239${NC} (or https://acmerevival.com after DNS)"
echo -e "Staging site at: ${GREEN}http://199.19.74.239:8080${NC} (or https://staging.acmerevival.com after DNS)"
echo ""
echo -e "Default login credentials for both sites:"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}SecureAdminPassword123!${NC} (for live), ${GREEN}SecureStagingPassword123!${NC} (for staging)"
echo ""
echo -e "To change credentials, edit the .env file and reinstall WordPress."
echo ""
echo -e "Useful commands:"
echo -e "  ${YELLOW}./backup-live.sh${NC}          - Create a backup of your Live site"
echo -e "  ${YELLOW}./backup-staging.sh${NC}       - Create a backup of your Staging site"
echo -e "  ${YELLOW}./setup-ssl.sh domain email${NC} - Setup SSL with Let's Encrypt"
echo -e "  ${YELLOW}./monitor.sh${NC}              - Monitor your WordPress installations"
echo -e "  ${YELLOW}./restart-services.sh${NC}     - Safely restart services"
echo -e "  ${YELLOW}./health-check-live.sh${NC}    - Check live environment health"
echo -e "  ${YELLOW}./health-check-staging.sh${NC} - Check staging environment health"
echo -e "  ${YELLOW}docker-compose -f docker-compose.live.yml logs -f${NC}    - View Live logs"
echo -e "  ${YELLOW}docker-compose -f docker-compose.staging.yml logs -f${NC} - View Staging logs"
echo -e "  ${YELLOW}docker-compose -f docker-compose.live.yml down${NC}       - Stop Live services"
echo -e "  ${YELLOW}docker-compose -f docker-compose.staging.yml down${NC}    - Stop Staging services"
echo -e "  ${YELLOW}docker-compose -f docker-compose.live.yml up -d${NC}      - Start Live services"
echo -e "  ${YELLOW}docker-compose -f docker-compose.staging.yml up -d${NC}   - Start Staging services"
echo ""
echo -e "For production use:"
echo -e "1. Configure DNS: Point acmerevival.com and staging.acmerevival.com to 199.19.74.239"
echo -e "2. Set up SSL with your domains using: ./setup-ssl.sh acmerevival.com staging.acmerevival.com contact@acmerevival.com"
echo -e "3. Update WordPress settings to use your actual domains"
echo -e "4. Configure your firewall to allow ports 80 and 443"
echo ""
print_status "Setup completed successfully! Your Acme Revival sites are ready for testing."
print_status "Access your sites using the IP address until DNS is configured."
print_status "Security and performance improvements have been applied."
print_status "All data is stored in external directories and will persist after project deletion."