#!/bin/bash

# Lecture config.ini et démarrage Docker avec variables d'environnement

cd "$(dirname "$0")" || exit 1

CONFIG_FILE="./config/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Fichier config.ini non trouvé !"
    exit 1
fi

. ./scripts/ini.sh

echo "Lecture des paramètres depuis $CONFIG_FILE ..."

# Extraction paramètres DB depuis config.ini
DB_HOST=$(ini_get "$CONFIG_FILE" Database host)
DB_USER=$(ini_get "$CONFIG_FILE" Database user)
DB_PASS=$(ini_get "$CONFIG_FILE" Database password)
DB_NAME=$(ini_get "$CONFIG_FILE" Database database)
DB_PORT=$(ini_get "$CONFIG_FILE" Database port)
DB_ROOT_PASS=$(ini_get "$CONFIG_FILE" Database root_password rootpass)

echo "Configuration détectée dans $CONFIG_FILE :"
echo "  Host: $DB_HOST"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Port: $DB_PORT"

echo ""
echo "Démarrage de Docker avec cette configuration..."

# Fichier .env lu automatiquement par docker compose (y compris pour exec/logs/ps)
cat > .env << EOF
MYSQL_ROOT_PASSWORD=$DB_ROOT_PASS
MYSQL_DATABASE=$DB_NAME
MYSQL_USER=$DB_USER
MYSQL_PASSWORD=$DB_PASS
EOF
chmod 600 .env

# Build et démarrage
# --wait : rend la main une fois les conteneurs démarrés et MySQL sain
echo "Construction et démarrage..."
sudo docker compose up -d --build --wait

if [ $? -eq 0 ]; then
    echo ""
    echo "Stack Docker démarrée avec succès !"
    echo ""
    echo "Conteneurs actifs :"
    sudo docker compose ps
    echo ""
    echo "Accès à l'application : http://localhost:8000"
    echo ""
    echo " MySQL configuré avec les paramètres de config.ini :"
    echo "  - Database: $DB_NAME"
    echo "  - User: $DB_USER"
    echo "  - Port: 127.0.0.1:3307 (mappé depuis 3306)"
else
    echo "Erreur lors du démarrage"
    exit 1
fi
