# syntax=docker/dockerfile:1

# ── STAGE 1: base ─────────────────────────────────────────
FROM php:8.2-fpm-alpine3.24 AS base

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# pdo_pgsql is a core extension → docker-php-ext-install (PIE handles only
# third-party extensions). Keep libpq at runtime, libpq-dev only to build.
RUN apk add --no-cache \
        libpq \
    && apk add --no-cache --virtual .build-deps \
        libpq-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
    && apk del .build-deps

RUN apk add --no-cache \
        envsubst

COPY www.conf.template /usr/local/etc/php-fpm.d/www.conf.template
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]

# ── STAGE 2: development ──────────────────────────────────
FROM base AS dev

# install node and npm
RUN apk add --no-cache \
        nodejs \
        npm

# install xdebug with PIE
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        linux-headers \
        git \
    && wget -qO /usr/local/bin/pie https://github.com/php/pie/releases/latest/download/pie.phar \
    && chmod +x /usr/local/bin/pie \
    && pie install xdebug/xdebug \
    && apk del .build-deps

COPY app.dev.ini /usr/local/etc/php/conf.d/app.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# env default values
ENV PHP_FPM_PM_MAX_CHILDREN=5 \
    PHP_FPM_PM_START_SERVERS=2 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_REQUESTS=0

# ── STAGE 3: production ───────────────────────────────────
FROM base AS prod

COPY app.prod.ini /usr/local/etc/php/conf.d/app.ini

ENV PHP_FPM_PM_MAX_CHILDREN=20 \
    PHP_FPM_PM_START_SERVERS=5 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=10 \
    PHP_FPM_PM_MAX_REQUESTS=500
