# N8N - Problème d'Authentification - Diagnostic et Solutions

## 🔍 DIAGNOSTIC COMPLET

### Problème Identifié
- **Erreur 401 Unauthorized** persistante lors de la connexion N8N
- Les vrais identifiants configurés ne fonctionnent pas
- N8N n'a pas été correctement initialisé avec le premier utilisateur

### Configuration Actuelle
- **Domaine** : dashboard-n8n.eu
- **Email configuré** : admin@dashboard-n8n.eu
- **Mot de passe configuré** : N8n_Dashboard_Secure_2025_Admin
- **Services** : Tous les conteneurs Docker sont UP et HEALTHY

## 🛠️ SOLUTIONS TESTÉES

### 1. Correction Configuration Trust Proxy
```bash
# Ajout des variables manquantes dans .env
N8N_TRUST_PROXY=true
N8N_RUNNERS_ENABLED=true
```

### 2. Redémarrage Services
```bash
cd /opt/n8n && /opt/n8n/scripts/n8n-manager.sh restart
```

### 3. Tentative Setup Premier Utilisateur
```bash
curl -X POST http://dashboard-n8n.eu/rest/owner/setup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@dashboard-n8n.eu",
    "firstName": "Admin",
    "lastName": "N8N",
    "password": "N8n_Dashboard_Secure_2025_Admin"
  }'
```

## 🔧 SOLUTIONS RECOMMANDÉES

### Solution 1: Réinitialisation Base de Données
```bash
# Arrêter N8N
cd /opt/n8n && docker-compose down

# Supprimer les volumes de données
docker volume rm n8n_postgres_data n8n_n8n_data

# Redémarrer
docker-compose up -d
```

### Solution 2: Configuration Directe via Variables d'Environnement
Ajouter dans `/opt/n8n/.env` :
```env
# Désactiver l'authentification temporairement
N8N_USER_MANAGEMENT_DISABLED=true

# Ou forcer la création du premier utilisateur
N8N_OWNER_EMAIL=admin@dashboard-n8n.eu
N8N_OWNER_PASSWORD=N8n_Dashboard_Secure_2025_Admin
N8N_OWNER_FIRST_NAME=Admin
N8N_OWNER_LAST_NAME=N8N
```

### Solution 3: Accès Direct au Conteneur
```bash
# Accéder au conteneur N8N
docker exec -it n8n-app /bin/sh

# Créer l'utilisateur via CLI N8N
n8n user:create --email=admin@dashboard-n8n.eu --password=N8n_Dashboard_Secure_2025_Admin --firstName=Admin --lastName=N8N
```

### Solution 4: Configuration HTTPS
Le problème peut venir du fait que N8N attend HTTPS. Configurer SSL :
```bash
# Générer certificats SSL
cd /opt/n8n/nginx/ssl && ./generate-certs.sh

# Modifier .env pour utiliser HTTPS
N8N_PROTOCOL=https
N8N_HOST=dashboard-n8n.eu
WEBHOOK_URL=https://dashboard-n8n.eu/
```

## 📋 ÉTAPES DE RÉSOLUTION PRIORITAIRES

### Étape 1: Vérification État Actuel
```bash
# Vérifier les logs N8N
docker logs n8n-app --tail 50

# Vérifier la base de données
docker exec -it n8n-postgres psql -U n8n_user -d n8n_production -c "SELECT * FROM user;"
```

### Étape 2: Test API Setup
```bash
# Tester si l'endpoint setup est disponible
curl -v http://dashboard-n8n.eu/rest/owner/setup

# Tester l'état de l'instance
curl -v http://dashboard-n8n.eu/rest/login
```

### Étape 3: Réinitialisation Complète (si nécessaire)
```bash
# Sauvegarde des workflows existants (si applicable)
docker exec n8n-app n8n export:workflow --all --output=/tmp/workflows.json

# Reset complet
cd /opt/n8n
docker-compose down -v
docker-compose up -d
```

## 🎯 CONFIGURATION FRONTEND POUR N8N

### Mise à jour API Config Flutter
```dart
// frontend/lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://dashboard-n8n.eu';
  static const String n8nApiUrl = '$baseUrl/api/v1';
  
  // Headers pour N8N
  static Map<String, String> get n8nHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

### Service N8N Flutter
```dart
// frontend/lib/services/n8n_service.dart
class N8nService {
  static const String _baseUrl = ApiConfig.baseUrl;
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rest/login'),
      headers: ApiConfig.n8nHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de connexion N8N: ${response.statusCode}');
    }
  }
}
```

## 🚀 PROCHAINES ÉTAPES

1. **Diagnostic approfondi** des logs N8N
2. **Test des endpoints** API N8N
3. **Réinitialisation** si nécessaire
4. **Configuration HTTPS** pour sécuriser
5. **Intégration frontend** Flutter avec N8N
6. **Tests de connexion** complets

## 📞 SUPPORT

Si le problème persiste :
- Vérifier la documentation N8N officielle
- Consulter les logs détaillés
- Envisager une installation fraîche de N8N
- Contacter le support N8N si nécessaire

---
*Document créé le 31/07/2025 - Diagnostic complet N8N*
