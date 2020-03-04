#!/bin/bash
TAG=`curl --silent "https://api.github.com/repos/YOUR_GITHUB_USER/YOUR_REPO/releases/latest" | jq -r .tag_name`
wget https://github.com/YOUR_GITHUB_USER/YOUR_REPO/releases/download/$TAG/website.tar.gz
tar -xvf website.tar.gz &> /dev/null
rm -rf /var/www/html/*
cp -R website/* /var/www/html/
rm -rf website.tar.gz website
