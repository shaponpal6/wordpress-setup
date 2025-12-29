#!/bin/bash

echo "=== Checking Docker Networks ==="
docker network ls | grep -E "(live|staging)"

echo ""
echo "=== Checking if networks exist ==="
docker network inspect live_network 2>&1 | head -20
echo ""
docker network inspect staging_network 2>&1 | head -20

echo ""
echo "=== Trying to start Live DB with verbose output ==="
docker-compose -f docker-compose.live.yml up -d live-db 2>&1

echo ""
echo "=== Checking container status ==="
docker ps -a | grep live

echo ""
echo "=== Checking compose file syntax ==="
docker-compose -f docker-compose.live.yml config 2>&1 | head -50
