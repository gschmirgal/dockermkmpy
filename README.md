# dockermkmpy

![Docker Compose](https://img.shields.io/badge/Docker_Compose-v2-2496ED?logo=docker&logoColor=white)
![Symfony](https://img.shields.io/badge/Symfony-7.3-000000?logo=symfony&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

Déploiement Docker clé en main d'un outil de suivi et de prédiction des prix des cartes Magic: The Gathering sur Cardmarket.

Une seule commande construit l'image, démarre la base et l'interface web, puis lance le premier import de données.

## Contenu

La stack assemble trois projets, clonés automatiquement au build :

| Projet | Rôle | Emplacement dans le conteneur |
|---|---|---|
| [frontMkmPy](https://github.com/gschmirgal/frontMkmPy) | Interface web Symfony (consultation des prix, graphiques, prédictions) | `/var/www/html` |
| [mkmpy](https://github.com/gschmirgal/mkmpy) | Import quotidien des données Cardmarket et Scryfall dans MySQL | `/opt/mkmpy` |
| [MKMOraclePy](https://github.com/gschmirgal/MKMOraclePy) | Apprentissage (RandomForest) et prédiction des prix | `/opt/mkmoraclepy` |

Ils tournent dans deux conteneurs :

- **`mysql`** : MySQL 8.0, avec `local-infile` activé pour les imports CSV.
- **`app`** : PHP 8.4 et Apache, plus Python, ainsi que Chromium pour le scraping.

```
                 ┌───────────────── app ─────────────────┐
navigateur ────▶ │  Apache + Symfony (frontMkmPy)  :8000 │
                 │                                       │      ┌─ mysql ─┐
  daily-task ──▶ │  mkmpy (import) ─▶ MKMOraclePy        │ ───▶ │ mkmpy_db│
 weekly-task ──▶ │                    (learn / predict)  │      └─────────┘
                 │  /data : CSV d'import, modèles IA     │
                 └───────────────────────────────────────┘
```

## Démarrage

Prérequis :
- Docker avec Compose v2 (`docker compose`)
- Ports 8000 et 3307 libres
- 4 Go de RAM
- Architecture x86_64 ou arm64

```bash
git clone https://github.com/gschmirgal/dockermkmpy.git
cd dockermkmpy

# Changer au minimum les mots de passe
nano config/config.ini

./docker-start.sh
```

L'application est ensuite accessible sur http://localhost:8000.

Au premier démarrage, un import complet se lance en arrière-plan, sans bloquer l'accès au site. Il dure plusieurs minutes. Pour le suivre :

```bash
sudo docker compose exec app tail -f /data/first-import.log
```

## Tâches planifiées

| Script | Fréquence | Ce qu'il fait |
|---|---|---|
| `daily-task.sh` | Quotidienne | Importe les nouvelles données Cardmarket, puis calcule les prédictions |
| `weekly-task.sh` | Hebdomadaire | Réentraîne le modèle de prédiction |

Les prédictions n'apparaissent qu'après quelques jours d'historique et un premier apprentissage.

Les scripts fonctionnent depuis n'importe quel dossier, ce qui permet de les mettre dans la crontab de root :

```cron
0 6 * * *  /chemin/vers/dockermkmpy/daily-task.sh
0 3 * * 0  /chemin/vers/dockermkmpy/weekly-task.sh
```

## Configuration

Toute la configuration se trouve dans [config/config.ini](config/config.ini), partagé par les trois projets :

| Section | Contenu |
|---|---|
| `[App]` | `env` : `prod` (par défaut) ou `dev` (mode debug Symfony, barre de debug) |
| `[Database]` | Connexion MySQL, plus `root_password` (lu uniquement par `docker-start.sh`) |
| `[Folders]` | `temp` : dossier des CSV et des modèles, à laisser sur `/data/` (volume persistant) |
| `[Logging]` | `WARNING` (silencieux) ou `INFO` (déroulé complet de l'import) |
| `[Browser]` | `chrome_version` : version de Chromium à forcer en cas de souci de scraping |
| `[IA]` | Hyperparamètres du RandomForest |

Le fichier est monté dans le conteneur. Après une modification, il suffit de redémarrer l'application, sans rebuild :

```bash
sudo docker compose restart app
```

Par exemple, pour déboguer le front, passez `[App] env = dev`, redémarrez, puis revenez à `prod` une fois terminé.

Le `APP_SECRET` de Symfony est généré au premier démarrage et conservé dans le volume `/data`.

> [!WARNING]
> Évitez `$`, `!`, `@` et `%` dans les mots de passe : ils cassent l'URL de connexion Doctrine.

> [!NOTE]
> Les identifiants MySQL ne sont appliqués qu'à la création de la base. Pour les changer ensuite, il faut soit les modifier dans MySQL, soit repartir de zéro (`down -v`).

## Mise à jour

```bash
./docker-start.sh
```

Le build vérifie s'il y a un nouveau commit sur la branche `main` de chacun des trois projets. Il ne re-clone et ne réinstalle que les projets qui ont changé, et les migrations Doctrine s'appliquent au démarrage.

## Données

| Volume | Contenu |
|---|---|
| `mysql_data` | Base de données |
| `app_data` | `/data` : CSV d'import, modèles entraînés, log du premier import |

`sudo docker compose down` arrête la stack et conserve les données.

`sudo docker compose down -v` supprime en plus **toutes les données**. Le démarrage suivant repart de zéro et relance un import initial.

MySQL n'écoute que sur la machine hôte, au port `127.0.0.1:3307` :

```bash
mysql -h 127.0.0.1 -P 3307 -u test_user -p mkmpy_db
```

## Commandes utiles

```bash
sudo docker compose ps                 # état des conteneurs
sudo docker compose logs -f app        # logs de l'application
sudo docker compose exec app bash      # shell dans le conteneur
sudo docker compose restart app        # redémarrer l'application seule
sudo docker compose exec app php bin/console doctrine:migrations:migrate
```

## Dépannage

| Symptôme | Piste |
|---|---|
| `app` ne démarre pas | `sudo docker compose logs app` : le plus souvent MySQL injoignable ou une migration en échec |
| `Access denied` sur MySQL | Mot de passe avec caractère spécial, ou modifié après la création de la base (voir [Configuration](#configuration)) |
| Port 8000 ou 3307 déjà pris | Changer le port côté hôte dans [docker-compose.yml](docker-compose.yml) |
| Import bloqué sur Cardmarket | Passer `[Logging] level = INFO` pour voir l'étape fautive, ajuster `[Browser] chrome_version` |
| Base vide après le premier démarrage | Consulter `/data/first-import.log`. Si l'import a échoué, il sera relancé au prochain démarrage. On peut aussi lancer `./daily-task.sh` |

## Structure

```
config/
  config.ini          configuration commune
  apache-vhost.conf   vhost Apache
  .htaccess           réécriture d'URL Symfony
scripts/
  startup.sh          point d'entrée du conteneur (migrations, import initial, Apache)
  generate-env.sh     génère .env.local pour Symfony depuis config.ini
  ini.sh              lecture de config.ini
docker-start.sh       build + démarrage
daily-task.sh         import + prédiction
weekly-task.sh        apprentissage
```

## Licence

MIT
