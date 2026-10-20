#!/bin/bash
set -e

echo "Démarrage de l'application..."

. /ini.sh

# Génération config Symfony depuis config.ini
echo "Génération de la configuration..."
/generate-env.sh

# Attente MySQL avec timeout (le healthcheck docker-compose couvre le cas normal)
DB_HOST=$(ini_get /opt/config.ini Database host mysql)
DB_PORT=$(ini_get /opt/config.ini Database port 3306)
if [ "$DB_HOST" = "127.0.0.1" ] || [ "$DB_HOST" = "localhost" ]; then
    DB_HOST="mysql"
fi
echo "Attente que MySQL soit prêt..."
timeout=60
counter=0
while ! nc -z "$DB_HOST" "$DB_PORT"; do
    echo "En attente de MySQL... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        echo "Timeout : MySQL n'est pas prêt après $timeout secondes"
        exit 1
    fi
done
echo "MySQL est prêt !"

# Exécution migrations Doctrine
echo "Exécution des migrations Doctrine..."
cd /var/www/html
php bin/console doctrine:migrations:migrate --no-interaction

# Cache Symfony reconstruit pour l'environnement courant, puis rendu à Apache (www-data)
echo "Préparation du cache Symfony..."
php bin/console cache:clear --no-interaction
chown -R www-data:www-data var

# Dossier des CSV d'import utilisé par mkmpy
TEMP_DIR=$(ini_get /opt/config.ini Folders temp /data/)
TEMP_DIR=${TEMP_DIR%/}
mkdir -p "$TEMP_DIR/csvtemp"

# Premier démarrage : import initial en arrière-plan pour peupler la base
# Tenté une seule fois, même en cas d'échec : le relancer à chaque redémarrage
# multiplie les passages sur Cardmarket et fait durcir le challenge Cloudflare
# Le marqueur est dans le volume app_data, supprimé par "docker compose down -v"
FIRST_IMPORT_MARKER="$TEMP_DIR/.first-import-attempted"
FIRST_IMPORT_LOG="$TEMP_DIR/first-import.log"
if [ ! -f "$FIRST_IMPORT_MARKER" ]; then
    touch "$FIRST_IMPORT_MARKER"
    echo "Premier démarrage : import initial lancé en arrière-plan (log : $FIRST_IMPORT_LOG)"
    (
        cd /opt/mkmpy && ./.venv/bin/python3 ./launch.py \
            && cd /opt/mkmoraclepy && ./.venv/bin/python3 ./launch_predict.py \
            || echo "Import initial en échec : relancer ./daily-task.sh depuis l'hôte"
    ) > "$FIRST_IMPORT_LOG" 2>&1 &
fi

echo "Démarrage d'Apache..."
# Démarrage Apache (processus principal en foreground)
exec apache2-foreground
