FROM php:7.4-fpm-alpine3.12

MAINTAINER Patric Eckhart <mail@patriceckhart.com>

ENV DB_DATABASE databasename
ENV DB_HOST databasehost
ENV DB_USER databaseuser
ENV DB_PASS databasepassword

ENV SITE_PACKAGE nosite
ENV ADMIN_PASSWORD noadmpwd
ENV EDITOR_USERNAME noeditorusr
ENV EDITOR_PASSWORD noeditorpwd
ENV EDITOR_ROLE norole

ENV GITHUB_TOKEN nogittoken

ENV UPDATEPACKAGES non

ENV PERSISTENT_RESOURCES_FALLBACK_BASE_URI non

RUN set -x \
	&& apk update \
	&& apk add bash \
	&& apk add nano git nginx tar curl postfix mysql-client optipng freetype libjpeg-turbo-utils icu-dev vips-dev vips-tools openssh pwgen build-base && apk add --virtual libtool freetype-dev libpng-dev libjpeg-turbo-dev yaml-dev libssh2-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install \
		gd \
		pdo \
		pdo_mysql \
		opcache \
		intl \
		exif \
		json \
		tokenizer \
	&& apk add --no-cache --virtual .deps imagemagick imagemagick-libs imagemagick-dev autoconf \
	&& deluser www-data \
	&& delgroup cdrw \
	&& addgroup -g 80 www-data \
	&& adduser -u 80 -G www-data -s /bin/bash -D www-data -h /data \
	&& rm -Rf /home/www-data \
	&& sed -i -e "s#listen = 9000#listen = /var/run/php-fpm.sock#" /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& sed -i -e "s#keepalive_timeout 65#keepalive_timeout 75#" /etc/nginx/nginx.conf \
	&& sed -i -e "s#gzip_vary on#gzip_vary off#" /etc/nginx/nginx.conf \
	&& sed -i -e "s#client_max_body_size 1m#client_max_body_size 1024m#" /etc/nginx/nginx.conf \
	&& sed -i -e "s#listen = 127.0.0.1:9000#listen = /var/run/php-fpm.sock#" /usr/local/etc/php-fpm.d/www.conf \
	&& echo "clear_env = no" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.group = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& chown 80:80 -R /var/lib/nginx

RUN apk add --no-cache redis

RUN pecl install redis && docker-php-ext-enable redis

RUN docker-php-ext-install bcmath && docker-php-ext-enable bcmath

RUN apk add imap-dev krb5-dev
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
        && docker-php-ext-install imap \
        && docker-php-ext-enable imap

RUN apk add \
        libzip-dev \
        zip \
  && docker-php-ext-install zip

RUN pecl install imagick-beta && docker-php-ext-enable --ini-name 20-imagick.ini imagick
RUN pecl install vips && echo "extension=vips.so" > /usr/local/etc/php/conf.d/ext-vips.ini && docker-php-ext-enable --ini-name ext-vips.ini vips

RUN cd /tmp \
    && git clone https://git.php.net/repository/pecl/networking/ssh2.git \
    && cd /tmp/ssh2/ \
    && .travis/build.sh \
    && docker-php-ext-enable ssh2

RUN pecl install yaml && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/ext-yaml.ini && docker-php-ext-enable --ini-name ext-yaml.ini yaml

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=2.0.11 && rm -rf /tmp/composer-setup.php

RUN mkdir /etc/periodic/1min
RUN crontab -l | { echo "*       *       *       *       *       run-parts /etc/periodic/1min"; cat; } | crontab -

RUN echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY /config/nginx/neos.conf /etc/nginx/conf.d/default.conf
COPY /config/nginx/nginx.conf /etc/nginx/conf.d/vars.conf

RUN mkdir -p /run/nginx
RUN mkdir -p /sh

COPY /config/neos/Settings.yaml /sh/Settings.yaml
COPY /config/neos/set-settings.sh /sh/set-settings.sh
COPY /config/sshd/github-keys.sh /sh/github-keys.sh
COPY /config/neos/update-neos.sh /sh/update-neos.sh
COPY /config/neos/update-neos-silent.sh /sh/update-neos-silent.sh
COPY /config/neos/set-filepermissions.sh /sh/set-filepermissions.sh

COPY /config/neos/flush-cache.sh /sh/flush-cache.sh
COPY /config/neos/flush-cache-dev.sh /sh/flush-cache-dev.sh
COPY /config/neos/flush-cache-prod.sh /sh/flush-cache-prod.sh

COPY /config/pipeline/pull-app.sh /sh/pull-app.sh
RUN chmod 755 /sh/pull-app.sh

COPY /config/pipeline/pull-app-silent.sh /sh/pull-app-silent.sh
RUN chmod 755 /sh/pull-app-silent.sh

RUN chmod 755 /sh/update-neos-silent.sh

COPY /config/etc/motd /etc/motd

EXPOSE 80 22

WORKDIR /data

COPY /config/docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]