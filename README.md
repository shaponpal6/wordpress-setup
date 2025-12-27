# Production WordPress Docker Setup

This repository contains a complete production-ready WordPress setup with both live and staging environments using Docker Compose.

## Features

- **WordPress 6.8.3** with **PHP 7.4.33**
- **MariaDB 11.4.9** database
- **phpMyAdmin** for database management
- **Redis** for caching
- **Nginx** as reverse proxy
- **Separate live and staging environments**
- **Persistent storage** outside project directory
- **Health checks** for all services
- **Security optimizations**

## Prerequisites

- Docker and Docker Compose
- At least 4GB RAM allocated to Docker
- Linux/macOS system

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd wordpress-setup
   ```

2. **Install Docker** (if not already installed):
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)

3. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

4. **Create external directories:**
   ```bash
   ./setup-external-dirs.sh
   ```

5. **Start the setup:**
   ```bash
   ./setup.sh
   ```

## Directory Structure

All persistent data is stored outside the project directory:

- `/etc/wordpress/` - Configuration files
- `/var/www/wordpress-live/` - Live WordPress files
- `/var/www/wordpress-staging/` - Staging WordPress files
- `/var/log/wordpress/` - Log files

## Services

### Live Environment
- **WordPress**: http://199.19.74.239
- **phpMyAdmin**: http://127.0.0.1:8081
- **Database**: MariaDB 11.4.9

### Staging Environment
- **WordPress**: http://199.19.74.239:8080 (or separate domain)
- **phpMyAdmin**: http://127.0.0.1:8082
- **Database**: MariaDB 11.4.9

## Configuration

Edit the `.env` file to customize:
- Database credentials
- WordPress admin credentials
- Site titles and URLs
- PHP and MySQL settings

## Management Commands

```bash
# Check live environment health
./health-check-live.sh

# Check staging environment health
./health-check-staging.sh

# Restart services
./restart-services.sh [live|staging|all]

# Monitor services
./monitor.sh

# Create backups
./backup-live.sh
./backup-staging.sh

# Setup SSL (after DNS configuration)
./setup-ssl.sh domain email
```

## Security Features

- All containers run with security options
- phpMyAdmin accessible only from localhost
- Proper file permissions
- MariaDB security configurations
- Network isolation between environments

## Production Considerations

1. **DNS Configuration**: Point your domains to the server IP
2. **SSL Setup**: Use `./setup-ssl.sh` after DNS is configured
3. **Firewall**: Allow ports 80, 443, and restrict others
4. **Backups**: Regular backup strategy using provided scripts
5. **Monitoring**: Use the health check scripts to monitor services

## Troubleshooting

- Check container status: `docker-compose -f docker-compose.live.yml ps`
- View logs: `docker-compose -f docker-compose.live.yml logs [service]`
- Diagnose database: `./diagnose-db.sh`
- Check for errors: `./check-db-error.sh`

## Stopping Services

```bash
# Stop live environment
docker-compose -f docker-compose.live.yml down

# Stop staging environment
docker-compose -f docker-compose.staging.yml down

# Stop all environments
docker-compose -f docker-compose.live.yml down && docker-compose -f docker-compose.staging.yml down
```

## Data Persistence

All data is stored in external directories and will persist even if you delete this project folder. This ensures no data loss during updates or maintenance.

## Support

For issues or questions, please check the troubleshooting commands above or create an issue in the repository.