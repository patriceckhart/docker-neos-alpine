#!/bin/bash

cd /data/neos && composer update --no-interaction

cd /data/neos && ./flow flow:core:setfilepermissions

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force

cd /data/neos && ./flow flow:cache:flush --force

chown -R www-data:www-data /data/neos