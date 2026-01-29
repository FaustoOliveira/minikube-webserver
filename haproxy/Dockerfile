# --------------------------------------------------
# HAProxy Docker Image
# TLS Load Balancer für Kubernetes Webserver Pods
# --------------------------------------------------

FROM haproxy:alpine
# Leichtgewichtiges HAProxy Basis-Image

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
# Eigene Load Balancer Konfiguration

COPY certs/fullchain.pem /usr/local/etc/haproxy/certs/fullchain.pem
# TLS Zertifikat für HTTPS Termination


