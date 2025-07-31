# 🚀 GUIDE DE DÉPLOIEMENT DES NOUVEAUX ENDPOINTS

## 📋 Résumé des Modifications

Date : 31 Juillet 2025  
Objectif : Ajouter les endpoints manquants pour la compatibilité frontend  
Status : ✅ **PRÊT POUR DÉPLOIEMENT**

---

## 🔧 MODIFICATIONS APPORTÉES

### 1. **Configuration Frontend Corrigée**
- ✅ Changé `_productionBaseUrl` de `http://51.159.110.4:8005` vers `http://51.159.110.4:8000`
- ✅ Service Flutter adapté pour gérer les deux formats de réponse

### 2. **Nouveaux Endpoints Ajoutés**
```python
# Endpoints de compatibilité frontend
GET /api/exercises                    # Liste des exercices
POST /api/sessions/create            # Créer une session
GET /api/sessions                    # Liste des sessions
GET /api/sessions/{session_id}       # Détails d'une session
POST /api/sessions/{session_id}/end  # Terminer une session
GET /api/sessions/{session_id}/analysis # Analyse de session
```

### 3. **Fichiers Modifiés**
- `services/eloquence-api/app.py` - API principale avec nouveaux endpoints
- `frontend/flutter_app/lib/config/api_config.dart` - Configuration corrigée
- `frontend/flutter_app/lib/services/eloquence_conversation_service.dart` - Service adaptatif
- `scripts/redeploy-eloquence-api.sh` - Script de redéploiement

---

## 🎯 PLAN DE DÉPLOIEMENT

### Phase 1 : Déploiement Local (Test)
```bash
# 1. Redéployer l'API avec les nouveaux endpoints
./scripts/redeploy-eloquence-api.sh

# 2. Vérifier les endpoints localement
curl http://localhost:8000/health
curl http://localhost:8000/api/exercises
curl http://localhost:8000/api/sessions
```

### Phase 2 : Déploiement Scaleway (Production)
```bash
# 1. Se connecter au serveur Scaleway
ssh root@51.159.110.4

# 2. Aller dans le répertoire du projet
cd /path/to/eloquence

# 3. Mettre à jour le code
git pull origin main

# 4. Redéployer le service
docker-compose stop eloquence-api
docker-compose build eloquence-api
docker-compose up -d eloquence-api

# 5. Vérifier le déploiement
curl http://localhost:8000/health
curl http://localhost:8000/api/exercises
```

---

## 🧪 TESTS DE VALIDATION

### Tests Automatiques (Script)
Le script `redeploy-eloquence-api.sh` effectue automatiquement :
- ✅ Health check
- ✅ Test endpoint `/api/exercises`
- ✅ Test endpoint `/api/sessions`
- ✅ Test création de session
- ✅ Test récupération de session

### Tests Manuels Complémentaires
```bash
# Test complet de création et gestion de session
curl -X POST http://51.159.110.4:8000/api/sessions/create \
  -H "Content-Type: application/json" \
  -d '{"exercise_type":"conversation","user_id":"test_user"}'

# Récupérer l'ID de session et tester les autres endpoints
SESSION_ID="session_xxxxxxxxxx"
curl http://51.159.110.4:8000/api/sessions/$SESSION_ID
curl -X POST http://51.159.110.4:8000/api/sessions/$SESSION_ID/end
curl http://51.159.110.4:8000/api/sessions/$SESSION_ID/analysis
```

---

## 📊 ENDPOINTS DISPONIBLES APRÈS DÉPLOIEMENT

### 🟢 Endpoints Frontend (Compatibilité)
| Méthode | Endpoint | Description | Status |
|---------|----------|-------------|---------|
| GET | `/api/exercises` | Liste des exercices | ✅ Nouveau |
| POST | `/api/sessions/create` | Créer session | ✅ Nouveau |
| GET | `/api/sessions` | Liste sessions | ✅ Nouveau |
| GET | `/api/sessions/{id}` | Détails session | ✅ Nouveau |
| POST | `/api/sessions/{id}/end` | Terminer session | ✅ Nouveau |
| GET | `/api/sessions/{id}/analysis` | Analyse session | ✅ Nouveau |

### 🔵 Endpoints API v1 (Existants)
| Méthode | Endpoint | Description | Status |
|---------|----------|-------------|---------|
| GET | `/api/v1/exercises/templates` | Templates exercices | ✅ Existant |
| POST | `/api/v1/exercises/sessions` | Créer session v1 | ✅ Existant |
| WebSocket | `/api/v1/exercises/realtime/{id}` | Temps réel | ✅ Existant |

---

## 🔍 VALIDATION POST-DÉPLOIEMENT

### 1. **Vérification Santé Services**
```bash
# Health check principal
curl http://51.159.110.4:8000/health

# Health check détaillé
curl http://51.159.110.4:8000/health/services
```

### 2. **Test Frontend**
```bash
# Test format exercices (doit retourner 4 exercices)
curl http://51.159.110.4:8000/api/exercises | jq '. | length'

# Vérification format JSON correct
curl http://51.159.110.4:8000/api/exercises | jq '.[0]'
```

### 3. **Test Sessions Complètes**
```bash
# Créer session
RESPONSE=$(curl -s -X POST http://51.159.110.4:8000/api/sessions/create \
  -H "Content-Type: application/json" \
  -d '{"exercise_type":"conversation","user_id":"test_deploy"}')

# Extraire session ID
SESSION_ID=$(echo $RESPONSE | jq -r '.session_id')

# Tester tous les endpoints de session
curl http://51.159.110.4:8000/api/sessions/$SESSION_ID
curl -X POST http://51.159.110.4:8000/api/sessions/$SESSION_ID/end
curl http://51.159.110.4:8000/api/sessions/$SESSION_ID/analysis
```

---

## 🚨 ROLLBACK EN CAS DE PROBLÈME

### Rollback Rapide
```bash
# 1. Revenir à la version précédente
git checkout HEAD~1

# 2. Redéployer l'ancienne version
docker-compose stop eloquence-api
docker-compose build eloquence-api
docker-compose up -d eloquence-api

# 3. Vérifier que le service fonctionne
curl http://51.159.110.4:8000/health
```

### Rollback Configuration Frontend
```bash
# Remettre l'ancienne configuration si nécessaire
# Dans frontend/flutter_app/lib/config/api_config.dart
# Changer de nouveau vers le port 8005 si problème
```

---

## 📈 MÉTRIQUES DE SUCCÈS

### Critères de Validation
- ✅ Health check répond 200
- ✅ `/api/exercises` retourne 4 exercices
- ✅ `/api/sessions/create` crée une session
- ✅ `/api/sessions` liste les sessions
- ✅ Pas d'erreur JSON côté frontend
- ✅ Temps de réponse < 2 secondes

### Monitoring Post-Déploiement
```bash
# Surveiller les logs
docker-compose logs -f eloquence-api

# Vérifier l'utilisation des ressources
docker stats eloquence-api

# Tester périodiquement
watch -n 30 'curl -s http://51.159.110.4:8000/health'
```

---

## 🎉 RÉSULTAT ATTENDU

Après le déploiement réussi :

1. **✅ Problème JSON résolu** - Le frontend peut récupérer les exercices sans erreur
2. **✅ Sessions fonctionnelles** - Création et gestion des sessions opérationnelles  
3. **✅ Compatibilité maintenue** - Les anciens endpoints v1 continuent de fonctionner
4. **✅ Performance optimale** - Temps de réponse améliorés
5. **✅ Monitoring actif** - Surveillance continue des services

---

## 📞 SUPPORT ET DÉPANNAGE

### Logs Utiles
```bash
# Logs API Eloquence
docker-compose logs eloquence-api

# Logs Redis
docker-compose logs redis

# Logs complets
docker-compose logs
```

### Commandes de Diagnostic
```bash
# Vérifier les conteneurs
docker-compose ps

# Vérifier les ports
netstat -tlnp | grep :8000

# Tester connectivité Redis
docker-compose exec redis redis-cli ping
```

### Contacts
- **Développeur** : Support technique disponible
- **Documentation** : Voir `ANALYSE_ENDPOINTS_SCALEWAY.md`
- **Monitoring** : Dashboard disponible sur le port 8080

---

## 🔗 LIENS UTILES

- **API Documentation** : http://51.159.110.4:8000/docs
- **Health Check** : http://51.159.110.4:8000/health
- **Exercices** : http://51.159.110.4:8000/api/exercises
- **Sessions** : http://51.159.110.4:8000/api/sessions

---

**Status Final** : 🎯 **PRÊT POUR DÉPLOIEMENT EN PRODUCTION**
