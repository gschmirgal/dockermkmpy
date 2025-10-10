#!/bin/bash

# Lecture config.ini et démarrage Docker avec variables d'environnement

CONFIG_FILE="./config/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Fichier config.ini non trouvé !"
    exit 1
fi

echo "Lecture des paramètres depuis $CONFIG_FILE ..."

# Extraction paramètres DB depuis config.ini
DB_HOST=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^host' | cut -d'=' -f2 | xargs)
DB_USER=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^user' | cut -d'=' -f2 | xargs)
DB_PASS=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^password' | cut -d'=' -f2 | xargs)
DB_NAME=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^database' | cut -d'=' -f2 | xargs)
DB_PORT=$(grep -A5 '\[Database\]' "$CONFIG_FILE" | grep '^port' | cut -d'=' -f2 | xargs)

echo "Configuration détectée dans $CONFIG_FILE :"
echo "  Host: $DB_HOST"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Port: $DB_PORT"

echo ""
echo "Démarrage de Docker avec cette configuration..."

# Export variables environnement pour docker-compose
export MYSQL_ROOT_PASSWORD=rootpass
export MYSQL_DATABASE=$DB_NAME
export MYSQL_USER=$DB_USER
export MYSQL_PASSWORD=$DB_PASS

# Build et démarrage avec variables exportées
echo "Construction et démarrage..."
sudo -E docker-compose up -d --build

if [ $? -eq 0 ]; then
    echo ""
    echo "Stack Docker démarrée avec succès !"
    echo ""
    echo "Conteneurs actifs :"
    sudo docker-compose ps
    echo ""
    echo "Accès à l'application : http://localhost:8000"
    echo ""
    echo " MySQL configuré avec les paramètres de config.ini :"
    echo "  - Database: $DB_NAME"
    echo "  - User: $DB_USER"
    echo "  - Port: 3307 (mappé depuis 3306)"
else
    echo "Erreur lors du démarrage"
    exit 1
fi