#!/usr/bin/env bash

source /usr/local/lib/mydump/common-properties.lib

cd /opt/mydump; git pull origin master
sudo apt install ${programs2install} -y
