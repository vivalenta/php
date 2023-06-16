FROM php:8.2-fpm-alpine

#docker build . -t wuddi/php
MAINTAINER Vitalii Shvets <wuddi@wuddi.in.ua>
LABEL REFRESHED_AT=2023-03-01

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime &&  echo $TZ > /etc/timezone

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    ffmpeg \
    bash \
    py3-pip \
    wget \
    curl \
    nano \
    gnu-libiconv \
    imagemagick \
    libxml2 \
    php82-apcu \
    php82-bcmath \
    php82-bz2 \
    php82-dom \
    php82-exif \
    php82-ftp \
    php82-gd \
    php82-gmp \
    php82-imap \
    php82-intl \
    php82-ldap \
    php82-opcache \
    php82-pcntl \
    php82-pdo_mysql \
    php82-pdo_pgsql \
    php82-pdo_sqlite \
    php82-pecl-imagick \
    php82-pecl-memcached \
    php82-pecl-smbclient \
    php82-pgsql \
    php82-posix \
    php82-redis \
    php82-sodium \
    php82-sqlite3 \
    php82-sysvsem \
    php82-xmlreader \
    samba-client \
    sudo && \
  apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    php82-pecl-mcrypt && \
  echo "**** configure php and nginx for nextcloud ****" && \
  echo 'apc.enable_cli=1' >> /etc/php82/conf.d/apcu.ini && \
  sed -i \
    -e 's/;opcache.enable.*=.*/opcache.enable=1/g' \
    -e 's/;opcache.interned_strings_buffer.*=.*/opcache.interned_strings_buffer=16/g' \
    -e 's/;opcache.max_accelerated_files.*=.*/opcache.max_accelerated_files=10000/g' \
    -e 's/;opcache.memory_consumption.*=.*/opcache.memory_consumption=128/g' \
    -e 's/;opcache.save_comments.*=.*/opcache.save_comments=1/g' \
    -e 's/;opcache.revalidate_freq.*=.*/opcache.revalidate_freq=1/g' \
    -e 's/;always_populate_raw_post_data.*=.*/always_populate_raw_post_data=-1/g' \
    -e 's/memory_limit.*=.*128M/memory_limit=2048M/g' \
    -e 's/max_execution_time.*=.*30/max_execution_time=120/g' \
    -e 's/upload_max_filesize.*=.*2M/upload_max_filesize=1024M/g' \
    -e 's/post_max_size.*=.*8M/post_max_size=1024M/g' \
    -e 's/output_buffering.*=.*/output_buffering=0/g' \
      /etc/php82/php.ini && \
  sed -i \
    '/opcache.enable=1/a opcache.enable_cli=1' \
      /etc/php82/php.ini && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php82/php-fpm.conf


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
