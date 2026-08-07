#!/bin/bash
set -e

cd /var/www/html

chmod -R 777 storage bootstrap/cache
if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
  chmod 777 database
  touch "${DB_DATABASE:-/tmp/twc.sqlite}"
  chmod 666 "${DB_DATABASE:-/tmp/twc.sqlite}"
fi

if [ ! -f .env ]; then
  touch .env
fi

if [ -z "${APP_KEY:-}" ] && ! grep -q '^APP_KEY=.\+' .env; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan migrate --force
if [ "${DB_CONNECTION:-}" = "sqlite" ] && [ -f "${DB_DATABASE:-database/database.sqlite}" ]; then
  chmod 777 "$(dirname "${DB_DATABASE:-database/database.sqlite}")"
  chmod 666 "${DB_DATABASE:-database/database.sqlite}"
fi
php artisan storage:link || true

apache2-foreground
