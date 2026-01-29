# Basis-Image: NGINX mit Alpine Linux (leichtgewichtig)
FROM nginx:alpine

# Installiert git und bash (ohne Cache für kleines Image)
RUN apk add --no-cache git bash

# Eigene NGINX-Konfiguration ins Image kopieren
COPY nginx.conf /etc/nginx/nginx.conf

# Entrypoint-Skript ins Image kopieren
COPY entrypoint.sh /entrypoint.sh

# Entrypoint-Skript ausführbar machen
RUN chmod +x /entrypoint.sh

# --- Security ---
# Erstellt einen non-root User für sicheren Containerbetrieb
RUN adduser -D nginxuser

# Container läuft nicht mehr als root
USER nginxuser

# Healthcheck: prüft alle 10s ob /health erreichbar ist
HEALTHCHECK --interval=10s --timeout=2s \
  CMD wget -qO- http://127.0.0.1/health || exit 1

# Startpunkt des Containers (führt entrypoint.sh aus)
ENTRYPOINT ["/entrypoint.sh"]


