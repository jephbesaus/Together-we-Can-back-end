#!/bin/bash
set -e

cd /var/www/html

if [ ! -f .env ]; then
  touch .env
fi

if [ -z "${APP_KEY:-}" ] && ! grep -q '^APP_KEY=.\+' .env; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan migrate --force
php artisan storage:link || true

apache2-foreground
