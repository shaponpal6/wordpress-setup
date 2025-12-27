#!/bin/bash

# WordPress Docker Monitoring Script for Live and Staging

echo "WordPress Docker Environment Monitoring - Live & Staging"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed"
    exit 1
fi

echo ""
echo "=== Live Service Status ==="
docker-compose -f docker-compose.live.yml ps

echo ""
echo "=== Staging Service Status ==="
docker-compose -f docker-compose.staging.yml ps

echo ""
echo "=== Container Resource Usage ==="
docker stats --no-stream

echo ""
echo "=== Disk Usage ==="
echo "Live Database volume:"
docker system df -v | grep live_db_data
echo ""
echo "Live WordPress volume:"
docker system df -v | grep live_wordpress_data
echo ""
echo "Staging Database volume:"
docker system df -v | grep staging_db_data
echo ""
echo "Staging WordPress volume:"
docker system df -v | grep staging_wordpress_data

echo ""
echo "=== Log Summary (Last 10 lines) ==="
echo "--- Live PHP Log ---"
docker-compose -f docker-compose.live.yml logs --tail=10 live-php-fpm 2>/dev/null | grep -E "(error|warning|notice)" || echo "No recent Live PHP messages"

echo ""
echo "--- Staging PHP Log ---"
docker-compose -f docker-compose.staging.yml logs --tail=10 staging-php-fpm 2>/dev/null | grep -E "(error|warning|notice)" || echo "No recent Staging PHP messages"

echo ""
echo "--- Live Database Log ---"
docker-compose -f docker-compose.live.yml logs --tail=10 live-db 2>/dev/null | grep -i error || echo "No recent Live database errors"

echo ""
echo "--- Staging Database Log ---"
docker-compose -f docker-compose.staging.yml logs --tail=10 staging-db 2>/dev/null | grep -i error || echo "No recent Staging database errors"

echo ""
echo "=== Health Check ==="
LIVE_SERVICES=("live-db" "live-php-fpm")
STAGING_SERVICES=("staging-db" "staging-php-fpm")

echo "Live Services:"
for service in "${LIVE_SERVICES[@]}"; do
    HEALTH_STATUS=$(docker inspect --format='{{json .State.Health}}' "live_wordpress_$service" 2>/dev/null | jq -r '.Status' 2>/dev/null)
    if [ "$HEALTH_STATUS" == "healthy" ]; then
        echo "$service: ✓ Healthy"
    elif [ "$HEALTH_STATUS" == "unhealthy" ]; then
        echo "$service: ✗ Unhealthy"
    elif [ "$HEALTH_STATUS" == "starting" ]; then
        echo "$service: ○ Starting"
    else
        echo "$service: ? Status unknown"
    fi
done

echo ""
echo "Staging Services:"
for service in "${STAGING_SERVICES[@]}"; do
    HEALTH_STATUS=$(docker inspect --format='{{json .State.Health}}' "staging_wordpress_$service" 2>/dev/null | jq -r '.Status' 2>/dev/null)
    if [ "$HEALTH_STATUS" == "healthy" ]; then
        echo "$service: ✓ Healthy"
    elif [ "$HEALTH_STATUS" == "unhealthy" ]; then
        echo "$service: ✗ Unhealthy"
    elif [ "$HEALTH_STATUS" == "starting" ]; then
        echo "$service: ○ Starting"
    else
        echo "$service: ? Status unknown"
    fi
done

echo ""
echo "=== WordPress Site Status ==="
# Note: This would require actual domain configuration to test
echo "Please check your configured domains for Live and Staging sites"
echo "Live: Check http://live.yourdomain.com"
echo "Staging: Check http://staging.yourdomain.com"

echo ""
echo "Monitoring completed!"