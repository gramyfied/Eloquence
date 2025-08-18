# Guide d’utilisation – Application Eloquence (Flutter)

## 1. Aperçu
Ce guide explique comment démarrer l’application, configurer le réseau (LiveKit, service de token), lancer les exercices et résoudre les problèmes courants.

## 2. Prérequis
- Flutter SDK installé (channel stable)
- Appareil Android (ou émulateur)
- Docker en local si vous utilisez LiveKit/HAProxy/Token service
- Accès au dépôt Git de l’application

## 3. Installation
1. Cloner le dépôt puis se placer dans le dossier Flutter:
   - `frontend/flutter_app/`
2. Installer les dépendances:
   - `flutter pub get`

## 4. Configuration de l’environnement (.env)
L’app lit les URLs/ports depuis un fichier `.env` (non versionné). Deux options:

- Option A (recommandée): générer automatiquement `.env` avec votre IP locale
  - PowerShell (depuis `frontend/flutter_app`):
    - `powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev.ps1`
  - Le script détecte l’IP locale et remplit:
    - `LIVEKIT_URL=ws://IP:8780`
    - `LIVEKIT_TOKEN_URL=http://IP:8804`
    - ...et autres services locaux

- Option B: manuel
  - Copier `env.example` vers `.env`
  - Remplacer `MOBILE_HOST_IP` et les URLs par votre IP: `192.168.1.X`

Notes:
- Le code évite les IP codées en dur. En debug, `localhost` est remplacé automatiquement par `MOBILE_HOST_IP` (appareil physique) ou `10.0.2.2` (émulateur Android).
- Vous pouvez ajuster les ports si vos services écoutent ailleurs.

## 5. Lancement
- `flutter run`
- L’app se lance, la navigation principale est gérée via GoRouter.

## 6. Utilisation
- Écran d’accueil → menu des exercices.
- Confidence Boost:
  - Sélectionner l’exercice « Confidence Boost Express »
  - L’app tentera d’obtenir un token via `LIVEKIT_TOKEN_URL` puis se connectera à `LIVEKIT_URL`.
- Studio Situations Pro:
  - Route `/preparation/:simulationType` pour la préparation (chat)
  - Route `/simulation/:simulationType` pour la simulation (LiveKit si activé)

## 7. Dépannage réseau
- Symptôme: Timeout lors de la génération de token ou connexion LiveKit.
  - Vérifier que les ports sont accessibles (PowerShell):
    - `Test-NetConnection IP -Port 8780` (LiveKit via HAProxy)
    - `Test-NetConnection IP -Port 8804` (token service)
  - Ouvrir les ports dans le pare-feu Windows si nécessaire.
  - Mettre à jour `.env` si votre IP locale a changé puis relancer l’app.

## 8. Questions fréquentes
- « Après un git pull, tout casse ? »
  - Non. `.env` reste local. Le code lit d’abord `.env` et remplace `localhost` intelligemment. En cas de nouvel environnement, (re)générez `.env` via le script.
- « Émulateur Android »
  - Utilisez l’alias `10.0.2.2` ou laissez le code effectuer la substitution. Pour appareil physique, renseignez `MOBILE_HOST_IP`.

## 9. Mise à jour du code
- Récupérer les changements: `git pull`
- Si votre IP a changé: relancer `scripts/setup-dev.ps1` pour régénérer `.env`.

## 10. Où modifier la config réseau dans le code
- `lib/core/config/network_config.dart`: centralise les URLs pour Studio/LiveKit et lit `.env`.
- `lib/core/config/app_config.dart`: remplace `localhost` par `MOBILE_HOST_IP`/`10.0.2.2` en debug.

## 11. Support
- Voir aussi `docs/dev-setup.md` pour le setup détaillé.
