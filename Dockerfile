FROM php:7.2-fpm-alpine3.10

MAINTAINER Patric Eckhart <mail@patriceckhart.com>

ENV DB_DATABASE db
ENV DB_HOST db
ENV DB_USER admin
ENV DB_PASS pass
ENV VERSION master
ENV BASE_URI /

RUN set -x \
	&& apk update \
	&& apk add bash \
	&& apk add nano git nginx tar curl mysql-client optipng freetype libjpeg-turbo-utils icu-dev openssh pwgen build-base && apk add --virtual libtool freetype-dev libpng-dev libjpeg-turbo-dev yaml-dev \
	&& docker-php-ext-configure gd \
		--with-gd \
		--with-freetype-dir=/usr/include/ \
		--with-png-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install \
		gd \
		pdo \
		pdo_mysql \
		mbstring \
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
	&& sed -i -e "s#sendfile on#sendfile off#" /etc/nginx/nginx.conf \
	&& sed -i -e "s#listen = 127.0.0.1:9000#listen = /var/run/php-fpm.sock#" /usr/local/etc/php-fpm.d/www.conf \
	&& echo "clear_env = no" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.owner = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.group = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& echo "listen.mode = 0660" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
	&& chown 80:80 -R /var/lib/nginx

RUN pecl install imagick-beta && docker-php-ext-enable --ini-name 20-imagick.ini imagick

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=1.9.2 && rm -rf /tmp/composer-setup.php

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY /config/nginx/neos.conf /etc/nginx/conf.d/default.conf
COPY /config/nginx/nginx.conf /etc/nginx/conf.d/vars.conf

RUN mkdir -p /run/nginx

COPY /config/neos/Settings.yaml /data/Settings.yaml
COPY /config/neos/set-settings.sh /set-settings.sh
COPY /config/sshd/github-keys.sh /github-keys.sh
COPY /config/neos/update-neos.sh /update-neos.sh
COPY /config/neos/set-filepermissions.sh /set-filepermissions.sh

EXPOSE 80 22

WORKDIR /data

COPY /config/docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]