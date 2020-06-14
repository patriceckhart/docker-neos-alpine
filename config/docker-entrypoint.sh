#!/bin/bash
set -ex

DIR="/data/neos/Web"
FILE=/data/neos/composer.lock
PHP="/php"

if [ -f "$PHP" ]; then
  echo "PHP has already been configured."
else
  echo "PHP Configuration ..."
  echo "date.timezone=${PHP_TIMEZONE:-Europe/Berlin}" > $PHP_INI_DIR/conf.d/date_timezone.ini
  echo "memory_limit=${PHP_MEMORY_LIMIT:-4096M}" > $PHP_INI_DIR/conf.d/memory_limit.ini
  echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE:-1024M}" > $PHP_INI_DIR/conf.d/upload_max_filesize.ini
  echo "post_max_size=${PHP_UPLOAD_MAX_FILESIZE:-1024M}" > $PHP_INI_DIR/conf.d/post_max_size.ini
  echo "allow_url_include=${PHP_ALLOW_URL_INCLUDE:-1}" > $PHP_INI_DIR/conf.d/allow_url_include.ini
  echo "max_execution_time=${PHP_MAX_EXECUTION_TIME:-240}" > $PHP_INI_DIR/conf.d/max_execution_time.ini
  echo "max_input_vars=${PHP_MAX_INPUT_VARS:-1500}" > $PHP_INI_DIR/conf.d/max_input_vars.ini
  rm -rf /var/cache/apk/*
  apk update && apk add tzdata
  cp /usr/share/zoneinfo/${PHP_TIMEZONE:-UTC} /etc/localtime
  apk del tzdata
  rm -rf /var/cache/apk/*
  echo "php" > /php
  echo "PHP configuration completed."
fi

/usr/local/sbin/php-fpm -y /usr/local/etc/php-fpm.conf -R -D
chmod 066 /var/run/php-fpm.sock
chown www-data:www-data /var/run/php-fpm.sock

if [ -f "$FILE" ]; then

  if [ "$GITHUB_TOKEN" != "nogittoken" ]; then

    composer config -g github-oauth.github.com $GITHUB_TOKEN

  fi

  echo "Neos is already installed."
else

  composer clear-cache --no-interaction

  echo "Downloading Neos ..."
  mkdir -p /data/neos

  if [ "$GITHUB_TOKEN" == "nogittoken" ]; then

    git clone $GITHUB_REPOSITORY /data/neos

  else

    git clone https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPOSITORY /data/neos
    composer config -g github-oauth.github.com $GITHUB_TOKEN
  
  fi

  echo "Installing Neos ..."
  chown -R www-data:www-data /data
  chmod -R 775 /data
  echo "Wait until composer update is finished!"
  cd /data/neos && composer update --no-interaction
  chown -R www-data:www-data /data
  chmod -R 775 /data
  echo "Neos installation completed."

  if [ "$DB_DATABASE" == "databasename" ]; then

    echo "Neos must be installed manually."
    
  else

    mv /Settings.yaml /data/neos/Configuration/Settings.yaml
    su www-data -c "/set-settings.sh"
    chown -R www-data:www-data /data
    chmod -R 775 /data

    echo "Update database ..."
    cd /data/neos && ./flow doctrine:migrate
    cd /data/neos && ./flow doctrine:update
    echo "Database updated."

    if [ "$SITE_PACKAGE" != "nosite" ]; then

      echo "Import site ..."
      cd /data/neos && ./flow site:import $SITE_PACKAGE
      echo "Site imported."

    fi

    if [ "$ADMIN_PASSWORD" != "noadmpwd" ]; then

      echo "Create user ..."
      cd /data/neos && ./flow user:create admin $ADMIN_PASSWORD Admin User
      cd /data/neos && ./flow user:addrole admin Neos.Neos:Administrator
      echo "admin created."

    fi

    if [ "$EDITOR_USERNAME" != "noeditorusr" ] && [ "$EDITOR_PASSWORD" != "noeditorpwd" ] ; then

      cd /data/neos && ./flow user:create $EDITOR_USERNAME $EDITOR_PASSWORD $EDITOR_FIRSTNAME $EDITOR_LASTNAME

      if [ "$EDITOR_ROLE" != "norole" ] ; then

        cd /data/neos && ./flow user:addrole $EDITOR_USERNAME $EDITOR_ROLE

      else

        cd /data/neos && ./flow user:addrole $EDITOR_USERNAME Neos.Neos:Editor

      fi
      
      echo "editor created."

    fi

  fi

fi

nginx
echo "nginx has started."

chown -R www-data:www-data /data
chmod -R 775 /data

su www-data -c "/set-filepermissions.sh"

echo "Start import Github keys ..."

set -e

[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -q -b 1024 -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key
[ -f /etc/ssh/ssh_host_dsa_key ] || ssh-keygen -q -b 1024 -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key
[ -f /etc/ssh/ssh_host_ecdsa_key ] || ssh-keygen -q -b 521  -N '' -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
[ -f /etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -q -b 1024 -N '' -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

[ -d /data/.ssh ] || mkdir /data/.ssh
[ -f /data/.ssh/authorized_keys ] || touch /data/.ssh/authorized_keys
chown www-data:www-data -R /data/.ssh
chmod go-w /data/
chmod 700 /data/.ssh
chmod 600 /data/.ssh/authorized_keys

PASS=$(pwgen -c -n -1 16)
echo "www-data:$PASS" | chpasswd

if [ -z "${GITHUB_USERNAME+xxx}" ] || [ -z "${GITHUB_USERNAME}" ]; then
  echo "WARNING: env variable \$GITHUB_USERNAME is not set. Please set it to have access to this container via SSH."
else
  for user in $(echo $GITHUB_USERNAME | tr "," "\n"); do
    echo "user: $user"
    su www-data -c "/github-keys.sh $user"
  done
fi

if [ "$UPDATEPACKAGES" == "daily" ]; then

  cp /update-neos.sh /etc/periodic/daily/update-neos.sh

fi

if [ "$UPDATEPACKAGES" == "weekly" ]; then

  cp /update-neos.sh /etc/periodic/weekly/update-neos.sh

fi

if [ "$UPDATEPACKAGES" == "monthly" ]; then

  cp /update-neos.sh /etc/periodic/monthly/update-neos.sh

fi

cp /update-neos.sh /usr/local/bin/updateneos
cp /set-filepermissions.sh /usr/local/bin/setfilepermissions

cp /flush-cache.sh /usr/local/bin/flushcache
cp /flush-cache-dev.sh /usr/local/bin/flushcachedev
cp /flush-cache-prod.sh /usr/local/bin/flushcacheprod

cp /pull-app.sh /usr/local/bin/pullapp

chown -Rf nginx:nginx /var/lib/nginx

postfix start

/usr/sbin/sshd

echo "SSH has started."

/usr/sbin/crond -fS

echo "crond has started."

echo "Container is up und running."

tail -f /dev/null
#exec "$@"