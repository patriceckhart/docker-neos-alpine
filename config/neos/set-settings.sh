#!/bin/bash

sed -i -e "s#%env:DB_DATABASE%#$DB_DATABASE#" /data/neos/Configuration/Settings.yaml
sed -i -e "s#%env:DB_USER%#$DB_USER#" /data/neos/Configuration/Settings.yaml
sed -i -e "s#%env:DB_PASS%#$DB_PASS#" /data/neos/Configuration/Settings.yaml
sed -i -e "s#%env:DB_HOST%#$DB_HOST#" /data/neos/Configuration/Settings.yaml
sed -i -e "s#%env:BASE_URI%#$BASE_URI#" /data/neos/Configuration/Settings.yaml
