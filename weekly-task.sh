#!/bin/bash

# Script pour exécuter la tâche hebdomadaire dans le conteneur
# apprentissage
# Usage: ./weekly-task.sh (utilisable depuis cron, quel que soit le dossier courant)

cd "$(dirname "$0")" || exit 1

sudo docker compose exec -T app bash -c "cd /opt/mkmoraclepy && ./.venv/bin/python3 ./launch_learn.py"
