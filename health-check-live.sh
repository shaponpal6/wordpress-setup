#!/bin/bash

# Live WordPress Health Check Script for Acme Revival
# Server: 199.19.74.239, Domain: acmerevival.com
set -e

echo "=== Acme Revival Live WordPress Health Check ==="
echo "Server: 199.19.74.239 | Domain: acmerevival.com"

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

# Check Live services status
echo ""
echo "=== Live Service Status ==="
LIVE_SERVICES=("live-db" "live-php-fpm")
for service in "${LIVE_SERVICES[@]}"; do
    CONTAINER_NAME="live_wordpress_$service"
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

# Check Live database connectivity
echo ""
echo "=== Live Database Health ==="
if docker exec live_wordpress_db mysql -u"$LIVE_DB_USER" -p"$LIVE_DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Database connection: ✅ OK"
    
    # Check database size
    DB_SIZE=$(docker exec live_wordpress_db mysql -u"$LIVE_DB_USER" -p"$LIVE_DB_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' FROM information_schema.tables WHERE table_schema = '$LIVE_DB_NAME';" | tail -1)
    echo "Database size: $DB_SIZE MB"
    
    # Check database uptime
    DB_UPTIME=$(docker exec live_wordpress_db mysql -u"$LIVE_DB_USER" -p"$LIVE_DB_PASSWORD" -e "SHOW STATUS LIKE 'Uptime';" | tail -1 | awk '{print $2}')
    echo "Database uptime: $((DB_UPTIME / 60)) minutes"
else
    echo "Database connection: ❌ Failed"
fi

# Check Live WordPress accessibility
echo ""
echo "=== Live WordPress Health ==="
if curl -f -s http://199.19.74.239 > /dev/null 2>&1; then
    echo "WordPress site: ✅ Accessible"
    
    # Check WordPress version
    WP_VERSION=$(curl -s http://199.19.74.239 | grep -o 'content="WordPress [0-9.]*' | head -1 | cut -d' ' -f2)
    echo "WordPress version: $WP_VERSION"
    
    # Check response time
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}s' http://199.19.74.239)
    echo "Response time: $RESPONSE_TIME"
else
    echo "WordPress site: ❌ Not accessible"
fi

# Check Live resource usage
echo ""
echo "=== Live Resource Usage ==="
docker stats --no-stream | grep -E "(live_wordpress_|live_phpmyadmin)" | while read line; do
    echo "$line"
done

# Check Live disk usage
echo ""
echo "=== Live Disk Usage ==="
LIVE_DB_SIZE=$(docker exec live_wordpress_db du -sh /var/lib/mysql 2>/dev/null | cut -f1)
LIVE_WP_SIZE=$(docker exec live_wordpress_php du -sh /var/www/html 2>/dev/null | cut -f1)
echo "Live Database volume: $LIVE_DB_SIZE"
echo "Live WordPress volume: $LIVE_WP_SIZE"

# Check Live logs for errors
echo ""
echo "=== Live Error Logs ==="
LIVE_PHP_ERRORS=$(docker-compose -f docker-compose.live.yml logs --tail=10 live-php-fpm 2>/dev/null | grep -i "error" | wc -l)
echo "Live PHP errors in last 10 lines: $LIVE_PHP_ERRORS"

LIVE_DB_ERRORS=$(docker-compose -f docker-compose.live.yml logs --tail=10 live-db 2>/dev/null | grep -i "error" | wc -l)
echo "Live DB errors in last 10 lines: $LIVE_DB_ERRORS"

# Security checks
echo ""
echo "=== Live Security Checks ==="
# Check if SSL is configured
if curl -f -s https://acmerevival.com > /dev/null 2>&1; then
    echo "SSL Certificate: ✅ Available"
else
    echo "SSL Certificate: ⚠️  Not configured (Run ./setup-ssl.sh)"
fi

# Check for security headers
SECURITY_HEADERS=$(curl -I -s http://199.19.74.239 | grep -E "X-Frame-Options|X-XSS-Protection|X-Content-Type-Options" | wc -l)
if [ "$SECURITY_HEADERS" -ge 3 ]; then
    echo "Security headers: ✅ Configured"
else
    echo "Security headers: ⚠️  Missing"
fi

echo ""
echo "Live health check completed for Acme Revival server 199.19.74.239!"