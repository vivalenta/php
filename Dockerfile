FROM php:8.1-fpm-alpine

#docker build . -t wuddi/php
MAINTAINER Vitalii Shvets <wuddi@wuddi.in.ua>
LABEL REFRESHED_AT=2023-03-01

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime &&  echo $TZ > /etc/timezone

RUN apk add py3-pip wget curl ffmpeg nano
RUN set -ex; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    autoconf freetype-dev icu-dev libevent-dev libjpeg-turbo-dev libmcrypt-dev libpng-dev libmemcached-dev libxml2-dev libzip-dev openldap-dev pcre-dev postgresql-dev imagemagick-dev libwebp-dev gmp-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap; \
    docker-php-ext-configure sockets --enable-sockets; \
    docker-php-ext-configure sysvmsg --enable-sysvmsg; \
    docker-php-ext-configure sysvsem --enable-sysvsem; \
    docker-php-ext-configure sysvshm --enable-sysvshm; \
    docker-php-ext-install -j "$(nproc)" bcmath exif gd intl ldap opcache pcntl pdo_mysql pdo_pgsql zip gmp ; \
    pecl install APCu-5.1.21; pecl install memcached-3.2.0; pecl install redis-5.3.7; pecl install imagick-3.7.0; \
    docker-php-ext-enable apcu memcached redis imagick ; \
    rm -r /tmp/pear; \
    runDeps="$( scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' )"; \
    apk add --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del .build-deps
RUN pip3 install yt-dlp
RUN ln /usr/bin/yt-dlp /usr/local/bin/youtube-dl

RUN echo 'memory_limit = 512M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;
EXPOSE 9000
WORKDIR /var/www
