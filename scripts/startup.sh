#!/bin/bash
set -e

echo "Démarrage de l'application..."

# Génération config Symfony depuis config.ini
echo "Génération de la configuration..."
/generate-env.sh

# Attente MySQL avec timeout
echo "Attente que MySQL soit prêt..."
timeout=60
counter=0
while ! nc -z mysql 3306; do
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

# Chargement données via script Python
echo "Chargement des données avec le script Python..."
mkdir -p /tmp/csvtemp

echo "Démarrage d'Apache..."
# Démarrage Apache (processus principal en foreground)
apache2-foreground