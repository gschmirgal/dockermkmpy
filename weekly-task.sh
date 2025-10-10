#!/bin/bash

# Script pour exécuter la tâche hebdomadaire dans le conteneur
# apprentissage
# Usage: ./scripts/weekly-task.sh

sudo docker-compose exec -T app bash -c "cd /opt/mkmoraclepy && ./.venv/bin/python3 ./launch_learn.py"