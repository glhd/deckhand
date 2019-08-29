FROM php:7.3-alpine

MAINTAINER Chris Morrell

# Install base packages

RUN apk upgrade \
    && apk add --no-cache openssl icu-dev zlib-dev libzip-dev sqlite-dev libpng-dev libjpeg-turbo-dev mysql-client \
    && apk add --no-cache --virtual .build-deps autoconf gcc make g++ zlib-dev file g++ libc-dev pkgconf libmemcached-dev

# Configure PHP (extensions & composer)

RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure gd \
    && docker-php-ext-install gd \
    && docker-php-ext-install exif \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

# Pre-load composer cache

ENV COMPOSER_ALLOW_SUPERUSER 1
RUN composer require --no-interaction --no-plugins --no-scripts --no-progress --no-suggest --prefer-dist \
    fideloper/proxy laravel/framework laravel/tinker

# Install dockerize

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Clean up packages only needed a build time

RUN apk del .build-deps && rm -rf tmp/* && rm -f composer.js && rm -rf vendor

# And we're ready to be extended

CMD ["/bin/sh"]
