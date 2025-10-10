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
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copie config.ini pour scripts Python
COPY ./config/config.ini /opt/config.ini

# Copie script d'initialisation
COPY ./scripts/init.sh /init.sh
RUN chmod +x /init.sh

# Clonage projets GitHub
RUN git clone https://github.com/gschmirgal/frontMkmPy.git /var/www/html && \
    git clone https://github.com/gschmirgal/mkmpy.git /opt/mkmpy && \
    git clone https://github.com/gschmirgal/MKMOraclePy.git /opt/mkmoraclepy

# Création environnements virtuels Python
RUN cd /opt/mkmpy && python3 -m venv .venv && \
    cd /opt/mkmoraclepy && python3 -m venv .venv

# Copie scripts de configuration et démarrage
COPY ./scripts/generate-env.sh /generate-env.sh
COPY ./scripts/startup.sh /startup.sh
RUN chmod +x /generate-env.sh /startup.sh

# Correction permissions Git pour Symfony
RUN git config --global --add safe.directory /var/www/html

# Installation dépendances Symfony au build
WORKDIR /var/www/html
# .env temporaire pour éviter erreur DATABASE_URL au build
RUN echo "DATABASE_URL=mysql://dummy:dummy@localhost:3306/dummy" > .env
RUN composer install --optimize-autoloader

# Installation apache-pack et copie .htaccess
RUN composer require symfony/apache-pack --no-interaction && \
    composer recipes:install symfony/apache-pack --force || true

# Copie .htaccess depuis répertoire config
COPY ./config/.htaccess public/.htaccess

# Installation dépendances Python au build
RUN cd /opt/mkmpy && \
    . .venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt

RUN cd /opt/mkmoraclepy && \
    . .venv/bin/activate && \
    export MYSQLCLIENT_CFLAGS="-I/usr/include/mysql" && \
    export MYSQLCLIENT_LDFLAGS="-L/usr/lib/x86_64-linux-gnu -lmysqlclient" && \
    pip install --no-cache-dir -r requirements.txt

# Configuration Apache pour Symfony
COPY ./config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Activation module rewrite Apache
RUN a2enmod rewrite

# Configuration finale Symfony
WORKDIR /var/www/html
EXPOSE 80

# Exécution script de démarrage
CMD ["/startup.sh"]
