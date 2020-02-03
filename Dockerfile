FROM php:7.2-fpm-alpine3.10

MAINTAINER Patric Eckhart <mail@patriceckhart.com>

RUN set -x \
	&& apk update \
	&& apk add bash \
	&& apk add nano git nginx tar curl mysql-client optipng freetype libjpeg-turbo-utils icu-dev openssh build-base && apk add --virtual libtool freetype-dev libpng-dev libjpeg-turbo-dev yaml-dev \
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
	&& apk add --no-cache --virtual .deps imagemagick imagemagick-libs imagemagick-dev autoconf

RUN pecl install imagick-beta && docker-php-ext-enable --ini-name 20-imagick.ini imagick

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=1.9.2 && rm -rf /tmp/composer-setup.php

EXPOSE 80 22

WORKDIR /data

COPY /config/docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]