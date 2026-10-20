FROM php:8.4-apache

# Installation outils système et extensions PHP
RUN apt-get update && apt-get install -y \
    git unzip libicu-dev libonig-dev libzip-dev zip \
    python3 python3-pip python3-venv netcat-openbsd \
    default-libmysqlclient-dev build-essential pkg-config default-mysql-client \
    && docker-php-ext-install intl pdo pdo_mysql zip

# Installation Chromium pour Selenium
RUN apt-get update && apt-get install -y \
    chromium chromium-driver \
    xvfb x11-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
    && rm -rf /var/lib/apt/lists/*

# Configuration chemins Chromium pour Selenium
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

# Installation Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Correction permissions Git pour Symfony
RUN git config --global --add safe.directory /var/www/html

# Clonage projets GitHub
# Le ADD du dernier commit invalide le cache Docker uniquement quand le dépôt a changé
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

# Configuration Apache pour Symfony
COPY ./config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Activation module rewrite Apache
RUN a2enmod rewrite

# Copie scripts de configuration et démarrage
COPY ./scripts/ini.sh /ini.sh
COPY ./scripts/generate-env.sh /generate-env.sh
COPY ./scripts/startup.sh /startup.sh
RUN chmod +x /generate-env.sh /startup.sh

EXPOSE 80

# Exécution script de démarrage
CMD ["/startup.sh"]
