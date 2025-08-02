# Guide de Configuration Locale Eloquence (192.168.1.44)

## Vue d'ensemble

Cette configuration permet de faire tourner tous les services Eloquence sur votre IP locale 192.168.1.44, facilitant le développement en évitant de jongler entre serveur distant et PC local.

## Architecture Simplifiée

### Services Déployés
- **API Principale Unifiée** : `http://192.168.1.44:8080`
- **Vosk STT** : `http://192.168.1.44:8002`
- **Mistral Conversation** : `http://192.168.1.44:8001`
- **LiveKit Server** : `ws://192.168.1.44:7880`
- **Redis** : `192.168.1.44:6379`

### Fichiers de Configuration

#### 1. Docker Compose Local
- **Fichier** : `docker-compose.local.yml`
- **Description** : Configuration Docker avec tous les services sur l'IP 192.168.1.44
- **Services** : API unifiée, Vosk, Mistral, LiveKit, Redis

#### 2. Script de Démarrage
- **Fichier** : `scripts/dev-local.ps1`
- **Usage** : `./scripts/dev-local.ps1`
- **Fonction** : Démarre tous les services en mode local

#### 3. Configuration Flutter
- **Fichier** : `frontend/flutter_app/lib/core/config/api_config.dart`
- **Configuration** : URLs locales par défaut (192.168.1.44)
- **Basculement** : Possibilité de revenir au serveur distant

## Utilisation

### Démarrage des Services

```powershell
# Démarrer tous les services locaux
./scripts/dev-local.ps1
```

### Vérification des Services

```powershell
# Vérifier l'état des services
docker-compose -f docker-compose.local.yml ps

# Voir les logs
docker-compose -f docker-compose.local.yml logs -f
```

### Arrêt des Services

```powershell
# Arrêter tous les services
docker-compose -f docker-compose.local.yml down
```

## Configuration Flutter

L'application Flutter est configurée pour utiliser automatiquement les services locaux :

- **API Principale** : `http://192.168.1.44:8080`
- **Vosk STT** : `http://192.168.1.44:8002`
- **Mistral** : `http://192.168.1.44:8001`
- **LiveKit** : `ws://192.168.1.44:7880`

### Basculement Serveur

Pour revenir au serveur distant :
1. Utiliser le toggle dans l'application Flutter
2. Ou modifier `api_config.dart` directement

## Avantages de cette Configuration

### 🚀 Développement Simplifié
- Tous les services sur la même machine
- Pas de latence réseau
- Debugging facilité

### 🔧 Flexibilité
- Configuration locale par défaut
- Possibilité de basculer vers le serveur distant
- Services indépendants

### 📱 Compatibilité Mobile
- L'app Flutter peut se connecter directement
- Tests en temps réel
- Développement mobile facilité

## Architecture Technique

### Services Core
```yaml
redis:
  ports: "192.168.1.44:6379:6379"
  
eloquence-api:
  ports: "192.168.1.44:8080:8080"
  depends_on: [redis, livekit, vosk-stt, mistral]
```

### Services Spécialisés
```yaml
livekit:
  ports: 
    - "192.168.1.44:7880:7880"
    - "192.168.1.44:7881:7881"
    - "192.168.1.44:40000-40100:40000-40100/udp"

vosk-stt:
  ports: "192.168.1.44:8002:8002"

mistral:
  ports: "192.168.1.44:8001:8001"
```

## Dépannage

### Services qui ne démarrent pas
```powershell
# Vérifier Docker
docker version

# Nettoyer les conteneurs
docker-compose -f docker-compose.local.yml down
docker system prune -f

# Redémarrer
./scripts/dev-local.ps1
```

### Problèmes de connectivité
1. Vérifier que l'IP 192.168.1.44 est accessible
2. Vérifier les ports (8080, 8001, 8002, 7880)
3. Vérifier les logs des services

### Flutter ne se connecte pas
1. Vérifier `api_config.dart`
2. S'assurer que `useRemoteServer` est `false`
3. Redémarrer l'app Flutter

## Configuration Distante (Sauvegardée)

La configuration distante reste disponible dans `api_config.dart` :
- **Serveur** : `51.159.110.4`
- **Ports** : 8000, 8001, 2700, 7880
- **Basculement** : Via toggle ou configuration manuelle

## Commandes Utiles

```powershell
# Démarrage
./scripts/dev-local.ps1

# Status
docker-compose -f docker-compose.local.yml ps

# Logs
docker-compose -f docker-compose.local.yml logs -f [service]

# Arrêt
docker-compose -f docker-compose.local.yml down

# Rebuild
docker-compose -f docker-compose.local.yml up --build -d
```

## Prochaines Étapes

1. **Test de l'application Flutter** avec les services locaux
2. **Validation des fonctionnalités** (STT, TTS, IA)
3. **Optimisation des performances** locales
4. **Documentation des workflows** de développement

---

**Note** : Cette configuration facilite grandement le développement en évitant la complexité du serveur distant tout en gardant la possibilité de basculer quand nécessaire.
