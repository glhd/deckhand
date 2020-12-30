FROM php:8.0-alpine

MAINTAINER Chris Morrell

ENV DOCKERIZE_VERSION=v0.6.1 \
	PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
	PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

RUN mkdir -p ~/Downloads /app \
	&& apk upgrade
	
RUN apk add --no-cache \
		bash \
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
		
RUN git clone https://github.com/Imagick/imagick.git imagick-src \
	&& cd imagick-src \
	&& ls -lh \
	&& phpize \
	&& ./configure --without-perl --disable-docs \
	&& make install -j$(nproc) \
	&& cd ..
		
RUN docker-php-ext-configure intl \
	&& docker-php-ext-install -j$(nproc) intl \
	&& docker-php-ext-install -j$(nproc) zip \
	&& docker-php-ext-install -j$(nproc) pdo_mysql \
	&& docker-php-ext-install -j$(nproc) bcmath \
	&& docker-php-ext-configure gd \
		--enable-gd \
		--with-jpeg \
		--with-freetype \
	&& docker-php-ext-install -j$(nproc) gd \
	&& docker-php-ext-install -j$(nproc) exif \
	&& pecl install xdebug \
	&& pecl install redis
	
RUN docker-php-ext-enable imagick \
	&& docker-php-ext-enable redis

RUN php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv composer.phar /usr/local/bin/composer
	
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& apk del .build-deps \
	&& rm -rf imagick-src \
	&& rm -rf tmp/*

# And we're set

CMD ["/bin/bash"]
