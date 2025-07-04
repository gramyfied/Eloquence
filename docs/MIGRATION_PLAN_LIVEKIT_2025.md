# 🚀 Plan de Migration LiveKit vers Versions Récentes (Juin 2025)

## 📊 Analyse de l'État Actuel

### Versions Actuelles (PROBLÉMATIQUES)
```
LiveKit Server: latest (v1.9.0)
LiveKit Python SDK: 0.11.1 (TRÈS OBSOLÈTE - incompatible avec server v1.9.0)
LiveKit API: 0.5.1 (OBSOLÈTE)
LiveKit Agents: 0.7.2 (FRAMEWORK OBSOLÈTE)
```

### Versions Cibles (JUIN 2025)
```
LiveKit Server: v1.9.0 (garder - stable)
LiveKit Python SDK: 1.0.10 (UPGRADE MAJEUR REQUIS)
LiveKit Agents: 1.1.3 (UPGRADE MAJEUR REQUIS)
LiveKit API: (inclus dans SDK v1.0.10)
```

## 🔄 Étapes de Migration

### ÉTAPE 1 : SAUVEGARDE COMPLÈTE ✅
- [ ] Créer backup complet du projet
- [ ] Sauvegarder docker-compose.yml
- [ ] Exporter images Docker
- [ ] Documenter versions actuelles

### ÉTAPE 2 : PRÉPARATION ENVIRONNEMENT TEST
- [ ] Créer branche git `migration-livekit-v1`
- [ ] Copier projet pour tests isolés
- [ ] Préparer environnement de rollback

### ÉTAPE 3 : MIGRATION SDK PYTHON (PRIORITÉ ABSOLUE)
- [ ] Mettre à jour requirements.agent.txt
- [ ] Adapter imports pour v1.x
- [ ] Migrer patterns de connexion
- [ ] Adapter gestion des événements

### ÉTAPE 4 : MIGRATION CODE AGENT
- [ ] Remplacer patterns obsolètes v0.x
- [ ] Implémenter nouveau framework agents v1.1.3
- [ ] Adapter gestion audio/WebRTC
- [ ] Migrer callbacks événements

### ÉTAPE 5 : TESTS PROGRESSIFS
- [ ] Test compilation Docker
- [ ] Test connexion basique
- [ ] Test audio bidirectionnel
- [ ] Test intégration Flutter

### ÉTAPE 6 : OPTIMISATION POST-MIGRATION
- [ ] Exploiter nouvelles fonctionnalités v1.x
- [ ] Optimiser configuration réseau
- [ ] Améliorer performance

## 🚨 Points d'Attention Critiques

1. **Incompatibilité Majeure** : SDK v0.11.1 ne peut PAS communiquer avec Server v1.9.0
2. **Breaking Changes** : L'API a complètement changé entre v0.x et v1.x
3. **Framework Agents** : Architecture totalement différente en v1.1.3

## 📝 Changements de Code Majeurs

### Ancien Pattern (v0.x) - À REMPLACER
```python
from livekit import rtc
room = rtc.Room()
await room.connect(url, token)
```

### Nouveau Pattern (v1.x) - OBLIGATOIRE
```python
from livekit.agents import JobContext, WorkerOptions, cli
async def entrypoint(ctx: JobContext):
    await ctx.connect()
```

## 🎯 Critères de Succès

1. ✅ Connexion stable sans timeout
2. ✅ Audio bidirectionnel fonctionnel
3. ✅ Intégration Flutter opérationnelle
4. ✅ Performance < 200ms latence
5. ✅ Stabilité 30+ minutes

## 🔧 Commandes de Migration

```bash
# Backup
cp -r . ../eloquence-backup-$(date +%Y%m%d-%H%M%S)

# Nouvelle branche
git checkout -b migration-livekit-v1

# Test versions
docker exec eloquence-agent pip list | grep livekit
```

## 📅 Timeline Estimée

- Étape 1-2 : 30 minutes
- Étape 3-4 : 2-3 heures
- Étape 5 : 1 heure
- Étape 6 : 30 minutes

**Total : 4-5 heures**