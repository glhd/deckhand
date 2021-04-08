FROM php:7.4-alpine

MAINTAINER Chris Morrell

ENV DOCKERIZE_VERSION=v0.6.1 \
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
	PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Set up user

RUN addgroup -g 1000 deckhand \
	&& adduser -u 1000 -G deckhand -s /bin/sh -D deckhand \
	&& mkdir -p /home/deckhand/Downloads /app \
	&& chown -R deckhand:deckhand /home/deckhand \
    && chown -R deckhand:deckhand /app

# Install base packages

RUN apk upgrade
RUN apk add --no-cache \
	git \
	openssl \
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
	npm \
	imagemagick \
	curl \
	tar \
	icu-dev \
	zlib-dev \
	libzip-dev \
	sqlite

RUN apk add --no-cache --virtual .build-deps \
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
	gnupg \
	libgcc \
	linux-headers \
	python3 \
	imagemagick-dev \
	libtool

# Configure PHP (extensions & composer)

RUN docker-php-ext-configure intl \
	&& docker-php-ext-install intl \
	&& docker-php-ext-install zip \
	&& docker-php-ext-install pdo_mysql \
	&& docker-php-ext-configure gd \
		--enable-gd \
        --with-jpeg \
        --with-freetype \
	&& docker-php-ext-install gd \
	&& docker-php-ext-install exif \
	&& pecl install xdebug \
	&& pecl install imagick \
	&& pecl install pcov

RUN docker-php-ext-enable imagick \
	&& docker-php-ext-enable pcov \
	&& php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer

# Install dockerize

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Clean up packages only needed a build time

RUN apk del .build-deps && rm -rf tmp/*

# Switch to our local user

USER deckhand

# And we're set

CMD ["/bin/sh"]
