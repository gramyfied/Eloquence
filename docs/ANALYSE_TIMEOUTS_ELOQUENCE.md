# Analyse et Résolution des Timeouts dans l'Application Eloquence

## Introduction

Ce document détaille l'analyse des timeouts persistants et de la lenteur d'analyse au sein de l'application Eloquence, spécifiquement en ce qui concerne l'analyse de confiance côté backend et la connexion LiveKit. Ces problèmes impactent directement l'expérience utilisateur, malgré les ajustements déjà effectués sur les seuils de timeout. L'objectif est d'identifier la cause première et de proposer des solutions concrètes pour optimiser les performances.

## Contexte Actuel des Timeouts

Des timeouts sont observés sur deux fronts principaux : l'analyse backend de confiance et la connexion LiveKit. Pour tenter d'atténuer ces problèmes, les configurations suivantes ont été apportées dans [`frontend/flutter_app/lib/features/confidence_boost/presentation/providers/confidence_boost_provider.dart`](frontend/flutter_app/lib/features/confidence_boost/presentation/providers/confidence_boost_provider.dart):

*   **Timeout global des analyses parallèles**: 35 secondes
*   **Timeout des tentatives d'analyse individuelles**: 32 secondes
*   **Timeout spécifique pour l'analyse backend** (`ConfidenceAnalysisBackendService.analyzeAudioRecording`): 30 secondes

Malgré ces ajustements, les utilisateurs rencontrent toujours des `TimeoutException` pour l'analyse backend et LiveKit, et le mécanisme de fallback s'active fréquemment, indiquant une persistance du problème sous-jacent.

## Architecture de l'Application

L'application Eloquence repose sur une architecture distribuée :

*   **Frontend**: Application Flutter.
*   **Backend**: Services Python (Flask/FastAPI, Whisper-realtime, Mistral) conteneurisés via Docker Compose.
*   **Connectivité**: Des défis récurrents ont été relevés et résolus par la détection dynamique de l'IP pour `localhost` et l'utilisation d'un `fileProvider` pour les `MultipartFile`.

## Objectifs de l'Analyse

Notre démarche d'analyse vise à :

1.  **Analyser les logs détaillés** (Flutter, Python backend, LiveKit) afin d'identifier la cause exacte des timeouts.
2.  **Déterminer l'origine de la lenteur**: Est-elle due au traitement côté Flutter, à des problèmes réseau, aux performances du backend Python (Flask/FastAPI), ou aux services d'intelligence artificielle (Whisper/Mistral ou tout autre service appelé par le backend) ?
3.  **Proposer des solutions concrètes** pour réduire la latence et éliminer les timeouts. Cela inclura des optimisations côté client (Flutter) et côté serveur (Docker, configurations de service, optimisation du code Python).
4.  **Valider la solution proposée** par des tests rigoureux et l'observation des métriques de performance.

## Causes Potentielles des Timeouts (Hypothèses)

Plusieurs sources peuvent être à l'origine de ces timeouts persistants :

1.  **Latence réseau**: Des connexions instables ou lentes entre le frontend Flutter et le backend, surtout en environnement mobile.
2.  **Performance du backend Python**:
    *   **Problèmes de Gunicorn/Workers**: Un nombre insuffisant de workers ou une mauvaise configuration de Gunicorn/Uvicorn pour gérer les requêtes concurrentes.
    *   **Goulot d'étranglement dans le code**: Code non optimisé dans Flask/FastAPI, en particulier lors du traitement des fichiers audio ou de la coordination des services IA.
    *   **Fuites de mémoire**: Accumulation de mémoire qui ralentit le service au fil du temps.
3.  **Performance des services IA (Whisper/Mistral)**:
    *   **Modèles trop lourds**: Exécution de modèles d'IA trop exigeants en ressources ou en temps sur l'infrastructure actuelle.
    *   **Sous-dimensionnement des ressources**: Manque de CPU/GPU alloué aux conteneurs IA.
    *   **Dépendances externes**: Latence ou indisponibilité des services externes appelés par les modèles IA.
4.  **Configuration Docker / Conteneurisation**:
    *   **Mauvaise gestion des ressources**: Allouer trop peu de CPU/mémoire aux conteneurs du backend ou des services IA.
    *   **Problèmes de réseau interne Docker**: Latence de communication entre les conteneurs au sein du réseau Docker Compose.
    *   **Temps de démarrage des conteneurs**: Si des conteneurs sont souvent redémarrés ou mis en veille, leur temps de "warm-up" peut causer des délais.
5.  **Traitement côté Flutter**: Bien que le problème semble être backend, un traitement trop lourd ou une mauvaise gestion des flux audio sortants du client peut contribuer.
6.  **Problèmes LiveKit**:
    *   **Configuration du serveur LiveKit**: Problèmes de performance ou de configuration incorrecte.
    *   **Latence de connexion**: Problèmes de réseau entre le client Flutter et le serveur LiveKit.

## Informations Nécessaires pour le Diagnostic

Pour affiner le diagnostic, les informations suivantes sont cruciales :

*   **Logs Flutter exacts** (`TimeoutException` ou autres erreurs pertinentes) au moment des timeouts.
*   **Logs du serveur Python** (`api-backend`) avec les traces complètes des requêtes d'analyse audio (début, fin, durée, erreurs).
*   **Logs des services Whisper-realtime et LiveKit** (si pertinents et disponibles) pour identifier les goulots d'étranglement spécifiques à ces services.
*   **Informations sur l'environnement d'exécution Flutter**:
    *   Émulateur ou appareil physique.
    *   Spécifications de l'appareil (modèle, OS).
    *   Détails de la connexion réseau (Wi-Fi, 4G, latence, bande passante).

## Prochaines Étapes

Une fois les logs et les informations collectées, l'analyse approfondie permettra de :

1.  Prioriser les **1-2 causes les plus probables** des timeouts.
2.  Ajouter des **logs supplémentaires** ciblés dans le code pour valider ces hypothèses.
3.  Proposer des **actions correctives** spécifiques pour chaque cause identifiée.
4.  **Exécuter des tests** de performance pour mesurer l'impact des optimisations.