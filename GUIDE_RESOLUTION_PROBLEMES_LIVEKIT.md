# 🔧 Guide de Résolution des Problèmes LiveKit - Eloquence

## 📋 **État Actuel du Système**

✅ **Tous les services sont opérationnels :**
- LiveKit Server : Connecté et fonctionnel
- Agent Multi-Agent : Connecté et fonctionnel  
- Redis : Opérationnel
- Mistral Conversation : Opérationnel
- Vosk STT : Opérationnel
- Token Service : Opérationnel

## 🚨 **Problèmes Identifiés et Solutions**

### 1. **Erreurs de Connexion Temporaires**

**Symptômes :**
```
ConnectionRefusedError: [Errno 111] Connect call failed ('172.18.0.7', 7880)
aiohttp.client_exceptions.ClientConnectorError: Cannot connect to host livekit-server:7880
```

**Cause :** Tentatives de connexion pendant le redémarrage du serveur LiveKit

**Solution Appliquée :**
- ✅ Ajout de `healthcheck` avec conditions `service_healthy`
- ✅ Augmentation du `start_period` à 30s pour LiveKit Server
- ✅ Dépendances conditionnelles dans `docker-compose.yml`

### 2. **Ordre de Démarrage des Services**

**Problème :** L'agent tentait de se connecter avant que LiveKit soit prêt

**Solution :**
```yaml
depends_on:
  livekit-server:
    condition: service_healthy
  redis:
    condition: service_healthy
  mistral-conversation:
    condition: service_healthy
```

## 🛠️ **Outils de Diagnostic**

### Script de Diagnostic Automatique
```powershell
# Exécuter le diagnostic
powershell -ExecutionPolicy Bypass -File scripts/check_livekit_simple.ps1
```

### Commandes de Diagnostic Manuel

**Vérifier l'état des conteneurs :**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep eloquence
```

**Vérifier les logs LiveKit :**
```bash
docker logs eloquence-livekit-server-1 --tail 20
```

**Vérifier les logs de l'agent :**
```bash
docker logs eloquence-multiagent --tail 20
```

**Tester la connectivité :**
```bash
curl -f http://localhost:8780
curl -f http://localhost:8080/health
```

## 🔄 **Procédure de Redémarrage Sécurisé**

### 1. **Arrêt Propre**
```bash
docker-compose down
```

### 2. **Nettoyage (si nécessaire)**
```bash
docker system prune -f
docker volume prune -f
```

### 3. **Redémarrage avec Healthchecks**
```bash
docker-compose up -d
```

### 4. **Vérification**
```bash
# Attendre 2-3 minutes puis vérifier
docker ps
powershell -ExecutionPolicy Bypass -File scripts/check_livekit_simple.ps1
```

## 📊 **Monitoring et Logs**

### Logs Importants à Surveiller

**LiveKit Server :**
- `worker registered` = Agent connecté avec succès
- `starting LiveKit server` = Démarrage normal
- `last worker deregistered` = Déconnexion normale

**Agent Multi-Agent :**
- `registered worker` = Connexion réussie
- `UNIFIED LIVEKIT AGENT STARTING` = Démarrage normal
- `Router will automatically detect` = Système opérationnel

### Indicateurs de Problème

**🚨 Problèmes Critiques :**
- `ConnectionRefusedError` répétés
- `Cannot connect to host livekit-server:7880`
- Conteneurs en état `unhealthy`

**⚠️ Problèmes Modérés :**
- Retards dans les healthchecks
- Redémarrages fréquents
- Logs d'erreur temporaires

## 🎯 **Bonnes Pratiques**

### 1. **Ordre de Démarrage**
- Toujours démarrer Redis en premier
- Puis LiveKit Server
- Enfin les agents

### 2. **Healthchecks**
- Utiliser les healthchecks pour les dépendances
- Attendre que les services soient `healthy` avant de continuer

### 3. **Monitoring**
- Surveiller les logs régulièrement
- Utiliser le script de diagnostic automatique
- Configurer des alertes si possible

### 4. **Réseau Docker**
- Vérifier que tous les services sont sur le même réseau
- S'assurer que les ports sont correctement exposés

## 🔧 **Configuration Optimisée**

### Docker Compose Amélioré
```yaml
# Dépendances conditionnelles
depends_on:
  livekit-server:
    condition: service_healthy
  redis:
    condition: service_healthy

# Healthchecks robustes
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Variables d'Environnement Critiques
```bash
LIVEKIT_URL=ws://livekit-server:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef
REDIS_URL=redis://redis:6379/0
```

## 📞 **Support et Escalade**

### Niveau 1 - Diagnostic Automatique
1. Exécuter le script de diagnostic
2. Vérifier les logs récents
3. Redémarrer les services problématiques

### Niveau 2 - Intervention Manuelle
1. Analyser les logs détaillés
2. Vérifier la configuration réseau
3. Reconstruire les images si nécessaire

### Niveau 3 - Support Avancé
1. Vérifier les ressources système
2. Analyser les métriques de performance
3. Consulter la documentation LiveKit officielle

---

**📝 Note :** Ce guide est basé sur l'analyse des logs du 21/08/2025 et les améliorations apportées au système. Il sera mis à jour selon l'évolution des problèmes rencontrés.
