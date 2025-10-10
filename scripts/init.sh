#!/bin/bash
set -e

# Clonage des repos GitHub
git clone https://github.com/gschmirgal/frontMkmPy.git /var/www/symfony
git clone https://github.com/gschmirgal/mkmpy.git /opt/mkmpy
git clone https://github.com/gschmirgal/MKMOraclePy.git /opt/mkmoraclepy

# Installation Symfony + migrations
cd /var/www/symfony
composer install
php bin/console doctrine:migrations:migrate --no-interaction

# Installation environnements Python
cd /opt/mkmpy
python -m venv .venv
source .venv/bin/activate
pip install --no-cache-dir -r requirements.txt
deactivate

cd /opt/mkmoraclepy
python -m venv .venv
source .venv/bin/activate
pip install --no-cache-dir -r requirements.txt
deactivate

