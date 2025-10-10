# Docker MKM Python Stack

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Symfony](https://img.shields.io/badge/Symfony-7.3-000000?style=for-the-badge&logo=symfony&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-2.4-D22128?style=for-the-badge&logo=apache&logoColor=white)
![Selenium](https://img.shields.io/badge/Selenium-43B02A?style=for-the-badge&logo=selenium&logoColor=white)
![Chromium](https://img.shields.io/badge/Chromium-4285F4?style=for-the-badge&logo=googlechrome&logoColor=white)

Stack Docker complète avec **Symfony 7.3**, **MySQL 8.0** et **Python 3.13** pour applications de data science et web.

## 📋 Vue d'ensemble

Ce projet containerise une application complète comprenant :
- **Frontend/API** : Symfony 7.3 avec Apache 2.4
- **Base de données** : MySQL 8.0 avec LOCAL_INFILE activé
- **Scripts Python** : Environnements virtuels pour data science (pandas, scikit-learn)
- **Selenium** : Chromium configuré pour automatisation web
- **Configuration centralisée** : Via `config.ini`

## 🚀 Démarrage rapide

### Prérequis
- Docker et Docker Compose installés
- Ports 8000 et 3307 disponibles
- 4GB RAM minimum recommandés

### Installation

```bash
# Cloner le projet
git clone <votre-repo>
cd dockermkmpy

# Configurer la base de données
cp config/config.ini.example config/config.ini
# Éditer config/config.ini selon vos besoins

# Démarrer la stack complète
./docker-start.sh
#premier chargement des données
./daily-task.sh
```

### Accès aux services

- **Application web** : http://localhost:8000
- **MySQL** : localhost:3307 (root/rootpass)
- **Base de données** : mkmpy_db (utilisateur: test_user)

## 📁 Structure du projet

```
dockermkmpy/
├── config/
│   ├── config.ini          # Configuration centralisée, à modifier si besoin
│   ├── apache-vhost.conf    # Configuration Apache
│   └── .htaccess           # Règles de réécriture Symfony
├── scripts/
│   ├── docker-start.sh     # Script de démarrage principal
│   ├── startup.sh          # Script d'initialisation conteneur
│   ├── generate-env.sh     # Génération .env.local Symfony
│   └── init.sh             # Script d'installation initial
├── docker-compose.yml      # Orchestration services
├── Dockerfile             # Image application personnalisée
└── README.md
```

## ⚙️ Configuration

### config.ini

Fichier de configuration principal pour tous les services :

```ini
[Database]
host     = mysql
user     = test_user
password = simplepass
database = mkmpy_db
port     = 3306

[Folders]
temp = /tmp/

[IA]
n_estimators = 200
max_depth = 15
# ... autres paramètres IA
```

⚠️ **Important** : Évitez les caractères spéciaux (`$`, `!`, `@`, `%`) dans les mots de passe MySQL car ils peuvent causer des problèmes d'échappement dans l'URL de connexion Doctrine.

### Variables d'environnement

Le script `generate-env.sh` génère automatiquement `.env.local` pour Symfony depuis `config.ini` :
- `DATABASE_URL` avec LOCAL_INFILE activé
- `MESSENGER_TRANSPORT_DSN` configuré

## Architecture technique

### Conteneurs

1. **mysql** (mysql:8.0)
   - Authentication native password
   - LOCAL_INFILE=1 pour imports CSV
   - Volume persistant `mysql_data`

2. **app** (build custom)
   - PHP 8.4 + Apache 2.4
   - Symfony 7.3 avec toutes dépendances
   - Python 3.13 + environnements virtuels
   - Chromium + ChromeDriver pour Selenium

### Optimisations build-time

- **Installation Composer** : Au build, pas au runtime
- **Compilation mysqlclient** : Pré-compilé dans l'image
- **Environnements Python** : Créés et configurés au build
- **Configuration Apache** : Intégrée dans l'image

### Système d'attente intelligent

- **Timeout configuré** : 60 secondes maximum
- **Détection réseau** : Via netcat sur port MySQL
- **Gestion d'erreur** : Continuation même si script Python échoue

## Projets intégrés

Le système clone et configure automatiquement :

1. **frontMkmPy** : Application Symfony principale
2. **mkmpy** : Scripts Python de data science
3. **MKMOraclePy** : Scripts Python pour base Oracle

## Commandes utiles

### Gestion des conteneurs

```bash
# Démarrage complet (build + start)
./docker-start.sh

#chargement des données cardmarket (à lancer tous les jours pour etre à jour)
#les données prévisonelles apparaitront apres plusieurs jours
./daily-task.sh 

#lancement apprentissage (a lancer regulierement ex:hebdo)
./weekly-task.sh 

# Redémarrer seulement l'application
sudo docker-compose restart app

# Voir les logs en temps réel
sudo docker-compose logs -f app

# Accéder au conteneur
sudo docker-compose exec app bash

# Arrêter tout
sudo docker-compose down

# Nettoyage complet (avec volumes)
sudo docker-compose down -v
```

### Base de données

```bash
# Connexion MySQL depuis l'hôte
mysql -h 127.0.0.1 -P 3307 -u test_user -psimplepass mkmpy_db

# Connexion root
mysql -h 127.0.0.1 -P 3307 -u root -prootpass

# Migrations Symfony
sudo docker-compose exec app php bin/console doctrine:migrations:migrate

# Vérifier les utilisateurs MySQL
sudo docker exec -it dockermkmpy_mysql_1 mysql -u root -prootpass -e "SELECT user, host FROM mysql.user;"

# Voir les logs MySQL
sudo docker-compose logs mysql
```

### Scripts Python

```bash
# Exécuter script mkmpy
sudo docker-compose exec app bash -c "cd /opt/mkmpy && ./.venv/bin/python3 ./launch.py"

# Accéder à l'environnement Python
sudo docker-compose exec app bash -c "cd /opt/mkmpy && source .venv/bin/activate && python"
```

## 🐛 Dépannage

### Problèmes courants

**Port 8000 déjà utilisé**
```bash
# Trouver le processus
sudo lsof -i :8000
# Modifier le port dans docker-compose.yml
```

**Erreur MySQL connection (Access denied)**
```bash
# Vérifier que MySQL est démarré
sudo docker-compose ps
# Vérifier les logs
sudo docker-compose logs mysql

# Si problème avec caractères spéciaux dans le mot de passe
# Modifier config.ini avec un mot de passe simple
# Exemple: password = simplepass123 (éviter $, !, @, %)
```

**Reset complet en cas de problème de configuration**
```bash
# Nettoyage complet Docker (supprime TOUT)
sudo docker system prune -a --volumes

# Suppression manuelle des volumes persistants si nécessaire
sudo docker-compose down -v --remove-orphans

# Redémarrage propre
./docker-start.sh
```

### Logs détaillés

```bash
# Logs application complète
sudo docker-compose logs app

# Logs MySQL uniquement  
sudo docker-compose logs mysql

# Logs avec timestamps
sudo docker-compose logs -t app
```

### Nettoyage et maintenance

```bash
# Nettoyage léger (garde les images de base)
sudo docker-compose down -v

# Nettoyage complet (libère maximum d'espace)
sudo docker system prune -a --volumes

# Vérification de l'espace utilisé
sudo docker system df

# Surveillance des conteneurs
sudo docker stats
```

### Debugging efficace

```bash
# Logs avec timestamps pour troubleshooting
sudo docker-compose logs -t -f app

# Tester la connectivité réseau entre conteneurs
sudo docker exec dockermkmpy_app_1 nc -zv mysql 3306

# Vérifier la configuration générée
sudo docker exec dockermkmpy_app_1 cat /var/www/html/.env.local
```

### Tests

```bash
# Test démarrage complet
./docker-start.sh

# Test accès web
curl -I http://localhost:8000

# Test base de données
mysql -h 127.0.0.1 -P 3307 -u test_user -psimplepass -e "SHOW DATABASES;"
```
## License

MIT License - voir [LICENSE](LICENSE) pour les détails.