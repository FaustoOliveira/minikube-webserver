FROM nginx:alpine

RUN apk add --no-cache git bash

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=10s --timeout=2s \
  CMD wget -qO- http://127.0.0.1/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]

