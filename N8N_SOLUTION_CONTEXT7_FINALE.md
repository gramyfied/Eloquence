# N8N - Solution Définitive avec Context7

## 🎯 SOLUTION TROUVÉE VIA CONTEXT7

Grâce à la documentation officielle N8N via Context7, j'ai identifié la **solution exacte** au problème d'authentification 401.

### 🔍 Problème Diagnostiqué
- **Erreur 401 Unauthorized** persistante
- N8N n'a pas été correctement initialisé avec le premier utilisateur
- Les tentatives de setup via API REST ont échoué

### ✅ SOLUTION OFFICIELLE N8N

La documentation N8N indique une commande CLI spécifique pour ce problème :

```bash
n8n user-management:reset
```

**Description officielle** : "This command resets n8n's user management system to its initial pre-setup state, effectively removing all existing user accounts. It is particularly useful for regaining access if you forget your password and do not have SMTP configured for email-based password resets."

## 🛠️ ÉTAPES DE RÉSOLUTION

### Étape 1: Réinitialiser le Système de Gestion des Utilisateurs
```bash
# Accéder au conteneur N8N
docker exec -u node -it n8n-app n8n user-management:reset
```

### Étape 2: Redémarrer N8N
```bash
cd /opt/n8n && docker-compose restart n8n
```

### Étape 3: Accéder à l'Interface de Setup
```bash
# Ouvrir le navigateur sur
http://dashboard-n8n.eu
```

### Étape 4: Créer le Premier Utilisateur
Via l'interface web, créer le premier utilisateur avec :
- **Email** : admin@dashboard-n8n.eu
- **Mot de passe** : N8n_Dashboard_Secure_2025_Admin
- **Prénom** : Admin
- **Nom** : N8N

## 🔧 COMMANDES COMPLÈTES

### Solution Complète en Une Fois
```bash
# 1. Réinitialiser le système utilisateur
docker exec -u node -it n8n-app n8n user-management:reset

# 2. Redémarrer N8N
cd /opt/n8n && docker-compose restart n8n

# 3. Attendre que les services soient prêts
sleep 30

# 4. Vérifier l'état
docker-compose ps
```

### Alternative : Reset Complet si Nécessaire
```bash
# Si le reset simple ne fonctionne pas, reset complet
cd /opt/n8n
docker-compose down
docker volume rm n8n_n8n_data
docker-compose up -d
```

## 📋 AUTRES COMMANDES CLI UTILES (VIA CONTEXT7)

### Diagnostic et Maintenance
```bash
# Vérifier les informations de licence
docker exec -u node -it n8n-app n8n license:info

# Audit de sécurité
docker exec -u node -it n8n-app n8n audit

# Désactiver MFA pour un utilisateur spécifique
docker exec -u node -it n8n-app n8n mfa:disable --email=admin@dashboard-n8n.eu
```

### Exécution de Workflows
```bash
# Exécuter un workflow par ID
docker exec -u node -it n8n-app n8n execute --id <WORKFLOW_ID>

# Exécution en lot pour tests
docker exec -u node -it n8n-app n8n executeBatch --help
```

## 🎯 CONFIGURATION FRONTEND FLUTTER

### Mise à Jour API Config
```dart
// frontend/lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://dashboard-n8n.eu';
  static const String n8nApiUrl = '$baseUrl/api/v1';
  static const String n8nRestUrl = '$baseUrl/rest';
  
  // Headers pour N8N
  static Map<String, String> get n8nHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
```

### Service N8N Complet
```dart
// frontend/lib/services/n8n_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class N8nService {
  static const String _baseUrl = ApiConfig.baseUrl;
  
  // Connexion utilisateur
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
  
  // Vérifier l'état de l'instance
  Future<Map<String, dynamic>> getInstanceStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/rest/login'),
      headers: ApiConfig.n8nHeaders,
    );
    
    return {
      'statusCode': response.statusCode,
      'body': response.body,
    };
  }
  
  // Créer le premier utilisateur (owner setup)
  Future<Map<String, dynamic>> setupOwner({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rest/owner/setup'),
      headers: ApiConfig.n8nHeaders,
      body: jsonEncode({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur setup owner: ${response.statusCode}');
    }
  }
}
```

## 🚀 PROCHAINES ÉTAPES

1. **Appliquer la commande reset** : `docker exec -u node -it n8n-app n8n user-management:reset`
2. **Redémarrer N8N** : `docker-compose restart n8n`
3. **Tester l'accès web** : http://dashboard-n8n.eu
4. **Créer le premier utilisateur** via l'interface
5. **Intégrer le service N8N** dans Flutter
6. **Tester la connexion** frontend-backend

## 📞 SUPPORT CONTEXT7

Cette solution a été trouvée grâce à **Context7** qui a fourni :
- Documentation officielle N8N
- Commandes CLI exactes
- Solutions recommandées par l'équipe N8N
- Exemples de configuration

## ✅ RÉSULTAT ATTENDU

Après application de cette solution :
- ✅ N8N sera réinitialisé à l'état pré-setup
- ✅ Interface de création du premier utilisateur disponible
- ✅ Connexion 401 résolue
- ✅ Frontend Flutter pourra se connecter au backend N8N
- ✅ Système d'authentification fonctionnel

---
*Solution trouvée via Context7 - Documentation officielle N8N*
*Date : 31/07/2025*
