#!/bin/bash
set -e

cd /var/www/html

chmod -R 777 storage bootstrap/cache database

# Installation des dépendances si vendor est absent
if [ ! -f vendor/autoload.php ]; then
  echo "[entrypoint] Installation des dépendances Composer..."
  composer install --no-interaction --optimize-autoloader --ignore-platform-req=ext-pcntl
fi

# Construit le .env à partir des variables d'environnement Render
echo "[entrypoint] Écriture du fichier .env depuis les variables d'environnement..."
cat > .env <<EOF
APP_NAME="${APP_NAME:-Together We Can}"
APP_ENV=${APP_ENV:-production}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-https://together-we-can-back-end-pqel.onrender.com}
APP_KEY=${APP_KEY:-}
FRONTEND_URL=${FRONTEND_URL:-${APP_URL:-https://together-we-can-back-end-pqel.onrender.com}}

DB_CONNECTION=${DB_CONNECTION:-pgsql}
DB_HOST=${DB_HOST:-127.0.0.1}
DB_PORT=${DB_PORT:-5432}
DB_DATABASE=${DB_DATABASE:-laravel_t9t5}
DB_USERNAME=${DB_USERNAME:-laravel_user}
DB_PASSWORD=${DB_PASSWORD:-}

SESSION_DRIVER=${SESSION_DRIVER:-database}
CACHE_DRIVER=${CACHE_DRIVER:-database}
QUEUE_CONNECTION=${QUEUE_CONNECTION:-database}
BROADCAST_DRIVER=${BROADCAST_DRIVER:-log}

MAIL_MAILER=${MAIL_MAILER:-smtp}
MAIL_HOST=${MAIL_HOST:-smtp.gmail.com}
MAIL_PORT=${MAIL_PORT:-587}
MAIL_USERNAME=${MAIL_USERNAME:-jephbesaus07@gmail.com}
MAIL_PASSWORD=${MAIL_PASSWORD:-}
MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-tls}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-jephbesaus07@gmail.com}
MAIL_FROM_NAME="${MAIL_FROM_NAME:-Together We Can}"

CHARIOW_API_KEY=${CHARIOW_API_KEY:-}
CHARIOW_PAYMENT_URL=${CHARIOW_PAYMENT_URL:-https://epazzsvw.mychariow.store/prd_dd7c35ic}
CHARIOW_WEBHOOK_SECRET=${CHARIOW_WEBHOOK_SECRET:-0fb92ed67139b8737d11fa8c9e65c150}
CHARIOW_CURRENCY=${CHARIOW_CURRENCY:-CDF}

PAYMENT_CURRENCY=${PAYMENT_CURRENCY:-CDF}
PAYMENT_MIN_DEPOSIT=${PAYMENT_MIN_DEPOSIT:-500}
PAYMENT_MIN_WITHDRAWAL=${PAYMENT_MIN_WITHDRAWAL:-1000}

FUSIONPAY_API_URL=${FUSIONPAY_API_URL:-https://api.fusionpay.com/v1}
FUSIONPAY_API_KEY=${FUSIONPAY_API_KEY:-}
FUSIONPAY_CURRENCY=${FUSIONPAY_CURRENCY:-XOF}
FUSIONPAY_WEBHOOK_SECRET=${FUSIONPAY_WEBHOOK_SECRET:-}

FULLSMM_API_URL=${FULLSMM_API_URL:-https://panel.fullsmm.com/api/v2}
FULLSMM_API_KEY=${FULLSMM_API_KEY:-}

ADMIN_EMAIL=${ADMIN_EMAIL:-jephbesaus07@gmail.com}
ADMIN_ACTIVATION_CODE=${ADMIN_ACTIVATION_CODE:-2007224}
REFERRAL_REWARD_AMOUNT=${REFERRAL_REWARD_AMOUNT:-1000}

JWT_SECRET=${JWT_SECRET:-}

FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-}
FIREBASE_CREDENTIALS=${FIREBASE_CREDENTIALS:-storage/app/firebase/service-account.json}

APP_RELEASE_VERSION=${APP_RELEASE_VERSION:-1.0.0}
APP_RELEASE_APK=${APP_RELEASE_APK:-together-we-can.apk}
APP_RELEASE_NOTES="${APP_RELEASE_NOTES:-Première version de Together We Can.}"
APP_MIN_ANDROID_VERSION=${APP_MIN_ANDROID_VERSION:-5.0}
APP_RELEASE_EXTERNAL_URL=${APP_RELEASE_EXTERNAL_URL:-}
EOF

echo "[entrypoint] .env créé avec succès."

# Génère une APP_KEY si absente
if [ -z "${APP_KEY:-}" ] && ! grep -q '^APP_KEY=.\+' .env; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan migrate --force
php artisan storage:link || true

apache2-foreground
