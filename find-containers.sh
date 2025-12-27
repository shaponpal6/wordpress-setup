#!/bin/bash

echo "=== Listing ALL Containers ==="
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

echo ""
echo "=== Checking Docker Compose Config interpretation ==="
docker-compose -f docker-compose.live.yml config

echo ""
echo "=== Trying to find live-db container by label ==="
docker ps -a --filter "label=com.docker.compose.service=live-db"
