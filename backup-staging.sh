#!/bin/bash

# Staging WordPress Backup Script for Acme Revival
# Server: 199.19.74.239, Domain: acmerevival.com
# All data stored in external directories for persistence after project deletion
set -e

BACKUP_DIR="/backups/staging"
DATE=$(date +%Y%m%d_%H%M%S)
SITE_NAME="staging_wordpress_site"

echo "Starting backup of Staging WordPress site..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create database dump
echo "Creating staging database backup..."
docker exec staging_wordpress_db mysqldump -u"$STAGING_DB_USER" -p"$STAGING_DB_PASSWORD" "$STAGING_DB_NAME" > "$BACKUP_DIR/${SITE_NAME}_db_${DATE}.sql"

# Create WordPress files backup
echo "Creating staging WordPress files backup..."
docker exec staging_wordpress_php tar -czf "/tmp/${SITE_NAME}_files_${DATE}.tar.gz" -C /var/www/html .

# Copy the backup file from container to host
docker cp "staging_wordpress_php:/tmp/${SITE_NAME}_files_${DATE}.tar.gz" "$BACKUP_DIR/"

# Clean up temporary file in container
docker exec staging_wordpress_php rm -f "/tmp/${SITE_NAME}_files_${DATE}.tar.gz"

# Create a summary file
cat > "$BACKUP_DIR/${SITE_NAME}_backup_${DATE}.txt" << EOF
Backup created on: $(date)
Database: ${SITE_NAME}_db_${DATE}.sql
Files: ${SITE_NAME}_files_${DATE}.tar.gz
WordPress Version: 6.8.3
PHP Version: 7.4.33
MariaDB Version: 11.4.9
Environment: Staging
Server: 199.19.74.239
Domain: staging.acmerevival.com
EOF

echo "Staging backup completed! Files saved to: $BACKUP_DIR"
echo "Backup files:"
ls -la "$BACKUP_DIR/${SITE_NAME}"*