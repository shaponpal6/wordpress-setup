#!/bin/bash

# WordPress Restore Script
set -e

BACKUP_DIR="/backups"
DB_DUMP_FILE=""
FILES_ARCHIVE=""

echo "WordPress Restore Script"
echo "Usage: $0 <database_dump.sql> <files_archive.tar.gz>"
echo ""

if [ $# -ne 2 ]; then
    echo "Error: Please provide both database dump and files archive"
    exit 1
fi

DB_DUMP_FILE="$1"
FILES_ARCHIVE="$2"

if [ ! -f "$DB_DUMP_FILE" ]; then
    echo "Error: Database dump file does not exist: $DB_DUMP_FILE"
    exit 1
fi

if [ ! -f "$FILES_ARCHIVE" ]; then
    echo "Error: Files archive does not exist: $FILES_ARCHIVE"
    exit 1
fi

echo "Restoring from:"
echo "  Database: $DB_DUMP_FILE"
echo "  Files: $FILES_ARCHIVE"
echo ""
echo "WARNING: This will overwrite your current WordPress installation!"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

echo "Stopping WordPress services..."
docker-compose down

echo "Restoring database..."
docker exec -i wordpress_db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$DB_DUMP_FILE"

echo "Restoring WordPress files..."
# Remove current WordPress files
docker exec wordpress_php rm -rf /var/www/html/*
# Extract backup files
docker cp "$FILES_ARCHIVE" wordpress_php:/tmp/restore_files.tar.gz
docker exec wordpress_php tar -xzf /tmp/restore_files.tar.gz -C /var/www/html --strip-components=1
docker exec wordpress_php rm /tmp/restore_files.tar.gz

# Set proper permissions
docker exec wordpress_php chown -R www-data:www-data /var/www/html
docker exec wordpress_php find /var/www/html -type f -exec chmod 644 {} \;
docker exec wordpress_php find /var/www/html -type d -exec chmod 755 {} \;

echo "Starting WordPress services..."
docker-compose up -d

echo "Restore completed!"
echo "Please verify that your site is working correctly."
echo "You may need to update the site URL in WordPress settings if the domain has changed."