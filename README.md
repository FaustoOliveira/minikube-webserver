# minikube-webserver


Das Projekt besteht aus zwei Repositories:

Das Haupt-Repository enthält die Infrastruktur (Docker, Kubernetes, HAProxy).

Die Webseite selbst liegt in einem separaten öffentlichen Repository und wird beim Start der Container aus diesem geladen.


Die TLS-Zertifikate werden lokal erzeugt und sind nicht Bestandteil des Git-Repositories.
Sie sind in .gitignore ausgeschlossen und werden nur lokal für Minikube verwendet.

