# minikube-webserver

Dieses Projekt demonstriert den Aufbau einer lokalen, hochverfügbaren Kubernetes-Infrastruktur, 
in der klar getrennte Komponenten zusammenarbeiten:


Kubernetes übernimmt die Orchestrierung der Container sowie automatisches Self-Healing bei Ausfällen.

NGINX-Webserver liefern statische Inhalte aus, die dynamisch aus einem Git-Repository geladen werden.

HAProxy dient als TLS-terminierender Load Balancer und verteilt den Traffic per Round-Robin auf mehrere Instanzen.

Health Checks ermöglichen eine kontinuierliche Zustandsüberwachung der Container.

Ein automatisches Failover verhindert Downtime, indem Requests nur an gesunde Pods geleitet werden.

HTTPS-Verschlüsselung schützt die Kommunikation zwischen Client und Plattform.




# Das Projekt besteht aus **zwei Repositories**:

1. Infrastruktur-Repo (dieses Projekt)

   → Enthält alle Konfigurationen für Kubernetes, Docker sowie den Load Balancer.

2. Öffentliches HTML-Repo (Webinhalt)

   → Beinhaltet den statischen Webseiteninhalt, der beim Start eines Containers automatisch geklont wird.

---
**Dynamischer Webseiteninhalt**

Beim Start führt jeder Webserver folgende Schritte aus:

- Klonen des Git-Repositories

- Validieren der enthaltenen index.html

- Starten des NGINX-Webservers

Dadurch können Änderungen an der Webseite sofort bereitgestellt werden.

---

TLS-Zertifikate werden **lokal erzeugt** und sind **nicht Bestandteil des Git-Repositories**.

Grund:
Private Schlüssel sollten niemals versioniert werden, um Sicherheitsrisiken zu vermeiden.

Diese Trennung ermöglicht es, 
Webinhalte unabhängig von der Infrastruktur zu aktualisieren ohne ein neues Container-Image bauen zu müssen.

-------------------------------------------------------------------------------------------------------------------------

| Technologie  | Zweck                                                |
| ------------ | ---------------------------------------------------- |
| **Docker**   | Containerisierung der Anwendungen                    |
| **Minikube** | Lokale Kubernetes-Umgebung für Entwicklung und Tests |
| **NGINX**    | Schlanker und performanter Webserver                 |
| **HAProxy**  | Load Balancer mit integrierten Health Checks         |
| **Git**      | Bereitstellung dynamischer Webseiteninhalte          |
| **OpenSSL**  | Erstellung selbstsignierter TLS-Zertifikate          |
| **Bash**     | Automatisierung von Container-Startprozessen         |


-------------------------------------------------------------------------------------------------------------------------

# Gesamtidee & Architektur

Die folgende Übersicht zeigt den kompletten Weg einer Anfrage — vom Browser bis zum Webserver:

```css
Browser (HTTPS)
   ↓
NodePort Service (Port 30443)
   ↓
HAProxy Pod
(TLS-Terminierung + Load Balancing)
   ↓
Headless Service
(DNS-basierte Pod-Erkennung)
   ↓
Webserver Pods
(NGINX + Git-basierter Content)

```

Was passiert hier Schritt für Schritt?

1️⃣ Der Browser stellt eine HTTPS-Verbindung zum Kubernetes-Cluster her.

2️⃣ Der NodePort Service macht den internen HAProxy von außen erreichbar (Port 30443).

3️⃣ HAProxy übernimmt zwei Aufgaben:

Entschlüsselung der HTTPS-Verbindung (TLS-Terminierung)

Gleichmäßige Verteilung der Anfragen auf mehrere Webserver (Round-Robin)

4️⃣ Über den Headless Service erhält HAProxy automatisch eine Liste aller aktiven Webserver-Pods via DNS.

5️⃣ Die Webserver Pods liefern die Webseite aus, deren Inhalte beim Start aus einem Git-Repository geladen werden.




Rolle der einzelnen Komponenten

**Minikube**
Stellt eine lokale Kubernetes-Umgebung für Entwicklung und Tests bereit.

**Docker-Image (Webserver)**
Enthält NGINX sowie die Logik zum Klonen des Webseiten-Repositories.

**Environment Variable (WEB_REPO_URL)**
Definiert, aus welchem Git-Repository der Webseiteninhalt geladen wird.

**Health Checks**
Überwachen kontinuierlich die Erreichbarkeit der Container und steuern das Failover.

**Load Balancer (HAProxy)**
Läuft als Kubernetes Pod und verteilt den Traffic zuverlässig auf gesunde Webserver.

**HTTPS (Self-Signed Zertifikat)**
Sichert die Kommunikation zwischen Browser und Plattform.

-------------------------------------------------------------------------------------------------------------------------

# Projektstruktur – minikube-webserver

```
minikube-webserver/
├── app/                         # Webserver Container
│   ├── Dockerfile               # Baut den NGINX-Webserver
│   ├── entrypoint.sh            # Klont Git-Repo & startet NGINX
│   └── nginx.conf               # NGINX Konfiguration + Health Endpoint
│
├── haproxy/                     # Load Balancer Container
│   ├── Dockerfile               # Baut HAProxy Image
│   ├── haproxy.cfg              # TLS + Loadbalancing + Healthchecks
│   └── certs/                   # Lokale TLS-Zertifikate (nicht versioniert)
│
├── k8s/                         # Kubernetes Ressourcen
│   ├── web-deployment.yaml      # Deployment der Webserver Pods
│   ├── web-headless-service.yaml# DNS-basierte Pod-Erkennung
│   ├── haproxy-deployment.yaml  # Deployment des Load Balancers
│   └── haproxy-service.yaml     # NodePort Service (externer Zugriff)
│
├── .gitignore                   # Schließt Zertifikate & lokale Dateien aus
└── README.md                    # Projekt-Dokumentation & Anleitung
```

-------------------------------------------------------------------------------------------------------------------------

# Schritt 1 – Voraussetzungen installieren

Bitte installiere folgende Tools:

- Docker  
https://docs.docker.com/get-docker/

- Minikube  
https://minikube.sigs.k8s.io/docs/start/

- kubectl  
https://kubernetes.io/docs/tasks/tools/

Installation prüfen:

```
docker --version
minikube version
kubectl version --client
```

Wenn alle Befehle eine Version anzeigen, bist du bereit.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 2 – Minikube starten

Starte nun dein lokales Kubernetes-Cluster:

```bash
minikube start --driver=docker
```
Dieser Schritt erstellt eine lokale Kubernetes-Umgebung auf deinem Rechner.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 3 – HTML Repository erstellen

Erstelle ein separates öffentliches Git-Repository für den Webseiteninhalt.

Beispiel index.html:

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

Die Platzhalter-Variable {{CONTAINER_ID}} wird beim Start automatisch ersetzt.

Merke dir die Repository-URL, sie wird später verwendet.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 4 – Zertifikat erzeugen

Wechsle in den Ordner ``haproxy/certs`` und erstelle ein Self-Signed Zertifikat:

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
cat cert.pem key.pem > fullchain.pem
```

ℹ️ Eine Zertifikatswarnung im Browser ist normal, da es sich um ein selbstsigniertes Zertifikat handelt. (self-signed)

-------------------------------------------------------------------------------------------------------------------------

# Schritt 5 – Docker auf Minikube umstellen

Damit Kubernetes deine lokal gebauten Docker Images nutzen kann, führe aus:

```bash
eval $(minikube docker-env)
```

Sehr wichtig:
Dieser Schritt wird häufig vergessen und führt sonst zu ErrImageNeverPull.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 6 – Images bauen

Webserver Image bauen:

```bash
docker build -t webserver ./app
```

HAProxy Image bauen:

```bash
docker build -t haproxy-lb ./haproxy
```

Beide Images werden jetzt direkt in der Minikube-Umgebung erstellt.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 7 – Kubernetes deployen

Starte alle Kubernetes-Komponenten:

```bash
kubectl apply -f k8s/
```

Status prüfen:

```bash
kubectl get pods
kubectl get svc
```
Warte, bis alle Pods den Status Running haben.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 8 – Zugriff auf die Anwendung

Ermittle die IP-Adresse von Minikube:

```bash
minikube ip
```

Im Browser:

```bash
https://<MINIKUBE-IP>:30443
```

Die HTTPS-Warnung kannst du ignorieren (Self-Signed Zertifikat).

-------------------------------------------------------------------------------------------------------------------------

# Schritt 9 – Funktion testen (Failover)

Lösche einen Webserver Pod:

```bash
kubectl delete pod -l app=web
```

Ergebnis:

Kubernetes startet automatisch einen neuen Pod

HAProxy leitet Traffic nur an gesunde Pods

Die Webseite bleibt erreichbar

✅ Failover funktioniert.

-------------------------------------------------------------------------------------------------------------------------

# Schritt 10 – Cluster zurücksetzen (optional)

Cluster löschen:

```bash
minikube delete
```

Der Code bleibt dabei erhalten.

-------------------------------------------------------------------------------------------------------------------------

# Wiederherstellung nach Reset

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

# Sicherheitsaspekte

Dieses Projekt berücksichtigt mehrere grundlegende Sicherheitsmaßnahmen:

- Minimalistische Container-Images reduzieren die Angriffsfläche
- Fail-fast Startlogik verhindert instabile Containerzustände
- Health Checks überwachen den Zustand der Anwendungen
- Keine Secrets oder privaten Schlüssel im Repository
- TLS-Zertifikate werden ausschließlich lokal erzeugt
- Klare Trennung zwischen Webserver und Load Balancer

---

Dieses Projekt demonstriert:

- Kubernetes zur Verwaltung mehrerer Webserver
- Einen externen Load-Balancer als Pod
- HTTPS-Absicherung
- Healthchecks zur Stabilitätsüberwachung
- Automatisches Failover bei Container-Ausfall
- Dynamische Inhalte aus einem Git-Repository

-------------------------------------------------------------------------------------------------------------------------



# Troubleshooting

ErrImageNeverPull
→ Docker images im Minikube bauen:

```bash
eval $(minikube docker-env)
```

Pods stuck in CrashLoopBackOff
→ Logs prüfen:

```bash
kubectl logs <pod>
```

Cluster reset:

```bash
minikube delete
```

-------------------------------------------------------------------------------------------------------------------------

Autor: Fausto Oliveira

