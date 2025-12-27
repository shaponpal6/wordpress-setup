#!/bin/bash

echo "Stopping manually started containers..."
docker-compose -f docker-compose.live.yml down
docker-compose -f docker-compose.staging.yml down
docker-compose -f docker-compose.proxy.yml down

echo ""
echo "Cleaning up..."
docker system prune -f

echo ""
echo "Ready to run ./setup.sh"
