#!/bin/bash
set -e

cd /var/www/html

chmod -R 777 storage bootstrap/cache database

# Crée les sous-dossiers de stockage pour les uploads
mkdir -p storage/app/public/profiles storage/app/public/posts
chmod -R 777 storage/app/public

# Installation des dépendances si vendor est absent
if [ ! -f vendor/autoload.php ]; then
  echo "[entrypoint] Installation des dépendances Composer..."
  composer install --no-interaction --optimize-autoloader --ignore-platform-req=ext-pcntl
fi

# Construit le .env à partir des variables d'environnement Render
echo "[entrypoint] Écriture du fichier .env depuis les variables d'environnement..."
cat > .env <<EOF
APP_NAME="${APP_NAME}"
APP_ENV="${APP_ENV}"
APP_DEBUG="${APP_DEBUG}"
APP_URL="${APP_URL}"
APP_KEY="${APP_KEY}"
FRONTEND_URL="${FRONTEND_URL}"

DB_CONNECTION="${DB_CONNECTION}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_DATABASE="${DB_DATABASE}"
DB_USERNAME="${DB_USERNAME}"
DB_PASSWORD="${DB_PASSWORD}"

SESSION_DRIVER="${SESSION_DRIVER}"
CACHE_DRIVER="${CACHE_DRIVER}"
QUEUE_CONNECTION="${QUEUE_CONNECTION}"
BROADCAST_DRIVER="${BROADCAST_DRIVER}"

MAIL_MAILER="${MAIL_MAILER}"
MAIL_HOST="${MAIL_HOST}"
MAIL_PORT="${MAIL_PORT}"
MAIL_USERNAME="${MAIL_USERNAME}"
MAIL_PASSWORD="${MAIL_PASSWORD}"
MAIL_ENCRYPTION="${MAIL_ENCRYPTION}"
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS}"
MAIL_FROM_NAME="${MAIL_FROM_NAME}"

CHARIOW_API_KEY="${CHARIOW_API_KEY}"
CHARIOW_STORE_URL="${CHARIOW_STORE_URL}"
CHARIOW_DEPOSIT_PRODUCT_ID="${CHARIOW_DEPOSIT_PRODUCT_ID}"
CHARIOW_BOOST_PRODUCT_ID="${CHARIOW_BOOST_PRODUCT_ID}"
CHARIOW_PULSE_SECRET="${CHARIOW_PULSE_SECRET}"

PAYMENT_CURRENCY="${PAYMENT_CURRENCY}"
PAYMENT_MIN_DEPOSIT="${PAYMENT_MIN_DEPOSIT}"
PAYMENT_MIN_WITHDRAWAL="${PAYMENT_MIN_WITHDRAWAL}"

FUSIONPAY_API_URL="${FUSIONPAY_API_URL}"
FUSIONPAY_API_KEY="${FUSIONPAY_API_KEY}"
FUSIONPAY_CURRENCY="${FUSIONPAY_CURRENCY}"
FUSIONPAY_WEBHOOK_SECRET="${FUSIONPAY_WEBHOOK_SECRET}"

FULLSMM_API_URL="${FULLSMM_API_URL}"
FULLSMM_API_KEY="${FULLSMM_API_KEY}"

ADMIN_EMAIL="${ADMIN_EMAIL}"
ADMIN_ACTIVATION_CODE="${ADMIN_ACTIVATION_CODE}"
REFERRAL_REWARD_AMOUNT="${REFERRAL_REWARD_AMOUNT}"

JWT_SECRET="${JWT_SECRET}"

FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}"

APP_RELEASE_VERSION="${APP_RELEASE_VERSION}"
APP_RELEASE_APK="${APP_RELEASE_APK}"
APP_RELEASE_NOTES="${APP_RELEASE_NOTES}"
APP_MIN_ANDROID_VERSION="${APP_MIN_ANDROID_VERSION}"
APP_RELEASE_EXTERNAL_URL="${APP_RELEASE_EXTERNAL_URL}"
EOF

echo "[entrypoint] .env créé avec succès."

# Écrit les credentials Firebase dans un fichier (le JSON ne rentre pas dans .env)
mkdir -p storage/app/firebase
if [ -n "${FIREBASE_CREDENTIALS:-}" ]; then
  echo "${FIREBASE_CREDENTIALS}" > storage/app/firebase/service-account.json
  chmod 644 storage/app/firebase/service-account.json
  echo "[entrypoint] Firebase credentials écrit dans storage/app/firebase/service-account.json"
fi

# Génère une APP_KEY si absente
if [ -z "${APP_KEY:-}" ] && ! grep -q '^APP_KEY=.\+' .env; then
  php artisan key:generate --force
fi

php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan migrate --force
php artisan courses:seed-demo || true

# Supprime l'ancien symlink cassé et le recrée proprement
rm -f public/storage
php artisan storage:link
chmod -R 777 storage/app/public

# Démarre le worker de queue en arrière-plan (emails OTP, notifications...)
if [ "${QUEUE_CONNECTION:-}" = "database" ] || [ "${QUEUE_CONNECTION:-}" = "redis" ]; then
  echo "[entrypoint] Démarrage du worker de queue..."
  php artisan queue:work --tries=3 --timeout=60 --max-time=3600 >> storage/logs/queue-worker.log 2>&1 &
fi

apache2-foreground
