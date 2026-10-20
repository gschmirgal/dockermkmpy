#!/bin/bash

# Script pour exécuter la tâche quotidienne dans le conteneur
# Import & prediction
# Usage: ./daily-task.sh (utilisable depuis cron, quel que soit le dossier courant)

cd "$(dirname "$0")" || exit 1

sudo docker compose exec -T app bash -c "cd /opt/mkmpy && ./.venv/bin/python3 ./launch.py" || exit 1
sudo docker compose exec -T app bash -c "cd /opt/mkmoraclepy && ./.venv/bin/python3 ./launch_predict.py"
