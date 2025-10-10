#!/bin/bash

# Génère .env.local Symfony depuis config.ini
CONFIG_FILE="/opt/config.ini"
ENV_FILE="/var/www/html/.env.local"

if [ -f "$CONFIG_FILE" ]; then
    echo "Génération de la configuration depuis config.ini..."
    
    # Extraction paramètres DB depuis config.ini
    DB_HOST=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^host' | cut -d'=' -f2 | xargs)
    DB_USER=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^user' | cut -d'=' -f2 | xargs)
    DB_PASS=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^password' | cut -d'=' -f2 | xargs)
    DB_NAME=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^database' | cut -d'=' -f2 | xargs)
    DB_PORT=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^port' | cut -d'=' -f2 | xargs)
    
    # Adaptation réseau Docker : localhost -> mysql
    if [ "$DB_HOST" = "127.0.0.1" ]; then
        DB_HOST="mysql"
    fi
    
    # Génération .env.local avec LOCAL_INFILE activé
    cat > "$ENV_FILE" << EOF
# Config auto-générée depuis config.ini
DATABASE_URL=mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?serverVersion=8.0&charset=utf8mb4&LOCAL_INFILE=1
MESSENGER_TRANSPORT_DSN=doctrine://default
EOF
    
    echo "Configuration générée dans $ENV_FILE"
    echo "DATABASE_URL=mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
else
    echo "Config.ini manquant, config par défaut utilisée"
fi