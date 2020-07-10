#!/bin/bash

cd /data/neos && ./flow flow:core:setfilepermissions
echo "Correct file permissions are set."

cd /data/neos && FLOW_CONTEXT=Production ./flow flow:cache:flush --force
echo "Flow cache are flushed."