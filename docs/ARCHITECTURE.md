# Documentation d'Architecture du Projet Eloquence (POC/MVP)

## 1. Vue d'ensemble du Projet

Ce document décrit l'architecture technique du projet Eloquence, un système de communication en temps réel axé sur la synthèse et la reconnaissance vocale intelligente. L'objectif principal est de permettre des interactions vocales fluides entre les utilisateurs et un agent conversationnel basé sur l'IA, en utilisant des technologies de pointe pour le traitement audio, la synthèse vocale (TTS) et la reconnaissance vocale (STT). Le projet est conteneurisé avec Docker Compose pour faciliter le déploiement et la gestion des différents services.

## 2. Architecture Générale

L'architecture est micro-services, orchestrée via Docker Compose. Chaque composant est un conteneur Docker distinct, communiquant via un réseau Docker interne. Le système est centré autour de LiveKit pour la gestion des sessions audio en temps réel, de Redis pour la persistance des données et la coordination, et de divers services Python pour le traitement de l'IA (STT, TTS, agent conversationnel).

```mermaid
graph TD
    User --> Frontend (Application Client)
    Frontend --> LiveKit (WebRTC/Audio/Video)
    LiveKit <--> eloquence-agent-v1 (Agent Vocal IA)
    eloquence-agent-v1 --> whisper-stt (Speech-to-Text)
    eloquence-agent-v1 --> openai-tts (Text-to-Speech)
    eloquence-agent-v1 --> api-backend (Proxy Mistral/LLM)
    api-backend --> Mistral (LLM Externe)
    eloquence-agent-v1 --> redis (Cache/Coordination)
    api-backend --> redis
    livekit --> redis
```

## 3. Détails des Composants

### 3.1. `redis`

*   **Rôle :** Base de données in-memory clé-valeur. Utilisé pour la mise en cache, la gestion des sessions et la coordination entre les services, notamment pour LiveKit.
*   **Technologie :** Redis 7 (alpine).
*   **Ports :** `6379` (interne et exposé).
*   **Ressources allouées :** Limite de 512MB, réservation de 256MB.
*   **Dépendances :** Aucune directe, mais d'autres services en dépendent.

### 3.2. `livekit`

*   **Rôle :** Serveur WebRTC pour la gestion des sessions audio/vidéo en temps réel. Il sert de point d'entrée pour les clients (frontend) et communique avec l'agent via son SDK.
*   **Technologie :** `livekit/livekit-server:v1.9.0`.
*   **Ports :** `7880` (WebRTC), `7881` (Monitoring), `50000-50019/udp` (flux RTP).
*   **Ressources allouées :** Limite de 1GB, réservation de 512MB.
*   **Dépendances :** `redis` (pour la configuration et l'état).

### 3.3. `whisper-stt`

*   **Rôle :** Service de reconnaissance vocale (Speech-to-Text) basé sur un modèle Whisper optimisé (Faster-Whisper). Reçoit des flux audio et les transcrit en texte.
*   **Technologie :** Python, Faster-Whisper.
*   **Ports :** `8001`.
*   **Ressources allouées :** Limite de 16GB (pour les modèles), réservation de 8GB. Nécessite des ressources CPU élevées ou un GPU pour de meilleures performances.
*   **Dépendances :** Aucune, mais utilisé par `eloquence-agent-v1`.

### 3.4. `openai-tts`

*   **Rôle :** Proxy léger pour l'API de synthèse vocale (Text-to-Speech) d'OpenAI. Reçoit du texte et renvoie un flux audio.
*   **Technologie :** FastAPI (Python), uvicorn.
*   **Ports :** `5002`.
*   **Ressources allouées :** Limite de 1GB, réservation de 512MB.
*   **Dépendances :** Accès externe à l'API OpenAI (via `OPENAI_API_KEY`).

### 3.5. `api-backend`

*   **Rôle :** Backend principal du système, servant de proxy pour l'API Mistral (LLM) et intégrant potentiellement d'autres logiques métier ou API. Il centralise les appels vers des services IA externes.
*   **Technologie :** FastAPI (Python), uvicorn.
*   **Ports :** `8000`.
*   **Ressources allouées :** Limite de 2GB, réservation de 1GB.
*   **Dépendances :** `livekit`, `redis`, `whisper-stt`, `openai-tts`. Sa logique interne interagit avec l'API Mistral via des credentials.

### 3.6. `eloquence-agent-v1`

*   **Rôle :** L'agent vocal intelligent LiveKit. Il se connecte en tant que participant LiveKit, reçoit les flux audio des utilisateurs, les traite via STT, génère des réponses textuelles via l'API Mistral (via `api-backend`), et synthétise des réponses audio via OpenAI TTS. Il est le cœur conversationnel du système.
*   **Technologie :** Python, LiveKit Agents SDK.
*   **Ports :** `8080`.
*   **Ressources allouées :** Limite de 4GB, réservation de 2GB. Nécessite suffisamment de RAM pour les modèles et le traitement audio.
*   **Dépendances :** `livekit`, `redis`, `whisper-stt`, `openai-tts`. Utilise un script `wait-for-it.sh` pour assurer que LiveKit est démarré avant son propre lancement.

## 4. Flux de Données et Interactions

1.  **Connexion Client :** Un client (Frontend Flutter) se connecte à LiveKit pour établir une session audio/vidéo WebRTC.
2.  **Connexion Agent :** L'agent `eloquence-agent-v1` se connecte également à LiveKit en tant que participant.
3.  **Audio Réception (Client vers Agent) :** L'agent reçoit le flux audio de l'utilisateur via LiveKit.
4.  **STT (Agent) :** L'agent envoie le flux audio au service `whisper-stt` (local ou distant) pour transcription en texte.
5.  **Traitement (Agent & API Backend) :** Le texte transcrit est envoyé à l'agent. L'agent peut soit traiter directement le texte ou l'envoyer au `api-backend` qui fera une requête à l'API Mistral (LLM externe) pour générer une réponse.
6.  **TTS (Agent) :** La réponse textuelle de l'IA est envoyée au service `openai-tts` qui la convertit en flux audio.
7.  **Audio Diffusion (Agent vers Client) :** L'agent renvoie le flux audio synthétisé à LiveKit, qui le diffuse aux participants (l'utilisateur).

## 5. Technologies Clés

*   **Conteneurisation :** Docker, Docker Compose
*   **Orchestration Audio/Vidéo en Temps Réel :** LiveKit
*   **Base de Données In-Memory :** Redis
*   **Reconnaissance Vocale (STT) :** Whisper (via Faster-Whisper)
*   **Synthèse Vocale (TTS) :** OpenAI TTS API
*   **Modèles de Langage (LLM) :** Mistral API
*   **Backend / API :** Python, FastAPI, uvicorn
*   **Scripting :** Shell scripts (`.sh`) pour les utilitaires de démarrage

## 6. Déploiement et Environnement

Le projet est conçu pour être déployé facilement via Docker Compose.
Le fichier `docker-compose.yml` définit l'ensemble des services, leurs dépendances, leurs images (parfois construites à partir de Dockerfiles locaux), leurs ports exposés et leurs ressources allouées.

Les variables d'environnement (`LIVEKIT_URL`, `API_KEYS`, etc.) sont passées aux conteneurs pour leur configuration.

## 7. Points à Refactorer et Améliorer (pour les Futures Itérations)

1.  **Gestion des Variables d'Environnement :** Les clés API sont actuellement câblées dans `docker-compose.yml` (e.g., `OPENAI_API_KEY`, `MISTRAL_API_KEY`, `LIVEKIT_API_SECRET`). Pour la production, utiliser un fichier `.env` ou un système de gestion de secrets (ex: Docker Secrets, HashiCorp Vault).
2.  **Robustesse de l'Agent :**
    *   **Gestion des Erreurs :** Améliorer la gestion des erreurs dans `real_time_voice_agent_force_audio.py` pour mieux gérer les déconnexions de LiveKit ou les erreurs des services STT/TTS/LLM.
    *   **Reconnexion Automatique :** Implémenter une logique de reconnexion robuste à LiveKit et aux autres services en cas de perte de connexion.
    *   **Historique `Room.participants` :** L'erreur `AttributeError: 'Room' object has no attribute 'participants'` indique une incompatibilité ou un usage incorrect du SDK LiveKit v1.x. L'agent doit utiliser les événements LiveKit ("participantConnected", "participantDisconnected") pour maintenir une liste locale de participants si cette information est nécessaire, car `Room.participants` n'est plus une propriété directe ou n'est pas fiable en temps réel. Cela nécessite une refactorisation de la gestion des participants dans `real_time_voice_agent_force_audio.py`.
3.  **Performances et Optimisation des Ressources :**
    *   **Modèles STT/TTS :** Évaluer l'utilisation de modèles STT et TTS plus petits ou plus efficaces si les performances sont un goulot d'étranglement ou si les coûts sont trop élevés.
    *   **Mise à l'échelle :** Pour la production, envisager des stratégies de mise à l'échelle (ex: Kubernetes) au lieu de Docker Compose.
4.  **Logging et Monitoring :** Implémenter une solution centralisée pour les logs et le monitoring (ex: ELK stack, Prometheus/Grafana) pour une meilleure visibilité sur le comportement des services.
5.  **Sécurité :**
    *   Réviser les permissions des fichiers et répertoires dans les conteneurs.
    *   S'assurer que seuls les ports nécessaires sont exposés.
6.  **Tests :** Renforcer la suite de tests unitaires et d'intégration pour chaque service.
7.  **Documentation :** Poursuivre la documentation détaillée des flux de données, des API internes et de chaque module de code.

### 7.1. Nettoyage et Suppression des Fichiers Obsolètes/Temporaires

Pour maintenir un projet propre, léger et facile à naviguer, il est crucial de supprimer les fichiers non essentiels qui s'accumulent pendant le développement (logs, diagnostics, tests temporaires, configurations obsolètes, etc.). Voici une liste des types de fichiers et répertoires qui devraient être examinés pour suppression ou déplacement :

*   **Fichiers de diagnostic et de log :** Tous les fichiers se terminant par `.json`, `.log`, ou `.wav` qui sont des artefacts de diagnostics ou des logs temporaires (ex: `agent_diagnostic_report_*.json`, `diagnostic_*.log`, `full_logs.txt`, `temp_logs.txt`, `test_*.wav` générés).
*   **Scripts de test/débogage ponctuels :** Les scripts Python (`.py`) et shell (`.sh`, `.bat`) qui ont servi à des tests ou des diagnostics spécifiques et ne font pas partie de l'application principale ou des tests unitaires formels (ex: `diagnostic_*.py`, `fix_*.py`, `test_*.py`, `test_*.sh`, `update_agent_to_audio_fixed.py`, `android_connectivity_test.dart`, `flutter_diagnostic_code.dart`). Ces scripts peuvent être déplacés dans un répertoire `tools/` séparé si elles sont utiles pour le débogage futur de manière ponctuelle.
*   **Fichiers de configuration / Docker obsolètes :** Les fichiers `docker-compose` de sauvegarde, les configurations réseau temporaires ou les `.json` spécifiques à des étapes passées du développement (ex: `docker-compose.yml.backup_*`, `docker_compose_network_fix.yml`, `docker-config.json`, l'exécutable `docker-compose` à la racine).
*   **Anciennes documentations / READMEs à la racine :** Les fichiers Markdown (.md) qui sont des brouillons ou des versions obsolètes de la documentation et qui devraient être consolidés ou déplacés dans le répertoire `docs/` pour une organisation centralisée.
*   **Fichiers divers et temporaires :** Tout fichier qui ne correspond pas à la structure du projet final (ex: `cls`, `Eloquence`, `add_firewall_rules.bat`, `livekit.yaml` directement à la racine, etc.).

En outre, il est conseillé de nettoyer les caches Docker (`docker system prune -a`) régulièrement et de s'assurer que les volumes Docker obsolètes sont supprimés.

### 7.2. Anciens Backends et Sauvegardes

Le projet a subi des évolutions significatives, notamment le passage des services Piper TTS et Azure TTS à OpenAI TTS, ainsi que des refactorisations backend. Il est important de s'assurer que toutes les dépendances et les fichiers liés à des versions antérieures ou des services non utilisés sont complètement supprimés du projet.

**Points à vérifier et à supprimer :**
*   **Anciens Dockerfiles et contextes de build :** Tout `Dockerfile` lié à des services comme Piper TTS ou d'anciennes versions de l'agent qui ne sont plus utilisés.
*   **Répertoires de services obsolètes :** Si des services entiers (comme `services/piper-tts` ou d'anciens dossiers d'agents) ne sont plus actifs dans `docker-compose.yml`, leurs répertoires correspondants devraient être supprimés.
*   **Dépendances Python/Node.js non utilisées :** Vérifier les fichiers `requirements.txt` ou `package.json` de chaque service pour s'assurer qu'ils ne listent pas des bibliothèques dédiées à des fonctionnalités supprimées.
*   **Sauvegardes de code :** Les répertoires ou fichiers de code qui sont des sauvegardes manuelles ou des copies de travail temporaires (ex: `backup-migration-20250621/`, `docker-compose.yml.backup_*`). Ces sauvegardes devraient être gérées via un système de contrôle de version (Git) plutôt que stockées directement dans le dépôt.

Un audit régulier du dossier `services/` est recommandé pour identifier et éliminer les composants Docker qui ne sont plus nécessaires.