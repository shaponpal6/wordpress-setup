#!/bin/bash

echo "=== Debugging Live Environment Creation ==="

echo "1. Ensuring clean slate for Live env..."
docker-compose -f docker-compose.live.yml down --remove-orphans

echo ""
echo "2. Checking Network..."
docker network ls | grep live
docker network inspect live_wordpress_network > /dev/null 2>&1 || docker network create live_wordpress_network

echo ""
echo "3. Starting Live DB (Verbose)..."
docker-compose --verbose -f docker-compose.live.yml up -d live-db

echo ""
echo "4. Checking result..."
docker ps -a | grep live_wordpress_db
docker logs live_wordpress_db 2>&1 | head -20
