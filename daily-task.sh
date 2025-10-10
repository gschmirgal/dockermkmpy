#!/bin/bash

# Script pour exécuter la tâche quotidienne dans le conteneur
# Import & prediction
# Usage: ./scripts/daily-task.sh

sudo docker-compose exec -T app bash -c "cd /opt/mkmpy && ./.venv/bin/python3 ./launch.py"
sudo docker-compose exec -T app bash -c "cd /opt/mkmoraclepy && ./.venv/bin/python3 ./launch_predict.py"