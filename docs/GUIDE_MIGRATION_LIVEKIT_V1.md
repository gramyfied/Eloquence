# 🚀 Guide de Migration LiveKit v0.x vers v1.x

## 📋 Résumé de la Migration

Cette migration résout les problèmes d'incompatibilité entre LiveKit SDK Python v0.11.1 et LiveKit Server v1.9.0 en mettant à jour vers les versions récentes et compatibles.

### Fichiers Créés
1. **`MIGRATION_PLAN_LIVEKIT_2025.md`** - Plan détaillé de migration
2. **`scripts/backup_before_migration.bat`** - Script de sauvegarde
3. **`services/api-backend/requirements.agent.v1.txt`** - Nouvelles dépendances
4. **`services/api-backend/services/real_time_voice_agent_v1.py`** - Agent migré v1.x
5. **`services/api-backend/start-agent-v1.sh`** - Script de démarrage
6. **`services/api-backend/Dockerfile.agent.v1`** - Dockerfile pour v1.x
7. **`docker-compose.v1.yml`** - Configuration Docker pour tests
8. **`scripts/test_migration_v1.bat`** - Script de test

## 🔄 Étapes de Migration

### 1️⃣ Sauvegarde Complète (OBLIGATOIRE)

```bash
# Exécuter le script de sauvegarde
scripts\backup_before_migration.bat
```

Cela créera une sauvegarde complète dans `../eloquence-backup-[date]`

### 2️⃣ Test de la Migration

```bash
# Tester la nouvelle configuration
scripts\test_migration_v1.bat
```

Ce script va :
- Construire la nouvelle image avec LiveKit v1.x
- Démarrer les services
- Vérifier les versions installées
- Afficher les logs

### 3️⃣ Validation de la Migration

#### Vérifier les versions
```bash
docker-compose -f docker-compose.v1.yml exec eloquence-agent-v1 pip list | grep livekit
```

Vous devriez voir :
```
livekit                1.0.10
livekit-agents         1.1.3
```

#### Vérifier les logs
```bash
docker-compose -f docker-compose.v1.yml logs -f eloquence-agent-v1
```

Recherchez :
- ✅ "Agent initialisé pour la room"
- ✅ "Assistant vocal démarré avec succès"
- ❌ Pas d'erreurs de connexion WebSocket

### 4️⃣ Migration Complète

Si les tests sont concluants :

1. **Arrêter l'ancienne configuration**
   ```bash
   docker-compose down
   ```

2. **Remplacer les fichiers**
   ```bash
   # Sauvegarder l'ancien agent
   copy services\api-backend\services\real_time_voice_agent.py services\api-backend\services\real_time_voice_agent.old.py
   
   # Remplacer par la version v1
   copy services\api-backend\services\real_time_voice_agent_v1.py services\api-backend\services\real_time_voice_agent.py
   
   # Mettre à jour requirements
   copy services\api-backend\requirements.agent.v1.txt services\api-backend\requirements.agent.txt
   
   # Mettre à jour Dockerfile
   copy services\api-backend\Dockerfile.agent.v1 services\api-backend\Dockerfile.agent
   ```

3. **Mettre à jour docker-compose.yml**
   - Remplacer l'image `latest` par `v1.9.0` pour LiveKit
   - S'assurer que tous les services utilisent les bonnes versions

4. **Redémarrer avec la nouvelle configuration**
   ```bash
   docker-compose up -d
   ```

## 🧪 Tests de Validation Post-Migration

### Test 1 : Connexion de Base
```bash
# Vérifier que l'agent se connecte
docker-compose logs eloquence-agent | grep "connecté"
```

### Test 2 : Test Audio avec Flutter
1. Démarrer l'application Flutter
2. Se connecter à un scénario
3. Vérifier :
   - ✅ Connexion établie sans timeout
   - ✅ Audio bidirectionnel fonctionnel
   - ✅ Pas de déconnexion intempestive

### Test 3 : Test de Stabilité
Laisser l'agent tourner pendant 30+ minutes et vérifier :
- Pas de crash
- Pas de fuite mémoire
- Performance stable

## 🚨 Rollback si Nécessaire

Si la migration échoue :

```bash
# Restaurer depuis la sauvegarde
..\eloquence-backup-[date]\restore-backup.bat

# Ou manuellement
docker-compose down
xcopy /E /I /H /Y "..\eloquence-backup-[date]\*" "."
docker-compose up -d
```

## 📊 Changements Majeurs du Code

### Ancien Pattern (v0.x)
```python
from livekit import rtc
room = rtc.Room()
await room.connect(url, token)

@room.on("track_subscribed")
async def on_track_subscribed(track, publication, participant):
    # Gestion manuelle des tracks
```

### Nouveau Pattern (v1.x)
```python
from livekit.agents import JobContext, WorkerOptions, cli
from livekit.agents.voice_assistant import VoiceAssistant

async def entrypoint(ctx: JobContext):
    await ctx.connect(auto_subscribe=rtc.AutoSubscribe.AUDIO_ONLY)
    
    assistant = VoiceAssistant(
        vad=vad,
        stt=stt,
        llm=llm,
        tts=tts
    )
    assistant.start(ctx.room)
```

## ✅ Critères de Succès

La migration est réussie quand :

1. **Connexion Stable** ✅
   - Pas de timeout `wait_pc_connection`
   - WebSocket reste connecté

2. **Audio Fonctionnel** ✅
   - Capture audio utilisateur OK
   - Synthèse vocale agent OK
   - Latence < 200ms

3. **Intégration Flutter** ✅
   - Application se connecte normalement
   - Tous les scénarios fonctionnent

4. **Performance** ✅
   - CPU/RAM stables
   - Pas de fuites mémoire
   - Réponses rapides

## 🎯 Prochaines Étapes

Après migration réussie :

1. **Optimiser la Configuration**
   - Ajuster les paramètres VAD
   - Optimiser la latence
   - Améliorer la qualité audio

2. **Exploiter les Nouvelles Fonctionnalités**
   - Interruption intelligente
   - Streaming amélioré
   - Métriques avancées

3. **Documenter**
   - Mettre à jour la documentation
   - Former l'équipe aux nouvelles APIs
   - Créer des tests automatisés

## 📞 Support

En cas de problème :
1. Vérifier les logs : `docker-compose logs -f eloquence-agent`
2. Consulter la doc LiveKit v1.x : https://docs.livekit.io
3. Rollback si nécessaire avec la sauvegarde

---

**Migration préparée le 21/06/2025 - LiveKit v1.0.10 / Agents v1.1.3**