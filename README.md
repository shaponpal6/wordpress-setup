# Acme Revival WordPress Production Setup

Complete production-ready WordPress setup with **completely separated** live and staging environments for Acme Revival project.

## Features

- **Complete Environment Separation**: Live and staging environments are completely isolated
- **External Data Storage**: All data stored outside project folder for persistence
- **Production Ready**: Optimized for security and performance
- **Complete Monitoring**: Logging, health checks, and monitoring tools
- **Database Management**: Separate phpMyAdmin for each environment
- **SSL Support**: Let's Encrypt integration
- **Backup & Restore**: Automated backup and restore capabilities

## Complete Environment Separation

### Live Environment
- **Database**: Named volume `live_wordpress_db_data`
- **Files**: `/var/www/wordpress-live/`
- **Config**: `/etc/wordpress/live/config/`
- **Logs**: `/var/log/wordpress/live/`
- **Network**: `live_wordpress_network`
- **Domain**: acmerevival.com

### Staging Environment
- **Database**: Named volume `staging_wordpress_db_data`
- **Files**: `/var/www/wordpress-staging/`
- **Config**: `/etc/wordpress/staging/config/`
- **Logs**: `/var/log/wordpress/staging/`
- **Network**: `staging_wordpress_network`
- **Domain**: staging.acmerevival.com

## Server Configuration

- **Server IP**: 199.19.74.239
- **Server Host**: 199-19-74-239.cloud-xip.com
- **Server ID**: fbbcb6f8-4252-472e-ad12-406242d2d889
- **Live Domain**: https://acmerevival.com/
- **Staging Domain**: https://staging.acmerevival.com/

## Setup Instructions

### 1. Clone and Prepare the Repository

```bash
# Clone your repository to the VPS
git clone https://github.com/shaponpal6/wordpress-setup.git
cd ./wordpress-setup
```

# Make all scripts executable
```bash
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
- Create external directories for both environments
- Build the PHP 7.4.33 Docker image
- Start both live and staging environments (completely separated)
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

## Service Access

### Web Access
- **Live Site**: `http://199.19.74.239` or `https://acmerevival.com` (after DNS)
- **Staging Site**: `http://199.19.74.239:8080` or `https://staging.acmerevival.com` (after DNS)
- **Live Admin**: `http://199.19.74.239/wp-admin` or `https://acmerevival.com/wp-admin`
- **Staging Admin**: `http://199.19.74.239:8080/wp-admin` or `https://staging.acmerevival.com/wp-admin`

### Database Access
- **Live phpMyAdmin**: `http://199.19.74.239:8081` (localhost only)
- **Staging phpMyAdmin**: `http://199.19.74.239:8082` (localhost only)

### Monitoring
- **Health Checks**: Run `./health-check-live.sh` or `./health-check-staging.sh`

## Data Persistence

All data is stored in external directories and will persist even after project folder deletion:

- **WordPress Files**: `/var/www/wordpress-live/` and `/var/www/wordpress-staging/`
- **Configuration**: `/etc/wordpress/live/config/` and `/etc/wordpress/staging/config/`
- **Logs**: `/var/log/wordpress/live/` and `/var/log/wordpress/staging/`
- **Databases**: Named Docker volumes (persist independently)

## Security Features

- **Complete Isolation**: Separate databases, files, and configurations
- **Network Isolation**: Separate Docker networks for each environment
- **Security Headers**: Enhanced security headers in nginx configuration
- **Secure phpMyAdmin**: Access restricted to localhost only
- **SSL Support**: Let's Encrypt integration with automatic renewal

## Production Best Practices

1. **Regular Backups**: Run backup scripts regularly for both environments
2. **Monitor Resources**: Watch memory and disk usage for both environments
3. **Update Security**: Keep Docker images updated
4. **Domain Configuration**: Ensure proper DNS setup
5. **SSL Renewal**: Certbot auto-renewal is configured

## Development Workflow

1. Make changes in staging environment
2. Test thoroughly in completely isolated staging
3. Deploy to live environment when ready

## Support

For issues or questions, review the logs and health checks first. If problems persist, check Docker container status and configuration files.

---

This setup provides a production-ready WordPress environment with completely separated live and staging capabilities, ensuring full isolation and data persistence.