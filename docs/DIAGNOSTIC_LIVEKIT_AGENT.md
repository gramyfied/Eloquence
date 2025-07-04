# Diagnostic LiveKit et Agent - Rapport Complet

## 📊 État actuel

### Logs LiveKit analysés
```
2025-06-24T13:37:49.947Z - LiveKit reçoit signal "terminated" et s'arrête
2025-06-24T13:37:49.948Z - Erreur TCP (normal lors de l'arrêt)
2025-06-24T13:37:55.325Z - LiveKit redémarre
2025-06-24T13:37:55.408Z - Connexion Redis établie
2025-06-24T13:37:55.409Z - LiveKit server démarré (v1.9.0)
2025-06-24T13:37:55.963Z - Agent worker enregistré avec succès
```

### Configuration identifiée

#### 1. **docker-compose.yml**
- Service `eloquence-agent-v1` configuré avec profile `agent-v1`
- Restart policy: `no` (l'agent ne redémarre pas automatiquement)
- Ports: 8080
- Mémoire: 4G max, 2G réservés

#### 2. **URLs de l'agent**
```yaml
LIVEKIT_URL: ws://livekit:7880
WHISPER_STT_URL: http://whisper-stt:8001
PIPER_TTS_URL: http://azure-tts:5002
MISTRAL_BASE_URL: https://api.scaleway.ai/.../v1/chat/completions
```

#### 3. **Script de lancement**
- Fichier: `/app/services/real_time_voice_agent_force_audio.py`
- Lancé via: `start-agent-v1.sh`

## 🔍 Analyse du problème

### Causes possibles du redémarrage LiveKit :

1. **Healthcheck échoué** - LiveKit n'a pas de healthcheck défini
2. **Problème de ressources** - Limites mémoire/CPU atteintes
3. **Crash de l'agent** - L'agent peut causer le redémarrage
4. **Signal externe** - Docker ou système envoie SIGTERM

### Points d'attention dans l'agent :

1. **Sessions HTTP non fermées** - Risque de fuite mémoire
2. **Traitement audio continu** - Toutes les 3 secondes (AUDIO_INTERVAL_MS)
3. **Pipeline complet** - STT→LLM→TTS peut être lourd

## 🛠️ Actions recommandées

### 1. Vérifier l'état des services
```bash
docker-compose ps -a
docker-compose logs --tail=100 livekit eloquence-agent-v1
```

### 2. Lancer l'agent avec le bon profile
```bash
docker-compose --profile agent-v1 up eloquence-agent-v1
```

### 3. Monitorer les ressources
```bash
docker stats
```

### 4. Vérifier les logs de l'agent
```bash
docker-compose logs -f eloquence-agent-v1
```

## 📝 Script de diagnostic complet

Exécutez le script de diagnostic créé :
```bash
python scripts/diagnostic_livekit_restart.py
```

## 🔧 Configuration de lancement correcte

Pour lancer tous les services avec l'agent :
```bash
# Arrêter tous les services
docker-compose down

# Lancer avec le profile agent-v1
docker-compose --profile agent-v1 up -d

# Vérifier les logs
docker-compose logs -f
```

## ⚠️ Points critiques

1. **L'agent a `restart: 'no'`** - Il ne redémarre pas automatiquement
2. **LiveKit redémarre** mais l'agent peut ne pas se reconnecter
3. **Vérifier que tous les services sont healthy** avant de lancer l'agent

## 📊 Commandes de monitoring

```bash
# État des conteneurs
docker-compose ps

# Logs en temps réel
docker-compose logs -f livekit eloquence-agent-v1

# Ressources utilisées
docker stats --no-stream

# Vérifier les ports
netstat -an | findstr "7880 7881 8080"