FROM php:7.3-alpine

MAINTAINER Chris Morrell

ENV MYSQL_ALLOW_EMPTY_PASSWORD=true
ENV MYSQL_HOST=127.0.0.1
ENV MYSQL_ROOT_HOST=%
ENV MYSQL_USER=root

ENV DOCKERIZE_VERSION v0.6.1
ENV NODE_VERSION 10.16.3
ENV YARN_VERSION 1.17.3
ENV REDIS_VERSION 5.0.5
ENV REDIS_SHA 2139009799d21d8ff94fc40b7f36ac46699b9e1254086299f8d3b223ca54a375

# Set up users and groups

RUN addgroup -g 1000 node \
    && addgroup -g 1500 redis \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && adduser -u 1500 -G redis -s /bin/sh -D redis

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
        libjpeg-turbo \
        mysql \
        mysql-client \
        libstdc++ \
        tzdata \
    && apk add --no-cache --virtual .build-deps \
        coreutils \
        musl-dev \
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
        tar

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
    && docker-php-ext-enable xdebug \
    && php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

# Install dockerize

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install Node
RUN for key in \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        77984A986EBC2AA786BC0F66B01FBB92821C587A \
        8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
        4ED778F539E3634C779C87C6D7062848A1AB005C \
        A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
        B9E2F5981AA6E0CD28160D9FF13993A75599653C \
        6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
        gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
        gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) V= \
    && make install \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
    && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

# Install Redis
RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"; \
	echo "$REDIS_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	serverMd5="$(md5sum /usr/local/bin/redis-server | cut -d' ' -f1)"; export serverMd5; \
	find /usr/local/bin/redis* -maxdepth 0 \
		-type f -not -name redis-server \
		-exec sh -eux -c ' \
			md5="$(md5sum "$1" | cut -d" " -f1)"; \
			test "$md5" = "$serverMd5"; \
		' -- '{}' ';' \
		-exec ln -svfT 'redis-server' '{}' ';' \
	; \
	rm -r /usr/src/redis; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache .redis-rundeps $runDeps;

# Configure MySQL
RUN echo '\n\
[mysqld]\n\
user = root\n\
datadir = /dev/shm/mysql\n\
collation-server = utf8_unicode_ci\n\
init-connect="SET NAMES utf8"\n\
character-set-server = utf8\n\
innodb_flush_log_at_trx_commit=2\n\
sync_binlog=0\n\
innodb_use_native_aio=0\n' >> /etc/mysql/my.cnf

# Clean up packages only needed a build time

RUN apk del .build-deps && rm -rf tmp/* && rm -f composer.js && rm -rf vendor

# And we're ready to be extended

CMD ["/bin/sh"]
