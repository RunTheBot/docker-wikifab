FROM php:7.4-apache

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

# Set working directory
WORKDIR /var/www/html

# Download MediaWiki
RUN wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.0.tar.gz \
    && tar -xzf mediawiki-1.31.0.tar.gz \
    && mv mediawiki-1.31.0/* . \
    && rm mediawiki-1.31.0.tar.gz

# Download Wikifab
RUN wget https://github.com/Wikifab/wikifab-main/archive/master.zip \
    && unzip master.zip \
    && cp -R wikifab-main-master/* . \
    && rm master.zip

# Install Tabber extension
RUN cd extensions \
    && wget -O tabber.zip https://github.com/HydraWiki/Tabber/archive/master.zip \
    && unzip tabber.zip \
    && mv Tabber-master Tabber \
    && rm tabber.zip

# Set composer config and install dependencies
RUN composer config minimum-stability dev \
    && composer config prefer-stable true \
    && composer update --no-dev --no-plugins \
    && composer require wikimedia/composer-merge-plugin:1.5.0

# Move Flow extension
RUN mv vendor/mediawiki/flow extensions/Flow

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]