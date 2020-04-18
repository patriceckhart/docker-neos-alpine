#!/bin/bash

echo "Start pulling the git repository ... "

if [ "$GITHUB_TOKEN" == "nogittoken" ]; then
	cd /data/neos && git pull $GITHUB_REPOSITORY
else
	cd /data/neos && git pull https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPOSITORY
fi

chown -R www-data:www-data /data/neos

echo "Git repository was pulled successfully."
