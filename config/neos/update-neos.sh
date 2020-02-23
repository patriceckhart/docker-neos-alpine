#!/bin/bash

echo "update" > /data/neos/Web/update.txt

cd /data/neos && composer update --no-interaction

cd /data/neos && ./flow flow:core:setfilepermissions

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force

rm -rf /data/neos/Web/update.txt