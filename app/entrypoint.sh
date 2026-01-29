#!/bin/sh

set -e
# NOTE: Script stoppt bei Fehlern

if [ -z "$WEB_REPO_URL" ]; then
  echo "WEB_REPO_URL nicht gesetzt"
  exit 1
fi

# NOTE: löscht alten Web-Content (ignoriert Permission Fehler)
rm -rf /usr/share/nginx/html/* || true

git clone "$WEB_REPO_URL" /usr/share/nginx/html

if [ ! -f /usr/share/nginx/html/index.html ]; then
  echo "index.html fehlt im Web-Repository"
  exit 1
fi

CONTAINER_ID=$(hostname)
# NOTE: ersetzt Platzhalter mit Container-ID
sed -i "s/{{CONTAINER_ID}}/$CONTAINER_ID/g" /usr/share/nginx/html/index.html

# NOTE: startet nginx im Vordergrund
nginx -g "daemon off;"


# --------------------------------------------------
# entrypoint.sh
#
# Dieses Script:
# - lädt Webseiteninhalt aus einem Git-Repository
# - validiert die Dateien
# - ersetzt Container-ID im HTML
# - startet NGINX
# - bricht bei Fehlern sofort ab
#
# Ziel:
# Dynamische Inhalte + sichere Startlogik
# --------------------------------------------------
