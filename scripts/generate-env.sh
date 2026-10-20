#!/bin/bash

# Génère .env.local Symfony depuis config.ini
CONFIG_FILE="/opt/config.ini"
ENV_FILE="/var/www/html/.env.local"

. /ini.sh

if [ -f "$CONFIG_FILE" ]; then
    echo "Génération de la configuration depuis config.ini..."

    # Extraction paramètres DB depuis config.ini
    DB_HOST=$(ini_get "$CONFIG_FILE" Database host mysql)
    DB_USER=$(ini_get "$CONFIG_FILE" Database user)
    DB_PASS=$(ini_get "$CONFIG_FILE" Database password)
    DB_NAME=$(ini_get "$CONFIG_FILE" Database database)
    DB_PORT=$(ini_get "$CONFIG_FILE" Database port 3306)

    # Adaptation réseau Docker : localhost -> mysql
    if [ "$DB_HOST" = "127.0.0.1" ] || [ "$DB_HOST" = "localhost" ]; then
        DB_HOST="mysql"
    fi

    # Environnement Symfony : prod par défaut, dev pour déboguer
    APP_ENV=$(ini_get "$CONFIG_FILE" App env prod)
    if [ "$APP_ENV" = "dev" ]; then APP_DEBUG=1; else APP_ENV=prod; APP_DEBUG=0; fi

    # APP_SECRET propre à l'installation, généré une fois et conservé dans le volume /data
    SECRET_FILE="/data/.app_secret"
    if [ ! -s "$SECRET_FILE" ]; then
        php -r 'echo bin2hex(random_bytes(32));' > "$SECRET_FILE"
        chmod 600 "$SECRET_FILE"
    fi
    APP_SECRET=$(cat "$SECRET_FILE")

    # Génération .env.local avec LOCAL_INFILE activé
    cat > "$ENV_FILE" << EOF
# Config auto-générée depuis config.ini
APP_ENV=${APP_ENV}
APP_DEBUG=${APP_DEBUG}
APP_SECRET=${APP_SECRET}
DATABASE_URL=mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?serverVersion=8.0&charset=utf8mb4&LOCAL_INFILE=1
MESSENGER_TRANSPORT_DSN=doctrine://default
EOF

    echo "Configuration générée dans $ENV_FILE (APP_ENV=$APP_ENV)"
    echo "DATABASE_URL=mysql://${DB_USER}:****@${DB_HOST}:${DB_PORT}/${DB_NAME}"
else
    echo "Config.ini manquant, config par défaut utilisée"
fi
