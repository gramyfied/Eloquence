# Guide de Déploiement Final - Eloquence v1.x

## État Actuel de l'Infrastructure

### Services Déployés
- ✅ **API Backend** : Port 8000 (Healthy)
- ✅ **LiveKit Server** : Ports 7880-7881 (Healthy)
- ✅ **Agent LiveKit v1** : Port 8080 (Starting)
- ✅ **OpenAI TTS** : Port 5002 (Healthy)
- ✅ **Whisper STT** : Port 8001 (Healthy)
- ✅ **Redis** : Port 6379 (Healthy)

### Corrections Appliquées

#### 1. Optimisation Mémoire Agent
- Implémentation du garbage collection forcé
- Nettoyage des ressources après chaque session
- Limitation de la taille du contexte de conversation

#### 2. Résolution Connectivité Mobile
- Configuration du pare-feu Windows
- Ouverture des ports nécessaires
- Scripts de test de connectivité

#### 3. Compatibilité LiveKit v1.x
- Adaptation du code pour LiveKit SDK 1.0.10
- Gestion correcte des événements
- Pipeline audio optimisé

## Commandes de Déploiement

### Démarrage Complet
```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Voir les logs
docker-compose logs -f
```

### Redémarrage d'un Service
```bash
# Redémarrer l'agent
docker-compose restart eloquence-agent-v1

# Redémarrer l'API
docker-compose restart api-backend
```

### Tests de Connectivité
```powershell
# Test depuis Windows
powershell -ExecutionPolicy Bypass -File test_connectivity.ps1

# Test mobile
powershell -ExecutionPolicy Bypass -File mobile_connectivity_test.ps1
```

## Configuration Mobile (Flutter)

### 1. Adresse IP du Serveur
Modifier dans `frontend/flutter_app/lib/config/app_config.dart` :
```dart
static const String serverIp = '192.168.1.44';
```

### 2. Build et Déploiement
```bash
cd frontend/flutter_app
flutter build apk --release
```

## Monitoring et Logs

### Logs en Temps Réel
```bash
# Tous les services
docker-compose logs -f

# Service spécifique
docker logs -f 25eloquence-finalisation-eloquence-agent-v1-1
```

### Métriques Clés à Surveiller
- Utilisation mémoire de l'agent (< 500MB)
- Latence audio (< 200ms)
- Taux de succès des connexions WebRTC

## Dépannage

### Agent ne Démarre Pas
1. Vérifier les logs : `docker logs eloquence-agent-v1`
2. Redémarrer : `docker-compose restart eloquence-agent-v1`
3. Rebuild si nécessaire : `docker-compose build eloquence-agent-v1`

### Problèmes de Connectivité Mobile
1. Exécuter `configure_firewall.ps1` en admin
2. Vérifier l'IP du serveur
3. Tester avec `mobile_connectivity_test.ps1`

### Haute Utilisation Mémoire
- L'agent inclut maintenant un garbage collector automatique
- Redémarrage automatique si > 500MB

## Variables d'Environnement

### Production (.env)
```env
# LiveKit
LIVEKIT_URL=ws://192.168.1.44:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret

# OpenAI
OPENAI_API_KEY=your-key-here

# Redis
REDIS_URL=redis://redis:6379

# Logging
LOG_LEVEL=INFO
```

## Sécurité

### Ports Exposés
- Utiliser un reverse proxy (nginx) en production
- Activer HTTPS/WSS
- Limiter l'accès par IP si nécessaire

### Secrets
- Ne jamais commiter les clés API
- Utiliser des secrets managers en production
- Rotation régulière des tokens

## Maintenance

### Sauvegarde
```bash
# Backup des données
docker-compose exec redis redis-cli BGSAVE

# Export des logs
docker-compose logs > backup_logs_$(date +%Y%m%d).txt
```

### Mise à Jour
```bash
# Pull des dernières images
docker-compose pull

# Rebuild et redémarrer
docker-compose up -d --build
```

## Checklist de Déploiement

- [ ] Variables d'environnement configurées
- [ ] Pare-feu Windows configuré
- [ ] Tests de connectivité passés
- [ ] Application mobile configurée avec la bonne IP
- [ ] Monitoring en place
- [ ] Logs accessibles
- [ ] Documentation à jour

## Support

Pour tout problème :
1. Consulter les logs détaillés
2. Vérifier la connectivité réseau
3. S'assurer que tous les services sont "healthy"
4. Redémarrer les services problématiques

---
*Dernière mise à jour : 30/06/2025*