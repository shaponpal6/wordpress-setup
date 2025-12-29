#!/bin/bash

# Database Diagnostic Script
echo "=== Live Database Container Diagnostic ==="
echo ""

echo "1. Checking if container exists..."
docker ps -a | grep live_wordpress_db

echo ""
echo "2. Container status:"
docker inspect live_wordpress_db --format='{{.State.Status}}' 2>/dev/null || echo "Container does not exist"

echo ""
echo "3. Container logs (last 50 lines):"
docker logs --tail 50 live_wordpress_db 2>&1 || echo "Cannot retrieve logs"

echo ""
echo "4. Checking mounted volumes:"
docker inspect live_wordpress_db --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null || echo "Cannot inspect mounts"

echo ""
echo "5. Checking permissions on config directory:"
ls -la /etc/wordpress/live/config/mariadb/ 2>/dev/null || echo "Directory does not exist"

echo ""
echo "6. Checking permissions on log directory:"
ls -la /var/log/wordpress/mysql/ 2>/dev/null || echo "Directory does not exist"

echo ""
echo "7. Checking MariaDB config file:"
cat /etc/wordpress/live/config/mariadb/custom.cnf 2>/dev/null || echo "Config file does not exist"

echo ""
echo "=== Diagnostic complete ==="
