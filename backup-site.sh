#!/bin/bash

# WordPress Backup Script
set -e

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
SITE_NAME="wordpress_site"

echo "Starting backup of WordPress site..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create database dump
echo "Creating database backup..."
docker exec wordpress_db mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/${SITE_NAME}_db_${DATE}.sql"

# Create WordPress files backup
echo "Creating WordPress files backup..."
docker exec wordpress_php tar -czf "/tmp/${SITE_NAME}_files_${DATE}.tar.gz" -C /var/www/html .

# Copy the backup file from container to host
docker cp "wordpress_php:/tmp/${SITE_NAME}_files_${DATE}.tar.gz" "$BACKUP_DIR/"

# Clean up temporary file in container
docker exec wordpress_php rm -f "/tmp/${SITE_NAME}_files_${DATE}.tar.gz"

# Create a summary file
cat > "$BACKUP_DIR/${SITE_NAME}_backup_${DATE}.txt" << EOF
Backup created on: $(date)
Database: ${SITE_NAME}_db_${DATE}.sql
Files: ${SITE_NAME}_files_${DATE}.tar.gz
WordPress Version: 6.8.3
PHP Version: 7.4.33
MariaDB Version: 11.4.9
EOF

echo "Backup completed! Files saved to: $BACKUP_DIR"
echo "Backup files:"
ls -la "$BACKUP_DIR/${SITE_NAME}"*