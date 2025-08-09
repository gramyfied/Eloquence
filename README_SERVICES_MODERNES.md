# 🚀 Services Eloquence Modernes

Configuration mise à jour avec les dernières versions des services pour résoudre les problèmes de connectivité LiveKit.

## 📋 Problèmes résolus

- ✅ Connexion LiveKit défaillante
- ✅ Génération de tokens impossible
- ✅ Exercices Confidence Boost et Tribunal des Idées non fonctionnels
- ✅ Configuration réseau obsolète
- ✅ Versions de services dépassées

## 🆕 Nouveautés

### Configuration réseau moderne
- Détection automatique de l'environnement
- Fallbacks intelligents
- Configuration WebRTC optimisée
- Gestion des timeouts modernes

### Services mis à jour
- **LiveKit Server**: v1.5.3 (dernière version stable)
- **Redis**: 7.2-alpine (performance optimisée)
- **HAProxy**: 2.9-alpine (load balancing moderne)
- **Prometheus**: v2.48.0 (monitoring avancé)
- **Grafana**: 10.2.0 (dashboards modernes)

### Configuration LiveKit avancée
- Codecs audio/vidéo optimisés
- Serveurs STUN multiples
- Configuration ICE moderne
- Métriques Prometheus intégrées

## 🚀 Démarrage rapide

### 1. Arrêt des services existants
```powershell
# Arrêter tous les services
docker-compose down --remove-orphans
```

### 2. Démarrage des services modernes
```powershell
# Démarrage simple
.\scripts\demarrer_services_modernes.ps1

# Démarrage avec nettoyage
.\scripts\demarrer_services_modernes.ps1 -Clean

# Démarrage avec surveillance
.\scripts\demarrer_services_modernes.ps1 -Monitor
```

### 3. Vérification de la connectivité
```powershell
# Diagnostic complet
.\scripts\diagnostic_connectivite_moderne.ps1

# Diagnostic avec IP spécifique
.\scripts\diagnostic_connectivite_moderne.ps1 -BaseUrl "192.168.1.44"
```

## 🔧 Configuration Flutter

### Mise à jour de l'IP réseau
1. Vérifiez votre IP avec `ipconfig`
2. Mettez à jour `frontend/flutter_app/lib/core/config/network_config.dart`
3. Remplacez `192.168.1.44` par votre IP actuelle

### Configuration automatique (recommandée)
La nouvelle configuration détecte automatiquement l'environnement et utilise les fallbacks appropriés.

## 📊 Services disponibles

| Service | Port | URL | Statut |
|---------|------|-----|--------|
| LiveKit Server | 7880 | `ws://localhost:7880` | ✅ Principal |
| Token Service | 8004 | `http://localhost:8004` | ✅ Tokens |
| Exercises API | 8005 | `http://localhost:8005` | ✅ Exercices |
| Mistral Conversation | 8001 | `http://localhost:8001` | ✅ IA |
| Vosk STT | 8002 | `http://localhost:8002` | ✅ Reconnaissance vocale |
| HAProxy | 8080 | `http://localhost:8080` | ✅ Load balancer |
| Redis | 6379 | `redis://localhost:6379` | ✅ Cache |
| Prometheus | 9090 | `http://localhost:9090` | ✅ Métriques |
| Grafana | 3000 | `http://localhost:3000` | ✅ Dashboards |

## 🔍 Diagnostic et dépannage

### Script de diagnostic
```powershell
# Diagnostic complet avec retry
.\scripts\diagnostic_connectivite_moderne.ps1 -Timeout 15 -MaxRetries 5
```

### Vérification des logs
```powershell
# Logs en temps réel
docker-compose -f docker-compose.modern.yml logs -f

# Logs d'un service spécifique
docker-compose -f docker-compose.modern.yml logs livekit-server
```

### Vérification de la santé
```powershell
# État des services
docker-compose -f docker-compose.modern.yml ps

# Health checks
docker-compose -f docker-compose.modern.yml exec livekit-server curl -f http://localhost:7880/
```

## 🛠️ Résolution des problèmes courants

### Problème: Impossible de se connecter à LiveKit
**Solution:**
1. Vérifiez que le service est démarré: `docker ps | findstr 7880`
2. Testez la connectivité: `Invoke-WebRequest http://localhost:7880/`
3. Vérifiez les logs: `docker logs eloquence-livekit-server-1`

### Problème: Génération de tokens échoue
**Solution:**
1. Vérifiez le service: `docker ps | findstr 8004`
2. Testez l'endpoint: `Invoke-WebRequest http://localhost:8004/health`
3. Vérifiez les clés API dans `livekit.modern.yaml`

### Problème: Exercices ne se chargent pas
**Solution:**
1. Vérifiez l'API: `Invoke-WebRequest http://localhost:8005/health`
2. Vérifiez la base de données Redis
3. Testez la génération de tokens

## 🔄 Migration depuis l'ancienne configuration

### 1. Sauvegarde
```powershell
# Sauvegarder l'ancienne configuration
Copy-Item docker-compose.yml docker-compose.backup.yml
Copy-Item livekit.yaml livekit.backup.yaml
```

### 2. Remplacement
```powershell
# Remplacer par les nouvelles configurations
Copy-Item docker-compose.modern.yml docker-compose.yml
Copy-Item livekit.modern.yaml livekit.yaml
```

### 3. Redémarrage
```powershell
# Redémarrer avec la nouvelle configuration
.\scripts\demarrer_services_modernes.ps1 -Clean
```

## 📈 Monitoring et métriques

### Prometheus
- Métriques LiveKit en temps réel
- Performance des agents
- Utilisation des ressources

### Grafana
- Dashboards prédéfinis
- Alertes configurables
- Historique des performances

## 🔐 Sécurité

### Clés API
- Clés de développement dans `livekit.modern.yaml`
- Variables d'environnement pour la production
- Rotation automatique des clés

### Réseau
- Isolation des services
- Firewall configuré
- Accès restreint aux ports

## 📝 Logs et debugging

### Niveaux de log
- `info`: Informations générales
- `debug`: Détails de debugging
- `warn`: Avertissements
- `error`: Erreurs

### Format des logs
- JSON structuré
- Horodatage automatique
- Métadonnées incluses

## 🚀 Déploiement en production

### Variables d'environnement
```bash
# Production
export LIVEKIT_API_KEY="your_production_key"
export LIVEKIT_API_SECRET="your_production_secret"
export REDIS_PASSWORD="your_redis_password"
```

### Configuration réseau
- IPs publiques configurées
- Certificats SSL/TLS
- Load balancer externe

## 📞 Support

### Documentation
- [Guide LiveKit officiel](https://docs.livekit.io/)
- [Configuration WebRTC](https://webrtc.org/getting-started/overview)
- [Docker Compose](https://docs.docker.com/compose/)

### Communauté
- Issues GitHub
- Forum Eloquence
- Documentation interne

---

## ✅ Checklist de validation

- [ ] Services démarrés sans erreur
- [ ] Connectivité LiveKit vérifiée
- [ ] Génération de tokens fonctionnelle
- [ ] Exercices Confidence Boost accessibles
- [ ] Exercices Tribunal des Idées accessibles
- [ ] Configuration réseau mise à jour
- [ ] Monitoring opérationnel
- [ ] Logs sans erreurs critiques

---

**🎯 Objectif**: Résoudre les problèmes de connectivité et moderniser l'infrastructure Eloquence pour une expérience utilisateur optimale.
