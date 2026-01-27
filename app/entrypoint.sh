#!/bin/sh
set -e

if [ -z "$WEB_REPO_URL" ]; then
  echo "WEB_REPO_URL nicht gesetzt"
  exit 1
fi

rm -rf /usr/share/nginx/html/*
git clone "$WEB_REPO_URL" /usr/share/nginx/html

if [ ! -f /usr/share/nginx/html/index.html ]; then
  echo "index.html fehlt im Web-Repository"
  exit 1
fi

CONTAINER_ID=$(hostname)
sed -i "s/{{CONTAINER_ID}}/$CONTAINER_ID/g" /usr/share/nginx/html/index.html

nginx -g "daemon off;"


