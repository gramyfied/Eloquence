# Configuration Frontend pour Connexion Distante

## Vue d'ensemble

Votre frontend Flutter a été configuré pour se connecter automatiquement au backend sur votre serveur distant (IP: 51.159.110.4).

## Configuration Actuelle

### 1. Configuration API (frontend/lib/config/api_config.dart)
- **URL locale** : `http://localhost:8000`
- **URL distante** : `http://51.159.110.4:8000`
- **Détection automatique** : L'application utilise par défaut l'URL distante

### 2. Service API (frontend/lib/services/api_service.dart)
- Gestion automatique des timeouts
- Test de connectivité au démarrage
- Gestion d'erreurs améliorée
- Retry automatique en cas d'échec

### 3. Interface Utilisateur
- Indicateur de statut de connexion
- Affichage de l'URL du serveur utilisé
- Bouton de reconnexion en cas d'échec

## Comment Utiliser

### 1. Démarrage de l'Application
L'application va automatiquement :
1. Tester la connexion au serveur distant (51.159.110.4:8000)
2. Afficher le statut de connexion
3. Charger les données si la connexion réussit

### 2. Changement d'Environnement
Pour modifier l'URL du serveur, éditez le fichier `frontend/lib/config/api_config.dart` :

```dart
// Pour utiliser un autre serveur
static const String _productionApiUrl = 'http://VOTRE_NOUVELLE_IP:8000';

// Pour forcer l'utilisation locale en développement
static String get baseUrl {
  if (kDebugMode) {
    return _localApiUrl; // Utilise localhost
  } else {
    return _productionApiUrl; // Utilise le serveur distant
  }
}
```

### 3. Vérification de la Connexion
- L'icône verte (☁️) indique une connexion réussie
- L'icône rouge (☁️) indique un échec de connexion
- Cliquez sur le bouton de rafraîchissement pour réessayer

## Prérequis Serveur

### 1. Backend en Fonctionnement

#### Option A: Avec Docker (Recommandé)
```bash
# Sur votre serveur (51.159.110.4)
cd /path/to/your/project
./start_backend.sh
```

#### Option B: Démarrage manuel avec Docker Compose
```bash
# Sur votre serveur (51.159.110.4)
cd /path/to/your/project
docker-compose up -d --build backend-api redis
```

#### Option C: Démarrage direct Python (pour développement)
```bash
# Sur votre serveur (51.159.110.4)
cd /path/to/your/backend
python main.py
```

**PROBLÈME IDENTIFIÉ**: D'après vos tests, le backend sur le port 8000 n'est pas accessible. Le service backend-api n'était pas configuré dans docker-compose.yml. J'ai ajouté la configuration manquante.

### 2. Port Ouvert
Le port 8000 doit être ouvert sur votre serveur :
```bash
# Vérifier si le port est ouvert
sudo ufw status
sudo ufw allow 8000
```

### 3. Configuration CORS
Le backend doit autoriser les requêtes cross-origin. Dans `backend/main.py` :
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Tests de Connectivité

### 1. Test Manuel
Vous pouvez tester la connexion manuellement :
```bash
# Test de base
curl http://51.159.110.4:8000/health

# Test de l'API
curl http://51.159.110.4:8000/api/items
```

### 2. Test depuis l'Application
- Ouvrez l'application Flutter
- Vérifiez l'indicateur de statut
- Utilisez le bouton "Actualiser" pour tester la connexion

## Dépannage

### 1. Connexion Échouée
Si la connexion échoue :
1. Vérifiez que le backend est démarré
2. Vérifiez que le port 8000 est ouvert
3. Testez avec curl depuis votre machine locale
4. Vérifiez les logs du backend

### 2. Timeout
Si les requêtes sont lentes :
- Augmentez les timeouts dans `api_config.dart`
- Vérifiez la latence réseau

### 3. Erreurs CORS
Si vous avez des erreurs CORS :
- Vérifiez la configuration CORS du backend
- Ajoutez votre domaine frontend aux origines autorisées

## Commandes Utiles

### Démarrer le Backend
```bash
cd backend
python main.py
```

### Compiler le Frontend Flutter
```bash
cd frontend
flutter build web
```

### Servir le Frontend
```bash
cd frontend
flutter run -d web-server --web-port 3000
```

## Sécurité

### Pour la Production
1. Remplacez `allow_origins=["*"]` par votre domaine spécifique
2. Utilisez HTTPS au lieu de HTTP
3. Configurez un reverse proxy (nginx)
4. Utilisez des certificats SSL

### Configuration HTTPS
Pour une configuration sécurisée, modifiez `api_config.dart` :
```dart
static const String _productionApiUrl = 'https://51.159.110.4:8000';
```

## Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs de l'application Flutter
2. Vérifiez les logs du backend Python
3. Testez la connectivité réseau
4. Vérifiez la configuration des ports et du firewall
