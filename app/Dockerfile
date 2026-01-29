FROM nginx:alpine

RUN apk add --no-cache git bash

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN adduser -D nginxuser

# NOTE: Rechte für Webroot
RUN chown -R nginxuser:nginxuser /usr/share/nginx/html

# NOTE: Rechte für nginx Cache
RUN chown -R nginxuser:nginxuser /var/cache/nginx

# NOTE: Rechte für nginx PID
RUN chown -R nginxuser:nginxuser /run

USER nginxuser

HEALTHCHECK --interval=10s --timeout=2s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]


HEALTHCHECK --interval=10s --timeout=2s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/health || exit 1


ENTRYPOINT ["/entrypoint.sh"]




