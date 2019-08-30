FROM php:7.3-alpine

MAINTAINER Chris Morrell

ENV DOCKERIZE_VERSION=v0.6.1 \
	NODE_VERSION=10.16.3 \
	YARN_VERSION=1.17.3 \
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Set up user

RUN addgroup -g 1000 deckhand && adduser -u 1000 -G deckhand -s /bin/sh -D deckhand

# Install base packages

RUN apk upgrade \
    && apk add --no-cache \
        git \
        openssl \
        icu-dev \
        zlib-dev \
        libzip-dev \
        sqlite-dev \
        libpng \
        freetype \
        ttf-freefont \
        libjpeg-turbo \
        mysql-client \
        libstdc++ \
        chromium \
        nss \
        harfbuzz \
        nodejs \
        yarn \
        imagemagick \
    && apk add --no-cache --virtual .build-deps \
        libpng-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        autoconf \
        gcc \
        make \
        g++ \
        zlib-dev \
        file \
        libc-dev \
        pkgconf \
        libmemcached-dev \
        binutils-gold \
        curl \
        gnupg \
        libgcc \
        linux-headers \
        python \
        tar \
        imagemagick-dev \
        libtool

# Configure PHP (extensions & composer)

RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install exif \
    && pecl install xdebug \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

# Install dockerize

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Clean up packages only needed a build time

RUN apk del .build-deps && rm -rf tmp/* && rm -f composer.js && rm -rf vendor

# Switch to our local user

USER deckhand

# And we're set

CMD ["/bin/sh"]
