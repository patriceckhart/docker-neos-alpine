#!/bin/bash
set -ex

DIR="/data/neos/Web"
FILE=/data/neos/composer.lock
PHP="/php"
INSTALL="/install"

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

if [ "$PERSISTENT_RESOURCES_FALLBACK_BASE_URI" != "non" ]; then

  if [ -f "$FILE" ]; then

    echo "Resource fallback uri has already been added."

  else

    sed -i -e "s#8.8.8.8;#8.8.8.8;proxy_pass $PERSISTENT_RESOURCES_FALLBACK_BASE_URI;#" /etc/nginx/conf.d/default.conf

  fi

fi

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

  echo "install" > /install

  if [ "$DB_DATABASE" == "databasename" ]; then

    echo "Neos must be set up manually."
    
  else

    mv /Settings.yaml /data/neos/Configuration/Settings.yaml
    su www-data -c "/sh/set-settings.sh"
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

CRONDIR="/data/cron/"

if [ -d "$CRONDIR" ]; then
  
  echo "Cron directory exist."

else

  echo "Create cron directory ..."

  mkdir -p /data/cron

  echo "Cron directory created."

fi

if [ -d "/data/cron/1min" ]; then
  echo "Cron 1 min directory exist."
else
  mkdir -p /data/cron/1min
  echo "Cron 1 min directory created."
fi
if [ -d "/data/cron/15min" ]; then
  echo "Cron 15 min directory exist."
else
  mkdir -p /data/cron/15min
  echo "Cron 15 min directory created."
fi
if [ -d "/data/cron/hourly" ]; then
  echo "Cron hourly directory exist."
else
  mkdir -p /data/cron/hourly
  echo "Cron hourly directory created."
fi
if [ -d "/data/cron/daily" ]; then
  echo "Cron daily directory exist."
else
  mkdir -p /data/cron/daily
  echo "Cron daily directory created."
fi
if [ -d "/data/cron/weekly" ]; then
  echo "Cron weekly directory exist."
else
  mkdir -p /data/cron/weekly
  echo "Cron weekly directory created."
fi
if [ -d "/data/cron/monthly" ]; then
  echo "Cron monthly directory exist."
else
  mkdir -p /data/cron/monthly
  echo "Cron monthly directory created."
fi

rm -rf /etc/periodic/1min
rm -rf /etc/periodic/15min
rm -rf /etc/periodic/hourly
rm -rf /etc/periodic/daily
rm -rf /etc/periodic/weekly
rm -rf /etc/periodic/monthly

ln -s /data/cron/1min /etc/periodic/1min
ln -s /data/cron/15min /etc/periodic/15min
ln -s /data/cron/hourly /etc/periodic/hourly
ln -s /data/cron/daily /etc/periodic/daily
ln -s /data/cron/weekly /etc/periodic/weekly
ln -s /data/cron/monthly /etc/periodic/monthly

nginx
echo "nginx has started."

chown -R www-data:www-data /data
chmod -R 775 /data

su www-data -c "/sh/set-filepermissions.sh"

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
    su www-data -c "/sh/github-keys.sh $user"
  done
fi

if [ "$UPDATEPACKAGES" == "daily" ]; then

  cp /sh/update-neos.sh /data/cron/daily/200-updateneos

fi

if [ "$UPDATEPACKAGES" == "weekly" ]; then

  cp /sh/update-neos.sh /data/cron/weekly/200-updateneos

fi

if [ "$UPDATEPACKAGES" == "monthly" ]; then

  cp /sh/update-neos.sh /data/cron/monthly/200-updateneos

fi

cp /sh/update-neos.sh /usr/local/bin/updateneos
cp /sh/update-neos-silent.sh /usr/local/bin/updateneossilent
cp /sh/set-filepermissions.sh /usr/local/bin/setfilepermissions

cp /sh/flush-cache.sh /usr/local/bin/flushcache
cp /sh/flush-cache-dev.sh /usr/local/bin/flushcachedev
cp /sh/flush-cache-prod.sh /usr/local/bin/flushcacheprod

cp /sh/pull-app.sh /usr/local/bin/pullapp
cp /sh/pull-app-silent.sh /usr/local/bin/pullappsilent

chmod 755 /usr/local/bin/updateneos
chmod 755 /usr/local/bin/updateneossilent
chmod 755 /usr/local/bin/setfilepermissions
chmod 755 /usr/local/bin/flushcache
chmod 755 /usr/local/bin/flushcachedev
chmod 755 /usr/local/bin/flushcacheprod
chmod 755 /usr/local/bin/pullapp
chmod 755 /usr/local/bin/pullappsilent

chown -Rf nginx:nginx /var/lib/nginx

postfix start

/usr/sbin/sshd

echo "SSH has started."

echo "crond has started."

echo "Container is up und running."

/usr/sbin/crond -fS

tail -f /dev/null
#exec "$@"