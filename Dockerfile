FROM php:8.4-apache

# Installation outils système et extensions PHP
RUN apt-get update && apt-get install -y \
    git unzip libicu-dev libonig-dev libzip-dev zip \
    python3 python3-pip python3-venv netcat-openbsd \
    default-libmysqlclient-dev build-essential pkg-config default-mysql-client \
    && docker-php-ext-install intl pdo pdo_mysql zip

# Installation Google Chrome pour le scraping des extensions Cardmarket
# Cloudflare bloque le Chromium de Debian, et sa simple présence fait aussi échouer Chrome :
# ne pas installer le paquet chromium à côté
# Google Chrome n'existe qu'en amd64 : sur arm64, repli sur Chromium (scraping probablement bloqué)
RUN apt-get update && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        curl -sfLo /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
        apt-get install -y /tmp/chrome.deb && rm /tmp/chrome.deb; \
    else \
        echo "ATTENTION : Google Chrome indisponible sur $(dpkg --print-architecture), installation de Chromium" && \
        apt-get install -y chromium; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Fuseau horaire du navigateur : Cloudflare bloque un navigateur en UTC derrière une IP française
ENV TZ=Europe/Paris

# Installation Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Correction permissions Git pour Symfony
RUN git config --global --add safe.directory /var/www/html

# Configuration Apache pour Symfony
COPY ./config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Activation module rewrite Apache
# Suppression de l'alias Debian /icons/ qui masque public/icons du front
RUN a2enmod rewrite && \
    sed -i 's|^Alias /icons/|#Alias /icons/|' /etc/apache2/mods-available/alias.conf

# Clonage projets GitHub, du moins souvent modifié au plus souvent modifié :
# un dépôt mis à jour ne reconstruit que lui et ceux qui le suivent
# Le ADD du dernier commit invalide le cache Docker uniquement quand le dépôt a changé
ADD https://api.github.com/repos/gschmirgal/mkmpy/git/refs/heads/main /tmp/ref-mkmpy.json
RUN git clone https://github.com/gschmirgal/mkmpy.git /opt/mkmpy && \
    cd /opt/mkmpy && python3 -m venv .venv && \
    ./.venv/bin/pip install --no-cache-dir -r requirements.txt

ADD https://api.github.com/repos/gschmirgal/MKMOraclePy/git/refs/heads/main /tmp/ref-oracle.json
RUN git clone https://github.com/gschmirgal/MKMOraclePy.git /opt/mkmoraclepy && \
    cd /opt/mkmoraclepy && python3 -m venv .venv && \
    export MYSQLCLIENT_CFLAGS="-I/usr/include/mysql" && \
    export MYSQLCLIENT_LDFLAGS="-L/usr/lib/$(uname -m)-linux-gnu -lmysqlclient" && \
    ./.venv/bin/pip install --no-cache-dir -r requirements.txt

ADD https://api.github.com/repos/gschmirgal/frontMkmPy/git/refs/heads/main /tmp/ref-front.json
RUN git clone https://github.com/gschmirgal/frontMkmPy.git /var/www/html

# Installation dépendances Symfony au build
# DATABASE_URL factice pour éviter l'erreur au build (la vraie est générée dans .env.local au démarrage)
WORKDIR /var/www/html
# Les dépendances de dev sont conservées pour pouvoir basculer en [App] env = dev
RUN export DATABASE_URL="mysql://dummy:dummy@localhost:3306/dummy?serverVersion=8.0" && \
    composer install --optimize-autoloader --no-interaction && \
    APP_ENV=prod php bin/console asset-map:compile

# Copie .htaccess depuis répertoire config
COPY ./config/.htaccess public/.htaccess

# Copie scripts de configuration et démarrage
COPY ./scripts/ini.sh /ini.sh
COPY ./scripts/generate-env.sh /generate-env.sh
COPY ./scripts/startup.sh /startup.sh
RUN chmod +x /generate-env.sh /startup.sh

EXPOSE 80

# Exécution script de démarrage
CMD ["/startup.sh"]
