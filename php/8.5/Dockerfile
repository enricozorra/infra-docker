# syntax=docker/dockerfile:1

# ── STAGE 1: base ─────────────────────────────────────────
FROM php:8.5-fpm AS base

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

RUN apt-get update && apt-get install -y \
    zlib1g-dev libpq-dev \
    libxslt-dev libpng-dev libicu-dev git \
    zip libzip-dev gettext-base curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) \
    exif pgsql pdo pdo_pgsql xsl gd zip intl

COPY <<EOF /usr/local/etc/php-fpm.d/www.conf.template
[www]
user = www-data
group = www-data
listen = 9000

pm = dynamic
pm.max_children      = \${PHP_FPM_PM_MAX_CHILDREN}
pm.start_servers     = \${PHP_FPM_PM_START_SERVERS}
pm.min_spare_servers = \${PHP_FPM_PM_MIN_SPARE_SERVERS}
pm.max_spare_servers = \${PHP_FPM_PM_MAX_SPARE_SERVERS}
pm.max_requests      = \${PHP_FPM_PM_MAX_REQUESTS}
EOF

COPY <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/sh
set -e
envsubst < /usr/local/etc/php-fpm.d/www.conf.template > /usr/local/etc/php-fpm.d/www.conf
exec docker-php-entrypoint "\$@"
EOF
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]

# ── STAGE 2: development ──────────────────────────────────
FROM base AS dev

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

COPY <<EOF /usr/local/etc/php/conf.d/app.ini
display_errors = On
error_reporting = E_ALL
opcache.enable = 0
EOF

COPY <<EOF /usr/local/etc/php/conf.d/xdebug.ini
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
EOF

ENV PHP_FPM_PM_MAX_CHILDREN=5 \
    PHP_FPM_PM_START_SERVERS=2 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_REQUESTS=0

# ── STAGE 3: production ───────────────────────────────────
FROM base AS prod

COPY <<EOF /usr/local/etc/php/conf.d/app.ini
display_errors = Off
opcache.enable = 1
opcache.memory_consumption = 256
opcache.validate_timestamps = 0
EOF

ENV PHP_FPM_PM_MAX_CHILDREN=20 \
    PHP_FPM_PM_START_SERVERS=5 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=10 \
    PHP_FPM_PM_MAX_REQUESTS=500
