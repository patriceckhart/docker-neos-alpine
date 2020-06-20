#!/bin/bash

echo "Start pulling the git repository ... "

cd /data/neos && git reset --hard

if [ "$GITHUB_TOKEN" == "nogittoken" ]; then
	cd /data/neos && git pull $GITHUB_REPOSITORY
else
	cd /data/neos && git pull https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPOSITORY
fi

# cd /data/neos && composer update --no-interaction

cd /data/neos && ./flow flow:core:setfilepermissions

cd /data/neos && ./flow flow:package:rescan

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:package:rescan

cd /data/neos && ./flow doctrine:update

cd /data/neos && FLOW_CONTEXT=Production ./flow doctrine:update

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force

cd /data/neos && ./flow flow:cache:flush --force

chown -R www-data:www-data /data/neos

echo "Git repository was pulled successfully."
