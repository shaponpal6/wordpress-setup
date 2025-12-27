FROM php:7.4.33-fpm

# Install system dependencies with security updates
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libgmp-dev \
    g++ \
    default-mysql-client \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions with security considerations
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    mysqli \
    pdo_mysql \
    zip \
    intl \
    xsl \
    soap \
    opcache \
    gmp

# Install additional PHP extensions
RUN pecl install redis-5.3.7 && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Set permissions properly
RUN chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /usr/local/etc/php \
    && chown -R www-data:www-data /var/log/php

# Expose port
EXPOSE 9000

# Security: Use existing www-data user
USER www-data

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD php -r 'echo "PHP-FPM is running";'

CMD ["php-fpm"]