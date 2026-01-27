#!/bin/sh


set -e
# Script bricht bei jedem Fehler sofort ab

if [ -z "$WEB_REPO_URL" ]; then
  # Prüft ob Repo-URL gesetzt ist
  echo "WEB_REPO_URL nicht gesetzt"
  exit 1
fi

rm -rf /usr/share/nginx/html/*
# Löscht alten Web-Content

git clone "$WEB_REPO_URL" /usr/share/nginx/html
# Klont Web-Repository in NGINX-Root

if [ ! -f /usr/share/nginx/html/index.html ]; then
  # Prüft ob index.html existiert
  echo "index.html fehlt im Web-Repository"
  exit 1
fi

CONTAINER_ID=$(hostname)
# Holt Container-ID / Hostname

sed -i "s/{{CONTAINER_ID}}/$CONTAINER_ID/g" /usr/share/nginx/html/index.html
# Ersetzt Platzhalter mit Container-ID

nginx -g "daemon off;"
# Startet NGINX im Vordergrund


