# WordPress Docker Production Setup with Live & Staging

This repository contains a complete Docker-based WordPress setup that replicates your shared hosting environment (PHP 7.4.33, MariaDB 11.4.9, WordPress 6.8.3) with separate live and staging environments for VPS deployment.

## Features

- **Dual Environment Setup**: Separate live and staging WordPress installations
- **Production Ready**: Optimized for performance and security
- **Complete Monitoring**: Logging, health checks, and monitoring tools
- **Database Management**: phpMyAdmin for both environments
- **SSL Support**: Let's Encrypt integration
- **Backup & Restore**: Automated backup and restore capabilities
- **Easy Management**: Comprehensive set of management scripts

## Prerequisites

- Docker (v20+)
- Docker Compose (v1.29+)
- Linux-based VPS (Ubuntu 20.04+ recommended)
- Domain names for live and staging sites
- At least 4GB RAM and 20GB disk space

## Server Configuration

- **Server IP**: 199.19.74.239
- **Server Host**: 199-19-74-239.cloud-xip.com
- **Server ID**: fbbcb6f8-4252-472e-ad12-406242d2d889
- **Live Domain**: https://acmerevival.com/
- **Testing Access**: Using IP address until DNS is configured

## Setup Instructions

### 1. Clone and Prepare the Repository

```bash
# Clone your repository to the VPS
git clone <your-repo-url>
cd /path/to/your/wordpress/setup

# Make all scripts executable
chmod +x *.sh
```

### 2. Configure Environment Variables

Edit the `.env` file to set your specific configuration:

```bash
nano .env
```

Your configuration is already set with:
- `LIVE_SITE_URL`: acmerevival.com
- `STAGING_SITE_URL`: staging.acmerevival.com
- Strong passwords are configured
- Contact email: contact@acmerevival.com

### 3. Initial Setup

Run the main setup script to install both environments:

```bash
./setup.sh
```

This will:
- Build the PHP 7.4.33 Docker image
- Start both live and staging environments
- Install WordPress with your configuration
- Set up Redis caching
- Create initial backups

### 4. Configure DNS (For Production)

Point your domain names to your VPS IP address:
- A record for acmerevival.com → 199.19.74.239
- A record for staging.acmerevival.com → 199.19.74.239

### 5. SSL Certificate Setup

After DNS propagation, set up SSL certificates:

```bash
./setup-ssl.sh acmerevival.com staging.acmerevival.com contact@acmerevival.com
```

## Management Scripts

### Core Management
- `./setup.sh` - Initial setup of both environments
- `./restart-services.sh [live|staging|all]` - Safely restart services
- `./health-check-live.sh` - Check live environment health
- `./health-check-staging.sh` - Check staging environment health
- `./monitor.sh` - Monitor all services

### Backup & Restore
- `./backup-live.sh` - Backup live environment
- `./backup-staging.sh` - Backup staging environment
- `./restore-site.sh` - Restore from backup (update script as needed)

### Logging & Monitoring
- Centralized logging with Elasticsearch, Logstash, and Kibana
- Access Kibana at `http://199.19.74.239:5601`

## Service Access

### Web Access
- **Live Site**: `http://199.19.74.239` or `https://acmerevival.com` (after DNS)
- **Staging Site**: `http://199.19.74.239:8080` or `https://staging.acmerevival.com` (after DNS)
- **Live Admin**: `http://199.19.74.239/wp-admin` or `https://acmerevival.com/wp-admin`
- **Staging Admin**: `http://199.19.74.239:8080/wp-admin` or `https://staging.acmerevival.com/wp-admin`

### Database Access
- **Live phpMyAdmin**: `http://199.19.74.239:8081`
- **Staging phpMyAdmin**: `http://199.19.74.239:8082`

### Monitoring
- **Kibana (Logging)**: `http://199.19.74.239:5601`
- **Health Checks**: Run `./health-check-live.sh` or `./health-check-staging.sh`

## Docker Compose Files

- `docker-compose.live.yml` - Live environment services
- `docker-compose.staging.yml` - Staging environment services
- `docker-compose.logging.yml` - Logging and monitoring services

## Security Features

- Isolated networks for live and staging environments
- Separate databases preventing cross-contamination
- Security headers in nginx configuration
- Proper file permissions
- SSL support with Let's Encrypt

## Production Best Practices

1. **Regular Backups**: Run backup scripts regularly
2. **Monitor Resources**: Watch memory and disk usage
3. **Update Security**: Keep Docker images updated
4. **Domain Configuration**: Ensure proper DNS setup
5. **SSL Renewal**: Certbot auto-renewal is configured

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Ensure ports 80, 443, 8081, 8082, 5601 are available
2. **Domain Resolution**: Verify DNS records are properly set
3. **Database Connection**: Check environment variables in `.env`

### Useful Commands

```bash
# Check all running containers
docker-compose -f docker-compose.live.yml ps
docker-compose -f docker-compose.staging.yml ps

# View logs
docker-compose -f docker-compose.live.yml logs -f
docker-compose -f docker-compose.staging.yml logs -f

# Restart services safely
./restart-services.sh all

# Run health checks
./health-check-live.sh
./health-check-staging.sh
```

## Development Workflow

1. Make changes in staging environment
2. Test thoroughly
3. Deploy to live environment when ready

## Maintenance

### Regular Maintenance Tasks

1. **Daily**: Monitor service health with health check scripts
2. **Weekly**: Review logs and system resources
3. **Monthly**: Update Docker images and WordPress
4. **As needed**: Perform backups and restore tests

### Updating WordPress

1. Update in staging first
2. Test functionality
3. Deploy to live environment

## Support

For issues or questions, review the logs and health checks first. If problems persist, check Docker container status and configuration files.

---

This setup provides a production-ready WordPress environment with live and staging capabilities, complete monitoring, and easy management tools.