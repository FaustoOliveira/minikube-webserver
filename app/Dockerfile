FROM nginx:alpine
# Basis-Image: leichtgewichtiges NGINX

RUN apk add --no-cache git bash
# Installiert Git + Bash für Repo-Clone & Script

COPY nginx.conf /etc/nginx/nginx.conf
# Eigene NGINX-Konfiguration

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Startscript kopieren + ausführbar machen

RUN adduser -D nginxuser
# Non-root User für Sicherheit

RUN chown -R nginxuser:nginxuser /usr/share/nginx/html
# Schreibrechte für Web-Inhalte

RUN chown -R nginxuser:nginxuser /var/cache/nginx
# Schreibrechte für NGINX Cache

RUN chown -R nginxuser:nginxuser /run
# Schreibrechte für PID/Runtime

USER nginxuser
# Container läuft ohne Root-Rechte

HEALTHCHECK --interval=10s --timeout=2s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/health || exit 1
# Kubernetes prüft Container-Gesundheit

ENTRYPOINT ["/entrypoint.sh"]
# Startet Webserver über Script



# Kurz erklärt in einem Satz: Container klont Git-Content → startet NGINX → läuft sicher als Non-root → meldet Health Status.

