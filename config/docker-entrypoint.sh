#!/bin/bash
set -ex

DIR="NeosCMS-Boilerplate"
if [ -d "$DIR" ]; then
  echo "NeosCMS-Boilerplate exists."
else
  echo "Downloading Neos"
  #git clone https://github.com/patriceckhart/NeosCMS-Boilerplate.git
  #mv NeosCMS-Boilerplate/composer.json /data/neos/composer.json
  #mv NeosCMS-Boilerplate/Source/* /data/neos/Source/
  #rm -rf NeosCMS-Boilerplate
  #echo "Installing Neos"
  #cd public && composer update
  #echo "Neos Install finished"
fi

tail -f /dev/null