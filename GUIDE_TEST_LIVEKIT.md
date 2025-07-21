# 🧪 Guide de Test - Connectivité LiveKit complète

## ✅ **Étape 1 : Démarrage des services**

```bash
# Arrêter tous les services
docker-compose down

# Démarrer tous les services avec le nouveau livekit-token-service
docker-compose up -d

# Vérifier que tous les services sont démarrés
docker-compose ps
```

**Vérification attendue** :
- `livekit-token-service` (port 8004) : **healthy**
- `api-backend` (port 8000) : **healthy**
- `livekit` (port 7880) : **healthy**
- `eloquence-eloquence-agent-v1-1` : **running**

## ✅ **Étape 2 : Test des endpoints LiveKit**

### Test du service de tokens
```bash
# Test health check du service token
curl http://localhost:8004/health

# Test génération de token via API backend
curl -X POST http://localhost:8000/api/livekit/generate-token \
  -H "Content-Type: application/json" \
  -d '{"room_name":"test-room","participant_name":"test-user"}'

# Test configuration LiveKit
curl http://localhost:8000/api/livekit/config
```

**Réponses attendues** :
```json
// Health check
{"status":"healthy","service":"livekit-token-generator"}

// Token generation  
{"token":"eyJ...","url":"ws://localhost:7880","room":"test-room"}

// Config
{"livekit_url":"ws://localhost:7880","supports_token_auth":true}
```

## ✅ **Étape 3 : Vérification Agent LiveKit v1**

```bash
# Vérifier que l'agent v1 est actif
docker logs eloquence-eloquence-agent-v1-1 --tail 20

# Vérifier les logs du serveur LiveKit
docker logs livekit --tail 20
```

**Logs attendus** :
- Agent v1 : `[INFO] Agent started successfully`
- LiveKit : `[INFO] Server listening on :7880`

## ✅ **Étape 4 : Test Flutter avec nouveau système**

### Option A : Test via Flutter directement
```bash
cd frontend/flutter_app

# Lancer l'app Flutter 
flutter run

# Dans l'app :
# 1. Aller dans "Confidence Boost"
# 2. Démarrer une session
# 3. Observer les logs console
```

### Option B : Test via commandes curl simulant Flutter
```bash
# Simuler une requête Flutter de création de session
curl -X POST http://localhost:8000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-flutter-user",
    "scenario_id": "demo-1", 
    "language": "fr"
  }'
```

## ✅ **Étape 5 : Validation des logs (crucial)**

### Logs à surveiller :

#### 1. **API Backend** (succès LiveKit)
```bash
docker logs api-backend --tail 50 | grep -i livekit
```
**Attendu** :
```
[SUCCESS] Token généré avec succès
[SUCCESS] LiveKit initialized successfully with new token
✅ AGENT CONNECTÉ avec succès
```

#### 2. **Flutter App** (plus de fallbacks constants)
```bash
# Dans les logs Flutter/console
```
**Attendu** :
```
[LIVEKIT_TOKEN] Token généré avec succès
[SUCCESS] RobustLiveKitService LiveKit initialized successfully
[SUCCESS] Primary LiveKit analysis SUCCESS
```

**❌ Plus attendu** :
```
[WARNING] Service in cooldown, using fallback immediately  
[SHIELD] Creating guaranteed emergency fallback
[CACHE] Cache hit! Returning cached result
```

## ✅ **Étape 6 : Test de performance**

### Test de charge simple
```bash
# Générer plusieurs tokens rapidement
for i in {1..5}; do
  curl -X POST http://localhost:8000/api/livekit/generate-token \
    -H "Content-Type: application/json" \
    -d "{\"room_name\":\"test-room-$i\",\"participant_name\":\"user-$i\"}" &
done
wait

echo "✅ Test de charge terminé"
```

### Vérifier pas de circuit breaker activé
```bash
# Les 5 requêtes doivent réussir sans fallback
docker logs api-backend --tail 20 | grep -E "(SUCCESS|WARNING|ERROR)"
```

## ✅ **Étape 7 : Test scenarios critiques**

### Scénario 1 : Connexion normale Flutter
1. **Action** : Démarrer session via Flutter
2. **Attendu** : Connexion LiveKit directe sans fallback
3. **Logs** : `[SUCCESS] Primary LiveKit analysis SUCCESS`

### Scénario 2 : Test de robustesse  
1. **Action** : Arrêter temporairement le service token
   ```bash
   docker stop livekit-token-service
   ```
2. **Attendu** : Flutter utilise les fallbacks intelligents
3. **Action** : Redémarrer le service
   ```bash
   docker start livekit-token-service
   ```
4. **Attendu** : Flutter reconnecte automatiquement à LiveKit

### Scénario 3 : Test mobile simulation
```bash
# Tester avec des timeouts plus courts (simulation mobile lente)
curl -X POST http://localhost:8000/api/livekit/generate-token \
  -H "Content-Type: application/json" \
  -d '{"room_name":"mobile-test","participant_name":"mobile-user"}' \
  --max-time 2
```

## 🎯 **Critères de réussite**

### ✅ **Succès total** si :
1. **Tokens générés** en < 1 seconde
2. **Agent v1 connecté** automatiquement  
3. **Flutter se connecte** sans fallback constant
4. **Logs montrent** : "PRIMARY LiveKit analysis SUCCESS"
5. **Circuit breaker** ne s'active pas sur usage normal

### ❌ **Échec** si :
1. Fallbacks constants (`[SHIELD]` répétés)
2. Timeouts fréquents (`Connection timeout`)
3. Circuit breaker activé (`Service in cooldown`)
4. Tokens non générés (`Token generation failed`)

## 🔧 **Debugging en cas de problème**

### Service token ne démarre pas :
```bash
docker logs livekit-token-service
# Vérifier les variables d'environnement LIVEKIT_API_KEY/SECRET
```

### Flutter n'arrive pas à se connecter :
```bash
# Vérifier que l'URL est accessible depuis Flutter
curl http://localhost:8000/api/livekit/health
```

### Agent v1 non connecté :
```bash
docker logs eloquence-eloquence-agent-v1-1
# Vérifier que MistralLLM et OpenAI TTS sont configurés
```

---

**🎉 Si tous les tests passent : Votre système LiveKit v1 est opérationnel !**
Flutter se connectera directement à votre agent sophistiqué sans fallbacks constants.