#!/bin/bash

# Live WordPress Backup Script for Acme Revival
# Server: 199.19.74.239, Domain: acmerevival.com
# All data stored in external directories for persistence after project deletion
set -e

BACKUP_DIR="/backups/live"
DATE=$(date +%Y%m%d_%H%M%S)
SITE_NAME="live_wordpress_site"

echo "Starting backup of Live WordPress site..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create database dump
echo "Creating live database backup..."
docker exec live_wordpress_db mysqldump -u"$LIVE_DB_USER" -p"$LIVE_DB_PASSWORD" "$LIVE_DB_NAME" > "$BACKUP_DIR/${SITE_NAME}_db_${DATE}.sql"

# Create WordPress files backup
echo "Creating live WordPress files backup..."
docker exec live_wordpress_php tar -czf "/tmp/${SITE_NAME}_files_${DATE}.tar.gz" -C /var/www/html .

# Copy the backup file from container to host
docker cp "live_wordpress_php:/tmp/${SITE_NAME}_files_${DATE}.tar.gz" "$BACKUP_DIR/"

# Clean up temporary file in container
docker exec live_wordpress_php rm -f "/tmp/${SITE_NAME}_files_${DATE}.tar.gz"

# Create a summary file
cat > "$BACKUP_DIR/${SITE_NAME}_backup_${DATE}.txt" << EOF
Backup created on: $(date)
Database: ${SITE_NAME}_db_${DATE}.sql
Files: ${SITE_NAME}_files_${DATE}.tar.gz
WordPress Version: 6.8.3
PHP Version: 7.4.33
MariaDB Version: 11.4.9
Environment: Live
Server: 199.19.74.239
Domain: acmerevival.com
EOF

echo "Live backup completed! Files saved to: $BACKUP_DIR"
echo "Backup files:"
ls -la "$BACKUP_DIR/${SITE_NAME}"*