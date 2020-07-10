#!/bin/bash

cd /data/neos && FLOW_CONTEXT=Development ./flow flow:cache:flush
cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush

cd /data/neos && FLOW_CONTEXT=Development ./flow flow:cache:flush --force
cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force

chown -R www-data:www-data /data/neos