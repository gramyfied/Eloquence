# 🚀 Optimisations Docker pour 25Eloquence

Ce document décrit toutes les optimisations Docker mises en place pour améliorer les performances, réduire l'utilisation des ressources et accélérer les temps de build et de démarrage.

## 📋 Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Optimisations par Service](#optimisations-par-service)
- [Scripts d'Optimisation](#scripts-doptimisation)
- [Configuration Docker](#configuration-docker)
- [Utilisation](#utilisation)
- [Monitoring](#monitoring)
- [Dépannage](#dépannage)

## 🎯 Vue d'ensemble

### Améliorations Principales

1. **Limites de Ressources** : Allocation optimisée de CPU et mémoire
2. **Cache Docker** : Utilisation intelligente du cache pour accélérer les builds
3. **Volumes Optimisés** : Séparation des données persistantes et du cache
4. **Health Checks** : Surveillance améliorée de l'état des services
5. **Démarrage Séquentiel** : Évite la surcharge au démarrage
6. **Nettoyage Automatique** : Scripts de maintenance automatisés

### Gains de Performance Attendus

- ⚡ **Build Time** : Réduction de 40-60% grâce au cache
- 🚀 **Startup Time** : Réduction de 30-50% avec le démarrage séquentiel
- 💾 **Memory Usage** : Optimisation de 20-30% avec les limites
- 🔄 **Restart Time** : Réduction de 50-70% avec les volumes persistants

## 🛠️ Optimisations par Service

### Redis
```yaml
deploy:
  resources:
    limits:
      memory: 512M
    reservations:
      memory: 256M
tmpfs:
  - /tmp:noexec,nosuid,size=100m
```

**Optimisations** :
- Limite mémoire à 512MB (suffisant pour le cache)
- Tmpfs pour les fichiers temporaires
- Restart policy optimisé

### API Backend
```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
environment:
  - PYTHONUNBUFFERED=1
  - PYTHONDONTWRITEBYTECODE=1
```

**Optimisations** :
- Variables Python pour de meilleures performances
- Cache volume pour les dépendances
- Build multi-stage avec cache

### LiveKit Server
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '1.0'
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```

**Optimisations** :
- Augmentation des limites de fichiers ouverts
- Volume persistant pour les données
- Configuration Redis intégrée

### Whisper STT
```yaml
deploy:
  resources:
    limits:
      memory: 16G
      cpus: '4.0'
environment:
  - OMP_NUM_THREADS=4
  - CUDA_VISIBLE_DEVICES=0
```

**Optimisations** :
- Allocation maximale de ressources (service le plus gourmand)
- Configuration OpenMP pour le parallélisme
- Cache des modèles persistant
- Tmpfs de 2GB pour les traitements

### Azure TTS
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

**Optimisations** :
- Ressources limitées (service léger)
- Cache pour les réponses TTS
- Health check optimisé

### Eloquence Agent v1
```yaml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '2.0'
environment:
  - OMP_NUM_THREADS=2
  - PYTHONUNBUFFERED=1
```

**Optimisations** :
- Ressources équilibrées pour l'IA
- Cache des modèles séparé
- Configuration OpenMP optimisée

## 📜 Scripts d'Optimisation

### Windows PowerShell (`scripts/docker-optimize.ps1`)

```powershell
# Utilisation interactive
.\scripts\docker-optimize.ps1

# Utilisation avec paramètres
.\scripts\docker-optimize.ps1 full    # Optimisation complète
.\scripts\docker-optimize.ps1 cleanup # Nettoyage uniquement
.\scripts\docker-optimize.ps1 build   # Build optimisé
.\scripts\docker-optimize.ps1 start   # Démarrage optimisé
.\scripts\docker-optimize.ps1 monitor # Monitoring
```

### Linux/macOS (`scripts/docker-optimize.sh`)

```bash
# Utilisation interactive
./scripts/docker-optimize.sh

# Utilisation avec paramètres
./scripts/docker-optimize.sh full    # Optimisation complète
./scripts/docker-optimize.sh cleanup # Nettoyage uniquement
./scripts/docker-optimize.sh build   # Build optimisé
./scripts/docker-optimize.sh start   # Démarrage optimisé
./scripts/docker-optimize.sh monitor # Monitoring
```

### Fonctionnalités des Scripts

1. **Nettoyage** : Supprime images, volumes et réseaux inutilisés
2. **Build Optimisé** : Active BuildKit et le cache
3. **Démarrage Séquentiel** : Démarre les services par étapes
4. **Monitoring** : Affiche l'utilisation des ressources
5. **Vérifications** : Contrôle les prérequis et la configuration

## ⚙️ Configuration Docker

### Variables d'Environnement Optimisées

```bash
# Build optimisé
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Python optimisé
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=random

# OpenMP optimisé
export OMP_NUM_THREADS=4
```

### Fichier `.dockerignore`

Le fichier `.dockerignore` optimisé exclut :
- Fichiers de développement (.git, .vscode, etc.)
- Cache et fichiers temporaires
- Documentation et logs
- Données volumineuses (modèles, audio)
- Fichiers de configuration locaux

## 🚀 Utilisation

### Démarrage Rapide

```bash
# 1. Optimisation complète (recommandé pour la première fois)
.\scripts\docker-optimize.ps1 full

# 2. Démarrage normal (après optimisation)
docker-compose --profile agent-v1 up -d

# 3. Monitoring des performances
.\scripts\docker-optimize.ps1 monitor
```

### Workflow de Développement

```bash
# 1. Nettoyage quotidien
.\scripts\docker-optimize.ps1 cleanup

# 2. Build après modifications
.\scripts\docker-optimize.ps1 build

# 3. Démarrage optimisé
.\scripts\docker-optimize.ps1 start

# 4. Monitoring continu
.\scripts\docker-optimize.ps1 monitor
```

### Commandes Docker Optimisées

```bash
# Build avec cache
docker-compose build --parallel --compress --pull

# Démarrage par étapes
docker-compose up -d redis livekit
docker-compose up -d whisper-stt azure-tts
docker-compose up -d api-backend
docker-compose --profile agent-v1 up -d eloquence-agent-v1

# Monitoring des ressources
docker stats --no-stream
docker-compose ps
```

## 📊 Monitoring

### Métriques Importantes

1. **Utilisation Mémoire** : Surveiller les limites
2. **Utilisation CPU** : Éviter la saturation
3. **Health Checks** : Vérifier l'état des services
4. **Temps de Réponse** : Mesurer les performances
5. **Espace Disque** : Contrôler l'accumulation

### Commandes de Monitoring

```bash
# État des services
docker-compose ps

# Utilisation des ressources
docker stats --no-stream

# Logs en temps réel
docker-compose logs -f

# Health checks
docker-compose ps --format "table {{.Name}}\t{{.Status}}"

# Espace disque Docker
docker system df
```

## 🔧 Dépannage

### Problèmes Courants

#### 1. Mémoire Insuffisante
```bash
# Symptômes : OOM kills, services qui redémarrent
# Solution : Augmenter les limites ou fermer d'autres applications
```

#### 2. Build Lent
```bash
# Symptômes : Builds qui prennent plus de 10 minutes
# Solution : Vérifier le cache Docker et .dockerignore
docker builder prune
```

#### 3. Services qui ne Démarrent Pas
```bash
# Symptômes : Services en état "Restarting"
# Solution : Vérifier les logs et les dépendances
docker-compose logs [service-name]
```

#### 4. Espace Disque Plein
```bash
# Symptômes : Erreurs "no space left on device"
# Solution : Nettoyage Docker
.\scripts\docker-optimize.ps1 cleanup
docker system prune -a
```

### Commandes de Diagnostic

```bash
# Informations système Docker
docker system info

# Utilisation de l'espace
docker system df -v

# Processus Docker
docker ps -a

# Réseaux Docker
docker network ls

# Volumes Docker
docker volume ls
```

## 📈 Optimisations Avancées

### Pour Systèmes Puissants (32GB+ RAM)

```yaml
# Augmenter les limites pour Whisper
whisper-stt:
  deploy:
    resources:
      limits:
        memory: 24G
        cpus: '8.0'
```

### Pour Systèmes Limités (8GB RAM)

```yaml
# Réduire les limites
whisper-stt:
  deploy:
    resources:
      limits:
        memory: 6G
        cpus: '2.0'
```

### Configuration GPU (si disponible)

```yaml
# Activer le support GPU pour Whisper
whisper-stt:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

## 🎯 Recommandations

### Configuration Système Recommandée

- **RAM** : 16GB minimum, 32GB recommandé
- **CPU** : 8 cœurs minimum, 16 cœurs recommandé
- **Stockage** : SSD avec 100GB libres minimum
- **Docker** : Version 20.10+ avec BuildKit activé

### Bonnes Pratiques

1. **Nettoyage Régulier** : Exécuter le script de nettoyage quotidiennement
2. **Monitoring Continu** : Surveiller l'utilisation des ressources
3. **Builds Incrémentaux** : Éviter les builds complets inutiles
4. **Logs Rotatifs** : Configurer la rotation des logs
5. **Sauvegardes** : Sauvegarder les volumes persistants

---

*Dernière mise à jour : 22 juin 2025*
*Version : 1.0.0*