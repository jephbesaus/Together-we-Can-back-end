#!/bin/bash
set -e

cd /var/www/html

if [ ! -f .env ]; then
  cp .env.example .env
fi

if [ -z "${APP_KEY:-}" ]; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan migrate --force
php artisan storage:link || true

apache2-foreground
