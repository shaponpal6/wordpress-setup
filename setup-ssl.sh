#!/bin/bash

# SSL Certificate Setup Script using Certbot for Live and Staging
set -e

LIVE_DOMAIN_NAME=""
STAGING_DOMAIN_NAME=""
EMAIL=""

echo "SSL Certificate Setup for WordPress - Live & Staging"

if [ $# -ne 3 ]; then
    echo "Usage: $0 <live_domain> <staging_domain> <email>"
    echo "Example: $0 live.example.com staging.example.com admin@example.com"
    exit 1
fi

LIVE_DOMAIN_NAME="$1"
STAGING_DOMAIN_NAME="$2"
EMAIL="$3"

echo "Setting up SSL for domains:"
echo "  Live: $LIVE_DOMAIN_NAME"
echo "  Staging: $STAGING_DOMAIN_NAME"
echo "Email for certificate notifications: $EMAIL"

# Stop nginx temporarily to allow certbot to bind to port 80
echo "Stopping nginx temporarily..."
docker-compose -f docker-compose.live.yml stop nginx 2>/dev/null || true
docker-compose -f docker-compose.staging.yml stop nginx 2>/dev/null || true

# Install certbot if not already installed
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y certbot
    elif command -v yum &> /dev/null; then
        yum install -y certbot
    else
        echo "Error: Could not install certbot. Please install it manually."
        exit 1
    fi
fi

# Obtain SSL certificate for Live
echo "Obtaining SSL certificate for Live: $LIVE_DOMAIN_NAME..."
certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$LIVE_DOMAIN_NAME"

# Check if Live certificate was obtained successfully
if [ -f "/etc/letsencrypt/live/$LIVE_DOMAIN_NAME/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$LIVE_DOMAIN_NAME/privkey.pem" ]; then
    echo "Live SSL certificate obtained successfully!"
    
    # Create ssl directory if it doesn't exist
    mkdir -p ssl
    
    # Copy certificates to ssl directory
    cp "/etc/letsencrypt/live/$LIVE_DOMAIN_NAME/fullchain.pem" "./ssl/live-ssl-cert.pem"
    cp "/etc/letsencrypt/live/$LIVE_DOMAIN_NAME/privkey.pem" "./ssl/live-ssl-cert.key"
    
    echo "Live SSL certificates copied to ssl/ directory"
else
    echo "Error: Failed to obtain Live SSL certificate"
    exit 1
fi

# Obtain SSL certificate for Staging
echo "Obtaining SSL certificate for Staging: $STAGING_DOMAIN_NAME..."
certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$STAGING_DOMAIN_NAME"

# Check if Staging certificate was obtained successfully
if [ -f "/etc/letsencrypt/live/$STAGING_DOMAIN_NAME/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$STAGING_DOMAIN_NAME/privkey.pem" ]; then
    echo "Staging SSL certificate obtained successfully!"
    
    # Copy certificates to ssl directory
    cp "/etc/letsencrypt/live/$STAGING_DOMAIN_NAME/fullchain.pem" "./ssl/staging-ssl-cert.pem"
    cp "/etc/letsencrypt/live/$STAGING_DOMAIN_NAME/privkey.pem" "./ssl/staging-ssl-cert.key"
    
    echo "Staging SSL certificates copied to ssl/ directory"
else
    echo "Error: Failed to obtain Staging SSL certificate"
    exit 1
fi

# Update .env file to enable SSL
sed -i 's/SSL_ENABLED=false/SSL_ENABLED=true/' .env

# Update nginx configuration to use the domain names
sed -i "s/live\.example\.com/$LIVE_DOMAIN_NAME/g" config/nginx/default.conf
sed -i "s/staging\.example\.com/$STAGING_DOMAIN_NAME/g" config/nginx/default.conf

echo "Updated .env to enable SSL"
echo "Updated nginx configuration to use domains: $LIVE_DOMAIN_NAME and $STAGING_DOMAIN_NAME"

# Set up auto-renewal cron job
echo "Setting up auto-renewal for SSL certificates..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --post-hook 'docker-compose -f docker-compose.live.yml restart nginx && docker-compose -f docker-compose.staging.yml restart nginx'") | crontab -

echo "SSL setup completed successfully!"
echo "Certificates will auto-renew every day at 12:00 PM"
echo "Your sites should now be accessible via:"
echo "  Live: https://$LIVE_DOMAIN_NAME"
echo "  Staging: https://$STAGING_DOMAIN_NAME"