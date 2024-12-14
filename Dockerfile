FROM php:7.4-apache

# Create non-root user and add to www-data group
RUN useradd -m composer && \
    usermod -a -G www-data composer

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libxml2-dev \
    xvfb \
    nodejs \
    npm \
    wget \
    && docker-php-ext-install zip xml mysqli pdo pdo_mysql

# Enable Apache modules
RUN a2enmod rewrite

# Install specific Composer version
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.10.26

# Set working directory and permissions
WORKDIR /var/www/html
RUN mkdir -p /var/www/.composer && \
    chown -R composer:www-data /var/www/.composer

# Configure Git for HTTPS
USER composer
ARG GITHUB_TOKEN
RUN git config --global url."https://github.com/".insteadOf git@github.com: && \
    git config --global url."https://".insteadOf git:// && \
    if [ -n "$GITHUB_TOKEN" ]; then \
      composer config -g github-oauth.github.com $GITHUB_TOKEN; \
    fi

USER root

# Download and setup MediaWiki
RUN wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.0.tar.gz \
    && tar -xzf mediawiki-1.31.0.tar.gz \
    && mv mediawiki-1.31.0/* . \
    && rm mediawiki-1.31.0.tar.gz \
    && chown -R composer:www-data .

# Download Wikifab
RUN wget https://github.com/Wikifab/wikifab-main/archive/master.zip \
    && unzip master.zip \
    && cp -R wikifab-main-master/* . \
    && rm master.zip \
    && chown -R composer:www-data .

# Install Tabber extension
RUN cd extensions \
    && wget -O tabber.zip https://github.com/HydraWiki/Tabber/archive/master.zip \
    && unzip tabber.zip \
    && mv Tabber-master Tabber \
    && rm tabber.zip \
    && chown -R composer:www-data .

# Set composer config and install dependencies
USER composer
RUN composer config minimum-stability dev \
    && composer config prefer-stable true \
    && composer config -g github-protocols https \
    && composer update --no-dev --no-plugins --prefer-dist \
    && composer require wikimedia/composer-merge-plugin:1.5.0

USER root

# Move Flow extension and set final permissions
RUN mv vendor/mediawiki/flow extensions/Flow && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]