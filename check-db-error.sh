#!/bin/bash

echo "=== Checking MariaDB Error Log ==="
cat /var/log/wordpress/mysql/error.log

echo ""
echo "=== Attempting to start Live DB manually ==="
docker-compose -f docker-compose.live.yml up live-db

echo ""
echo "=== If container exits, check status ==="
docker ps -a | grep live_wordpress_db
