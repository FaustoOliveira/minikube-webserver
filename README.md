# minikube-webserver


Das Projekt besteht aus zwei Repositories:

Das Haupt-Repository enthält die Infrastruktur (Docker, Kubernetes, HAProxy).

Die Webseite selbst liegt in einem separaten öffentlichen Repository und wird beim Start der Container aus diesem geladen.


Die TLS-Zertifikate werden lokal erzeugt und sind nicht Bestandteil des Git-Repositories.
Sie sind in .gitignore ausgeschlossen und werden nur lokal für Minikube verwendet.

-------------------------------------------------------------------------------------------------------------------------




| Technologie  | Begründung                               |
| ------------ | ---------------------------------------- |
| **Docker**   | Standard für Container                   |
| **Minikube** | Einfaches lokales Kubernetes             |
| **NGINX**    | Leicht, sicher, stabil                   |
| **HAProxy**  | Perfekter Load-Balancer ohne K8S-Service |
| **Git**      | HTML-Seite wird dynamisch geladen        |
| **OpenSSL**  | Self-Signed HTTPS                        |
| **Bash**     | Automatisierung                          |


---------------------------------------------------------------------------------------------------------------------------

# Gesamtidee

```css
Browser (https)
   ↓
Load Balancer (NGINX, Round-Robin + Healthcheck)
   ↓
Container 1  ----> Webserver (HTML aus Git-Repo)
   ↓
Container 2  ----> Webserver (HTML aus Git-Repo)
```


Minikube: Lokales Kubernetes 

Docker-Image: Webserver + Logik zum Klonen eines Git-Repos

ENV Variable: Git-Repo-URL

Healthchecks: Kubernetes weiß, ob Container lebt

Load Balancer (NGINX): außerhalb von Kubernetes Services

HTTPS: self-signed Zertifikat

Sicherheit: non-root, minimal Image, ReadOnly FS


# Projektstruktur – minikube-webserver

```
minikube-webserver/
├── app/
│   ├── Dockerfile              # Webserver Image (nginx, non-root, minimal)
│   ├── entrypoint.sh           # Startskript: cloned HTML Repo + Start nginx
│   └── nginx.conf              # nginx Konfiguration inkl. Health Endpoint
│
├── haproxy/
│   ├── Dockerfile              # HAProxy Image mit SSL
│   ├── haproxy.cfg             # HAProxy Config (Round-Robin + Healthchecks)
│   └── certs/
│       ├── cert.pem            # Self-signed Zertifikat
│       └── key.pem             # Private Key
│
├── k8s/
│   ├── web-deployment.yaml     # Deployment für Webserver (replicas >= 2)
│   ├── web-headless-service.yaml # Headless Service für direkte Pod-Erreichbarkeit
│   ├── haproxy-deployment.yaml # Deployment für HAProxy
│   └── haproxy-service.yaml    # Service für externen Zugriff (NodePort)
│
├── .gitignore
└── README.md                   # Projektbeschreibung & Anleitung
```





# Schritt 1 – Voraussetzungen installieren

# Docker
https://docs.docker.com/get-docker/

# Minikube
https://minikube.sigs.k8s.io/docs/start/

# kubectl
https://kubernetes.io/docs/tasks/tools/


# Testen
``
docker --version
minikube version
kubectl version --client``

# Schritt 2 – Minikube starten

```bash
minikube start --driver=docker
```

# Schritt 3 – HTML Repository erstellen

Erstelle ein separates öffentliches Git-Repo, z. B.:

```
simple-webpage/
└── index.html 
```

index.html

```html
<!DOCTYPE html>
<html>
<head>
    <title>Minikube Demo</title>
</head>
<body>
    <h1>Hallo von Kubernetes 👋</h1>
    <p>Antwort von Container: <strong>{{CONTAINER_ID}}</strong></p>
</body>
</html>
```
Repo-URL merken (z. B. https://github.com/deinname/simple-webpage.git)

---------------------------------------------------------------------------------------------

# Schritt 4 app/Dockerfile erstellen – Webserver Docker-Image  

```
FROM nginx:alpine

RUN apk add --no-cache git bash

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=10s --timeout=2s \
  CMD wget -qO- http://127.0.0.1/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]

```

----------------------------------------------------------------------

# app/entrypoint.sh erstellen 

```bash
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
```

---------------------------------------------------------------------------------

# app/nginx.conf erstellen 

```nginx
events {}

http {

    server {
        

        listen 80;

        location /health {
            return 200 "OK";
        }

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
```
-------------------------------------------------------------------------------------

# Schritt 5 – HAProxy Load-Balancer (HTTPS)

Zertifikat erzeugen

openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
cat cert.pem key.pem > cert.pem

-------------------------------------------------------------------------------------
#  haproxy/haproxy.cfg erstellen 
```
global
    log stdout format raw local0
    maxconn 256

defaults
    log global
    mode http
    option httplog
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend https_front
    mode http
    bind *:8443 ssl crt /usr/local/etc/haproxy/certs/fullchain.pem
    default_backend web_back


backend web_back
    mode http
    balance roundrobin
    option httpchk GET /health
    server-template web 2 webserver-headless.default.svc.cluster.local:80 check
```
-------------------------------------------------------------------------------------

# Schritt 6 k8s/web-deployment.yaml  erstellen – Kubernetes Deployment (2 Instanzen)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver
spec:
  replicas: 2                 
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web               
    spec:
      containers:
        - name: web
          image: webserver:latest
          imagePullPolicy: Never   
          env:
            - name: WEB_REPO_URL
              value: "https://github.com/FaustoOliveira/minikube-webpage.git"
              # Git-Repo für Web-Inhalt
          ports:
            - containerPort: 80     # HTTP-Port des Webservers
```
------------------------------------------------------------------------------------------

# k8s/web-headless-service.yaml 

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webserver-headless
spec:
  clusterIP: None        
  selector:
    app: web              
  ports:
    - port: 80             
      targetPort: 80      
```

-------------------------------------------------------------------------------------------

# haproxy-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy
spec:
  replicas: 1              
  selector:
    matchLabels:
      app: haproxy
  template:
    metadata:
      labels:
        app: haproxy        
    spec:
      containers:
        - name: haproxy
          image: haproxy-lb:latest
          imagePullPolicy: Never  
          ports:
            - containerPort: 8443 
```
----------------------------------------------------------------------------------------------

# haproxy-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: haproxy
spec:
  type: NodePort          
  selector:
    app: haproxy         
  ports:
    - name: https
      port: 443           
      targetPort: 443    
      nodePort: 30443    
```
--------------------------------------------------------------------------------------------

# Schritt 7 – Build & Start
```bash
eval $(minikube docker-env)
docker build -t webserver ./app
kubectl apply -f k8s/
```
---------------------------------------------------------------------------------------------

Zugriff:

```
minikube ip
```
Browser:

https://<MINIKUBE-IP>:30443


------------------------------------------------------------------------------------------



```minikube delete
``` 

löscht:

-  alle Pods
    
-  alle Deployments & Services
    
-  alle Images **im Minikube-Docker**
    
-  den ganzen Cluster
    

**Dein Code, YAMLs, Dockerfiles sind noch da**  
Kubernetes-Zustand ist nur leer

--------------------------------------------------------------------------------------------

# Ziel

Am Ende erreichst du wieder:

https://<minikube-ip>:30443

---------------------------------------------------------------------------------------------

SCHRITT-FÜR-SCHRITT WIEDERHERSTELLUNG

# 1  Minikube starten

```minikube start
```

Prüfen:

```kubectl get pods
```
# → No resources found (OK!)

---------------------------------------------------------------------------------------------

# 2 Docker auf Minikube umstellen (SEHR WICHTIG)

```eval $(minikube docker-env)
```

---------------------------------------------------------------------------------------------

# 3 Images neu bauen

Webserver

```docker build -t webserver ./app
```

HAProxy

```docker build -t haproxy-lb ./haproxy
```


Prüfen:

```docker images | grep -E "webserver|haproxy"
```

---------------------------------------------------------------------------------------------

# 4 Kubernetes-Objekte deployen

Einfach **alles auf einmal**:

```kubectl apply -f k8s/
```

Du solltest sehen:

deployment.apps/webserver created
deployment.apps/haproxy created
service/webserver-headless created
service/haproxy created

-----------------------------------------------------------------------------------------------

# 5 Status prüfen

```bash
kubectl get pods
kubectl get svc
```

Erwartet:

webserver   1/1 Running (2x)
haproxy     1/1 Running

haproxy   NodePort   443:30443/TCP

----------------------------------------------------------------------------------------------

# 6 Zugriff im Browser

```minikube ip
```

Dann: 

https://<MINIKUBE-IP>:30443

Zertifikatswarnung → **Erweitert → Trotzdem fortfahren**

-----------------------------------------------------------------------------------------------

# 7 Funktionstest (optional, aber gut)

```kubectl delete pod -l app=web
```

