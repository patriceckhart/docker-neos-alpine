#!/bin/bash

cd /data && echo "update" >> update

cd /data/neos && composer update --no-interaction

cd /data/neos && ./flow flow:core:setfilepermissions

cd /data/neos && ./flow flow:package:rescan

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:package:rescan

cd /data/neos && ./flow doctrine:update

cd /data/neos && FLOW_CONTEXT=Production ./flow doctrine:update

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force

cd /data/neos && ./flow flow:cache:flush --force

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush

cd /data/neos && ./flow flow:cache:flush

chown -R www-data:www-data /data/neos

cd /data && rm -rf update