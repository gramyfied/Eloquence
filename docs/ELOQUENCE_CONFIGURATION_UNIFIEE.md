# Configuration Unifiée Eloquence - Résumé et Instructions

## 📋 Résumé du Travail Effectué

### 1. **Problème Initial**
- LiveKit était cassé pour Tribunal et Confidence Boost
- Studio Situations Pro utilisait le mauvais agent (Thomas au lieu des agents multi-agents)
- Configuration Docker complexe avec plusieurs fichiers YAML

### 2. **Solution Implémentée**

#### A. Système de Routage Unifié
Création de `services/livekit-agent/unified_entrypoint.py` qui :
- Détecte automatiquement le type d'exercice depuis les métadonnées
- Route vers le bon système (multi-agents ou individuel)
- Évite les conversions incorrectes entre exercices

#### B. Configuration Docker Simplifiée
- `docker-compose-unified.yml` : Un seul fichier avec tous les services essentiels
- `Dockerfile.unified` : Dockerfile simplifié pour l'agent LiveKit
- Suppression de la complexité inutile

### 3. **Fichiers Créés/Modifiés**

```
✅ services/livekit-agent/unified_entrypoint.py
✅ services/livekit-agent/Dockerfile.unified  
✅ docker-compose-unified.yml
✅ scripts/restart-unified.ps1
✅ services/livekit-agent/main.py (modifié pour supprimer les conversions)
```

## 🚀 Instructions de Démarrage

### Étape 1 : Arrêter tous les services existants
```powershell
docker-compose down
docker container prune -f
```

### Étape 2 : Démarrer avec la configuration unifiée
```powershell
# Build et démarrage
docker-compose -f docker-compose-unified.yml build
docker-compose -f docker-compose-unified.yml up -d

# Vérifier l'état
docker-compose -f docker-compose-unified.yml ps
```

### Étape 3 : Vérifier les logs
```powershell
# Logs de l'agent LiveKit
docker-compose -f docker-compose-unified.yml logs -f livekit-agent

# Logs de VOSK
docker-compose -f docker-compose-unified.yml logs -f vosk-stt
```

## 🔧 Architecture Technique

### Services Docker
1. **redis** : Cache et état partagé
2. **vosk-stt** : Reconnaissance vocale française
3. **mistral-conversation** : IA conversationnelle  
4. **livekit-server** : Serveur WebRTC
5. **livekit-token-service** : Génération de tokens JWT
6. **livekit-agent** : Agent unifié avec routage intelligent
7. **eloquence-exercises-api** : API backend principale

### Flux de Routage

```
Métadonnées exercice
       ↓
unified_entrypoint.py
       ↓
    Détection
       ↓
┌──────────────┬──────────────┐
│ Multi-Agents │  Individual  │
│              │              │
│ • Studio Pro │ • Tribunal   │
│              │ • Confidence │
└──────────────┴──────────────┘
```

## ✅ Points de Validation

### Configuration des Exercices

#### 1. **Tribunal des Idées Impossibles**
- **Type** : Individual
- **Agent** : Juge Magistrat
- **Voix** : onyx (grave et autoritaire)
- **Fichier** : main.py → TribunalAgent

#### 2. **Confidence Boost**  
- **Type** : Individual
- **Agent** : Thomas
- **Voix** : alloy (chaleureuse)
- **Fichier** : main.py → ConfidenceBoostAgent

#### 3. **Studio Situations Pro**
- **Type** : Multi-Agents
- **Agents** : 11 agents distincts
- **Voix** : Variées selon l'agent
- **Fichier** : multi_agent_main.py → MultiAgentManager

## 🐛 Résolution des Problèmes

### Problème : VOSK ne trouve pas le modèle
**Solution** :
```bash
# Dans le conteneur VOSK
docker exec -it eloquence-vosk-stt bash
cd /app
./download_model.sh
```

### Problème : Agent LiveKit ne démarre pas
**Vérifier** :
1. Variable OPENAI_API_KEY dans .env
2. Logs : `docker logs eloquence-livekit-agent`
3. Rebuild : `docker-compose -f docker-compose-unified.yml build --no-cache livekit-agent`

### Problème : Mauvais agent répond
**Vérifier** :
1. Métadonnées envoyées par Flutter
2. Logs de unified_entrypoint.py
3. Type d'exercice détecté

## 📊 État Actuel

### ✅ Complété
- Création du système de routage unifié
- Configuration Docker simplifiée
- Suppression des conversions incorrectes
- Documentation de la solution

### ⏳ En Cours
- Test de la configuration unifiée
- Validation du modèle VOSK

### 📝 À Faire
- Tester tous les exercices avec la nouvelle configuration
- Valider les voix et agents pour chaque exercice
- Optimiser les performances si nécessaire

## 🎯 Prochaines Étapes

1. **Immédiat** :
   - Redémarrer tous les services avec docker-compose-unified.yml
   - Vérifier que VOSK a son modèle
   - Tester un exercice de chaque type

2. **Court terme** :
   - Valider la stabilité sur plusieurs sessions
   - Optimiser les temps de démarrage
   - Ajouter des health checks plus précis

3. **Long terme** :
   - Monitoring des performances
   - Logs centralisés
   - Auto-scaling si nécessaire

## 📚 Références

- [unified_entrypoint.py](../services/livekit-agent/unified_entrypoint.py)
- [docker-compose-unified.yml](../docker-compose-unified.yml)
- [Documentation LiveKit](https://docs.livekit.io/)
- [Documentation Vosk](https://alphacephei.com/vosk/)