#!/bin/sh
set -e
envsubst < /usr/local/etc/php-fpm.d/www.conf.template > /usr/local/etc/php-fpm.d/www.conf
exec docker-php-entrypoint "$@"