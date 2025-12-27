#!/bin/bash

# Staging WordPress Health Check Script
set -e

echo "=== Staging WordPress Health Check ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose is not installed"
    exit 1
fi

# Check Staging services status
echo ""
echo "=== Staging Service Status ==="
STAGING_SERVICES=("staging-db" "staging-php-fpm")
for service in "${STAGING_SERVICES[@]}"; do
    CONTAINER_NAME="staging_wordpress_$service"
    if [ "$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)" = "running" ]; then
        echo "$service: ✅ Running"
    else
        echo "$service: ❌ Not running"
    fi
    
    # Check health status if available
    HEALTH_STATUS=$(docker inspect --format='{{json .State.Health}}' "$CONTAINER_NAME" 2>/dev/null | jq -r '.Status' 2>/dev/null)
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "  Health: ✅ Healthy"
    elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
        echo "  Health: ❌ Unhealthy"
    elif [ "$HEALTH_STATUS" = "starting" ]; then
        echo "  Health: ⏳ Starting"
    fi
done

# Check Staging database connectivity
echo ""
echo "=== Staging Database Health ==="
if docker exec staging_wordpress_db mysql -u"$STAGING_DB_USER" -p"$STAGING_DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Database connection: ✅ OK"
    
    # Check database size
    DB_SIZE=$(docker exec staging_wordpress_db mysql -u"$STAGING_DB_USER" -p"$STAGING_DB_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' FROM information_schema.tables WHERE table_schema = '$STAGING_DB_NAME';" | tail -1)
    echo "Database size: $DB_SIZE MB"
else
    echo "Database connection: ❌ Failed"
fi

# Check Staging WordPress accessibility
echo ""
echo "=== Staging WordPress Health ==="
if curl -f -s http://localhost > /dev/null 2>&1; then
    echo "WordPress site: ✅ Accessible"
    
    # Check WordPress version
    WP_VERSION=$(curl -s http://localhost | grep -o 'content="WordPress [0-9.]*' | head -1 | cut -d' ' -f2)
    echo "WordPress version: $WP_VERSION"
else
    echo "WordPress site: ❌ Not accessible"
fi

# Check Staging resource usage
echo ""
echo "=== Staging Resource Usage ==="
docker stats --no-stream | grep -E "(staging_wordpress_|staging_phpmyadmin)" | while read line; do
    echo "$line"
done

# Check Staging disk usage
echo ""
echo "=== Staging Disk Usage ==="
STAGING_DB_SIZE=$(docker exec staging_wordpress_db du -sh /var/lib/mysql 2>/dev/null | cut -f1)
STAGING_WP_SIZE=$(docker exec staging_wordpress_php du -sh /var/www/html 2>/dev/null | cut -f1)
echo "Staging Database volume: $STAGING_DB_SIZE"
echo "Staging WordPress volume: $STAGING_WP_SIZE"

# Check Staging logs for errors
echo ""
echo "=== Staging Error Logs ==="
STAGING_PHP_ERRORS=$(docker-compose -f docker-compose.staging.yml logs --tail=10 staging-php-fpm 2>/dev/null | grep -i "error" | wc -l)
echo "Staging PHP errors in last 10 lines: $STAGING_PHP_ERRORS"

STAGING_DB_ERRORS=$(docker-compose -f docker-compose.staging.yml logs --tail=10 staging-db 2>/dev/null | grep -i "error" | wc -l)
echo "Staging DB errors in last 10 lines: $STAGING_DB_ERRORS"

echo ""
echo "Staging health check completed!"