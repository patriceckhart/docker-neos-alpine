#!/bin/bash

cd /data/neos && composer update

cd /data/neos && ./flow flow:core:setfilepermissions

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force