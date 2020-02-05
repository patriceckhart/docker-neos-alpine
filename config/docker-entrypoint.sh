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
  #cd /data/neos && ./flow doctrine:migrate
  #cd /data/neos && ./flow doctrine:update
  #echo "Import site ..."
  #cd /data/neos && ./flow site:import Raw.Site
  #echo "Database updated."

  #echo "Create user ..."
  #cd /data/neos && ./flow user:create admin $ADMIN_PASSWORD inoovum admin
  #cd /data/neos && ./flow user:addrole admin Neos.Neos:Administrator
  #cd /data/neos && ./flow user:create $EDITOR_USERNAME $EDITOR_PASSWORD $EDITOR_FIRSTNAME $EDITOR_LASTNAME
  #cd /data/neos && ./flow user:addrole $EDITOR_USERNAME Neos.Neos:Editor

  #echo "admin and editor created."
fi

nginx
echo "nginx has started."

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

/usr/sbin/sshd
echo "SSH has started."

tail -f /dev/null
#exec "$@"