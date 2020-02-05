#!/bin/bash
set -ex

DIR="/data/neos"

/usr/local/sbin/php-fpm -y /usr/local/etc/php-fpm.conf -R -D
chmod 066 /var/run/php-fpm.sock
chown www-data:www-data /var/run/php-fpm.sock

if [ -d "$DIR" ]; then
  echo "Neos is already installed."
else
  echo "Downloading Neos ..."
  mkdir -p /data/neos
  git clone $GITHUB_REPOSITORY /data/neos
  echo "Installing Neos ..."
  chown -R www-data:www-data /data
  chmod -R 775 /data
  echo "Wait until composer update is finished!"
  cd /data/neos && composer update
  mv /data/Settings.yaml /data/neos/Configuration/Settings.yaml
  chown -R www-data:www-data /data
  chmod -R 775 /data
  echo "Neos installation completed."
  echo "Update database ..."
  cd /data/neos && ./flow doctrine:migrate
  cd /data/neos && ./flow doctrine:update
  echo "Import site ..."
  cd /data/neos && ./flow site:import Raw.Site
  echo "Database updated."

  echo "Create user ..."
  cd /data/neos && ./flow user:create admin $ADMIN_PASSWORD inoovum admin
  cd /data/neos && ./flow user:addrole admin Neos.Neos:Administrator
  cd /data/neos && ./flow user:create $EDITOR_USERNAME $EDITOR_PASSWORD $EDITOR_FIRSTNAME $EDITOR_LASTNAME
  cd /data/neos && ./flow user:addrole $EDITOR_USERNAME Neos.Neos:Editor

  echo "admin and editor created."
fi

nginx
echo "nginx has started."

#tail -f /dev/null
exec "$@"