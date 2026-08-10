#!/bin/bash
set -e

cd /var/www/html

chmod -R 777 storage bootstrap/cache database

# Installation des dépendances si vendor est absent (dossier monté depuis l'hôte)
if [ ! -f vendor/autoload.php ]; then
  echo "[entrypoint] Installation des dépendances Composer..."
  composer install --no-interaction --optimize-autoloader --ignore-platform-req=ext-pcntl
fi

if [ ! -f .env ]; then
  touch .env
fi

# Génère une APP_KEY si absente
if [ -z "${APP_KEY:-}" ] && ! grep -q '^APP_KEY=.\+' .env; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan migrate --force
php artisan storage:link || true

apache2-foreground
