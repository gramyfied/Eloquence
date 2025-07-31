# Configuration Frontend pour Connexion Backend Distant

## 🎯 CONFIGURATION MINIMALE REQUISE

### 1. Configuration API de Base

**URL du Backend N8N** : `http://dashboard-n8n.eu`

**Endpoints principaux** :
- Login : `POST /rest/login`
- API Workflows : `/api/v1/workflows`
- Health Check : `/healthz`

### 2. Structure d'Authentification N8N

**Login Request** :
```json
{
  "emailOrLdapLoginId": "admin@dashboard-n8n.eu",
  "password": "N8n_Dashboard_Secure_2025_Admin"
}
```

**Headers requis** :
```
Content-Type: application/json
Accept: application/json
```

### 3. Configuration Flutter Minimale

**pubspec.yaml** - Dépendance HTTP :
```yaml
dependencies:
  http: ^1.1.0
```

**Configuration API simple** :
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://dashboard-n8n.eu';
  static const String loginEndpoint = '/rest/login';
  static const String apiEndpoint = '/api/v1';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

### 4. Test de Connexion Simple

**Commande curl de test** :
```bash
curl -X POST http://dashboard-n8n.eu/rest/login \
  -H "Content-Type: application/json" \
  -d '{
    "emailOrLdapLoginId": "admin@dashboard-n8n.eu",
    "password": "N8n_Dashboard_Secure_2025_Admin"
  }'
```

### 5. Gestion CORS (si nécessaire)

Si vous rencontrez des erreurs CORS depuis Flutter Web, ajoutez dans votre configuration N8N :

```yaml
# docker-compose.yml
environment:
  - N8N_CORS_ORIGIN=*
  - N8N_CORS_CREDENTIALS=true
```

### 6. Configuration Réseau

**Vérifications réseau** :
- ✅ Port 80 ouvert sur le serveur
- ✅ DNS `dashboard-n8n.eu` résolu
- ✅ Nginx configuré pour proxy N8N
- ✅ N8N accessible via HTTP

### 7. Authentification Basique

**Flux d'authentification** :
1. POST vers `/rest/login` avec identifiants
2. Récupération du token/cookie de session
3. Utilisation du token pour les requêtes API suivantes

### 8. Endpoints API Utiles

**Workflows** :
- `GET /api/v1/workflows` - Liste des workflows
- `POST /api/v1/workflows/{id}/execute` - Exécuter un workflow
- `GET /api/v1/executions` - Historique d'exécution

**Instance** :
- `GET /healthz` - Vérifier l'état de N8N
- `GET /rest/settings` - Informations de l'instance

## 🔧 RÉSOLUTION DES PROBLÈMES

### Problème d'Authentification 401
**Solution appliquée** : Reset avec Context7
```bash
sudo docker exec -u node -it n8n-app n8n user-management:reset
sudo docker-compose restart n8n
```

### Erreur de Champ Login
**Problème** : `"email"` non reconnu
**Solution** : Utiliser `"emailOrLdapLoginId"` à la place

### Test de Connectivité
```bash
# Test simple de connectivité
curl -I http://dashboard-n8n.eu/healthz

# Test de l'API de login
curl -X POST http://dashboard-n8n.eu/rest/login \
  -H "Content-Type: application/json" \
  -d '{"emailOrLdapLoginId":"admin@dashboard-n8n.eu","password":"N8n_Dashboard_Secure_2025_Admin"}'
```

## ✅ ÉTAT ACTUEL

- ✅ N8N déployé sur `dashboard-n8n.eu`
- ✅ Problème d'authentification résolu avec Context7
- ✅ Premier utilisateur créé
- ✅ API accessible via HTTP
- ✅ Structure d'authentification identifiée

## 🚀 PROCHAINES ÉTAPES

1. **Tester la connexion** avec la bonne structure de login
2. **Implémenter l'authentification** dans votre frontend
3. **Gérer les tokens/cookies** de session
4. **Créer des workflows** de test
5. **Tester l'exécution** depuis le frontend

---
*Configuration simplifiée pour connexion frontend-backend*
*Solution N8N avec Context7 - 31/07/2025*
