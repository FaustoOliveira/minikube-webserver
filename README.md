# minikube-webserver

Dieses Projekt demonstriert eine vollständige lokale Kubernetes-Infrastruktur mit:

- dynamischem Webserver
- externem Load Balancer
- HTTPS
- Healthchecks
- Failover
- Git-basiertem Content

Das Projekt besteht aus **zwei Repositories**:

1. Infrastruktur-Repo (dieses Projekt)
2. Öffentliches HTML-Repo (Webinhalt)

Die Webseite wird beim Containerstart automatisch aus dem Git-Repo geladen.

TLS-Zertifikate werden **lokal erzeugt** und sind **nicht Bestandteil des Git-Repositories**.

-------------------------------------------------------------------------------------------------------------------------

| Technologie  | Begründung                               |
| ------------ | ---------------------------------------- |
| **Docker**   | Standard für Container                   |
| **Minikube** | Lokales Kubernetes für Tests             |
| **NGINX**    | Leichtgewichtiger Webserver              |
| **HAProxy**  | Load Balancer mit Healthchecks           |
| **Git**      | Dynamischer Webseiteninhalt              |
| **OpenSSL**  | Self-signed HTTPS                        |
| **Bash**     | Automatisierung                          |

-------------------------------------------------------------------------------------------------------------------------

# Gesamtidee

```css
Browser (https)
   ↓
HAProxy Load Balancer (Round-Robin + Healthcheck)
   ↓
Webserver Pod 1 → HTML aus Git-Repo
   ↓
Webserver Pod 2 → HTML aus Git-Repo
```

Minikube: lokales Kubernetes  
Docker-Image: Webserver + Git Clone Logik  
ENV Variable: Git-Repo URL  
Healthchecks: Container + HAProxy  
Load Balancer: außerhalb von Kubernetes Services  
HTTPS: self-signed Zertifikat

-------------------------------------------------------------------------------------------------------------------------

# Projektstruktur – minikube-webserver

```
minikube-webserver/
├── app/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── nginx.conf
│
├── haproxy/
│   ├── Dockerfile
│   ├── haproxy.cfg
│   └── certs/        # lokal erzeugt (nicht im Repo)
│
├── k8s/
│   ├── web-deployment.yaml
│   ├── web-headless-service.yaml
│   ├── haproxy-deployment.yaml
│   └── haproxy-service.yaml
│
├── .gitignore
└── README.md
```

-------------------------------------------------------------------------------------------------------------------------

# Schritt 1 – Voraussetzungen installieren

Docker  
https://docs.docker.com/get-docker/

Minikube  
https://minikube.sigs.k8s.io/docs/start/

kubectl  
https://kubernetes.io/docs/tasks/tools/

Test:

```
docker --version
minikube version
kubectl version --client
```

-------------------------------------------------------------------------------------------------------------------------

# Schritt 2 – Minikube starten

```bash
minikube start --driver=docker
```

-------------------------------------------------------------------------------------------------------------------------

# Schritt 3 – HTML Repository erstellen

Beispiel:

```
simple-webpage/
└── index.html
```

```html
<!DOCTYPE html>
<html>
<body>
<h1>Hallo Kubernetes 👋</h1>
<p>Antwort von Container: {{CONTAINER_ID}}</p>
</body>
</html>
```

Repo-URL merken.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 4 – Zertifikat erzeugen

Im Ordner `haproxy/certs`:

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
cat cert.pem key.pem > fullchain.pem
```

Zertifikatswarnung ist normal (self-signed)

-------------------------------------------------------------------------------------------------------------------------

# Schritt 5 – Docker auf Minikube umstellen

```bash
eval $(minikube docker-env)
```

Sehr wichtig — sonst sieht Kubernetes die Images nicht.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 6 – Images bauen

Webserver:

```bash
docker build -t webserver ./app
```

HAProxy:

```bash
docker build -t haproxy-lb ./haproxy
```

-------------------------------------------------------------------------------------------------------------------------

# Schritt 7 – Kubernetes deployen

```bash
kubectl apply -f k8s/
```

Status prüfen:

```bash
kubectl get pods
kubectl get svc
```

-------------------------------------------------------------------------------------------------------------------------

# Zugriff

```bash
minikube ip
```

Im Browser:

```bash
https://<MINIKUBE-IP>:30443
```

Zertifikatswarnung ignorieren (self-signed).

-------------------------------------------------------------------------------------------------------------------------

# Funktionstest

Pod löschen:

```bash
kubectl delete pod -l app=web
```

Die Webseite bleibt erreichbar → Failover funktioniert.

-------------------------------------------------------------------------------------------------------------------------

# Reset

Cluster löschen:

```bash
minikube delete
```

Code bleibt erhalten.

-------------------------------------------------------------------------------------------------------------------------

# Wiederherstellung

```bash
minikube start
eval $(minikube docker-env)

docker build -t webserver ./app
docker build -t haproxy-lb ./haproxy

kubectl apply -f k8s/
```

-------------------------------------------------------------------------------------------------------------------------

# Sicherheitsaspekte

- Minimales Container-Image reduziert Angriffsfläche
- Fail-fast Startlogik verhindert instabile Zustände
- Healthchecks überwachen Containerzustand
- Keine Secrets im Repository gespeichert
- TLS-Zertifikate bleiben lokal
- Klare Trennung zwischen Webserver und Load Balancer

-------------------------------------------------------------------------------------------------------------------------

# Ziel

Dieses Projekt demonstriert:

- Kubernetes zur Verwaltung mehrerer Webserver
- Externes Load Balancing
- HTTPS Absicherung
- Healthchecks zur Stabilitätsüberwachung
- Automatisches Failover bei Container-Ausfall
- Dynamische Inhalte aus einem Git-Repository

-------------------------------------------------------------------------------------------------------------------------

Autor: Fausto Oliveira

