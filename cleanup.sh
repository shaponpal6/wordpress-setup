#!/bin/bash

echo "=== Cleaning up old networks ==="
docker network rm live_network 2>/dev/null || echo "live_network doesn't exist"
docker network rm staging_network 2>/dev/null || echo "staging_network doesn't exist"

echo ""
echo "=== Stopping all containers ==="
docker-compose -f docker-compose.live.yml down
docker-compose -f docker-compose.staging.yml down
docker-compose -f docker-compose.proxy.yml down

echo ""
echo "=== Pruning system ==="
docker system prune -f

echo ""
echo "=== Ready for fresh setup ==="
echo "Run: ./setup.sh"
