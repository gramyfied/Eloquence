# 🎯 Système de Configuration Centralisée Eloquence

## 📋 Vue d'ensemble

Le système de configuration centralisée d'Eloquence est conçu pour éliminer la configuration hardcodée et fournir une **seule source de vérité** pour tous les paramètres du système. Toute modification de configuration doit être effectuée dans le fichier `eloquence.config.yaml` et les autres fichiers sont générés automatiquement.

## 🚨 RÈGLE ABSOLUE

**❌ INTERDICTION TOTALE de configuration hardcodée dans le code !**
- Tous les ports, URLs, credentials doivent venir de la configuration centralisée
- Utiliser UNIQUEMENT les fonctions d'accès autorisées
- Toute violation lèvera une erreur fatale

## 🏗️ Architecture du Système

```
config/
├── eloquence.config.yaml          # 🔑 SEULE SOURCE DE VÉRITÉ
├── config_loader.py               # 📥 Chargeur de configuration
├── config_validator.py            # ✅ Validateur de configuration
├── config_generator.py            # 🔄 Générateur de fichiers dérivés
├── config_manager.py              # 🎮 Gestionnaire principal
├── config_client.py               # 🚪 Interface client sécurisée
├── eloquence_config_cli.py        # 💻 Interface en ligne de commande
└── config_test.py                 # 🧪 Tests du système
```

## 🔑 Fichier de Configuration Principal

### Structure de `eloquence.config.yaml`

```yaml
eloquence_config:
  version: "1.0.0"
  environment: "development"
  
  # Configuration réseau centralisée
  network:
    domain: "localhost"
    ports:
      livekit_server: 7880
      livekit_tcp: 7881
      agent_http: 8080
      redis: 6379
      mistral_api: 8001
      vosk_stt: 8002
      eloquence_api: 8003
      haproxy: 8081
    
    rtc_port_range:
      start: 40000
      end: 40100
    
    docker_network: "eloquence-network"
  
  # Services et leurs configurations
  services:
    livekit_server:
      enabled: true
      image: "livekit/livekit-server:latest"
      internal_host: "livekit-server"
      external_host: "localhost"
    
    # ... autres services
  
  # URLs générées automatiquement
  urls:
    docker:
      livekit: "ws://livekit-server:7880"
      # ... autres URLs Docker
    
    external:
      livekit: "ws://localhost:7880"
      # ... autres URLs externes
  
  # Sécurité
  security:
    livekit:
      api_key: "devkey"
      api_secret: "devsecret123456789abcdef0123456789abcdef"
  
  # Configuration multi-agents
  multi_agent:
    enabled: true
    instances: 4
    ports:
      agent_1: 8011
      agent_2: 8012
      # ... autres agents
```

## 🚪 Interface Client Sécurisée

### Importation Autorisée

```python
# ✅ CORRECT - Utiliser l'interface client
from config_client import (
    get_livekit_config,
    get_services_urls,
    get_agent_config
)

# Récupérer la configuration LiveKit
livekit_config = get_livekit_config()
url = livekit_config['url']
api_key = livekit_config['api_key']

# Récupérer les URLs des services
services = get_services_urls()
redis_url = services['redis']
mistral_url = services['mistral']
```

### Importation Interdite

```python
# ❌ INTERDIT - Configuration hardcodée
LIVEKIT_URL = "ws://localhost:7880"  # Erreur fatale !
LIVEKIT_API_KEY = "devkey"           # Erreur fatale !
MISTRAL_BASE_URL = "http://localhost:8001"  # Erreur fatale !
```

## 🎮 Gestionnaire de Configuration

### Utilisation du Gestionnaire Principal

```python
from config_manager import get_config_manager

# Obtenir l'instance du gestionnaire
manager = get_config_manager()

# Résumé de la configuration
summary = manager.get_config_summary()
print(f"Version: {summary['version']}")
print(f"Services actifs: {summary['services']['enabled']}")

# Validation de la configuration
is_valid, errors, warnings = manager.validate_configuration()

# Génération des fichiers dérivés
results = manager.generate_config_files()

# Sauvegarde de la configuration
backup_path = manager.backup_configuration()

# Mise à jour d'une valeur
success = manager.update_config_value('network.ports.redis', 6380)
```

## 💻 Interface en Ligne de Commande

### Commandes Disponibles

```bash
# Afficher le statut des services
python config/eloquence_config_cli.py status

# Afficher un résumé de la configuration
python config/eloquence_config_cli.py summary

# Valider la configuration
python config/eloquence_config_cli.py validate

# Générer les fichiers de configuration
python config/eloquence_config_cli.py generate

# Génération forcée
python config/eloquence_config_cli.py generate --force

# Validation et génération automatiques
python config/eloquence_config_cli.py auto

# Créer une sauvegarde
python config/eloquence_config_cli.py backup

# Restaurer depuis une sauvegarde
python config/eloquence_config_cli.py restore --backup-path ./config_backup/backup_20241201_120000

# Mettre à jour une valeur
python config/eloquence_config_cli.py update --path network.ports.redis --value 6380

# Exporter le schéma de configuration
python config/eloquence_config_cli.py schema --output schema.json

# Afficher les informations réseau
python config/eloquence_config_cli.py network
```

## 🔄 Génération Automatique

### Fichiers Générés

Le système génère automatiquement :

1. **`docker-compose.yml`** - Configuration Docker Compose
2. **`.env`** - Variables d'environnement
3. **`livekit.yaml`** - Configuration LiveKit

### Protection des Fichiers Générés

Tous les fichiers générés contiennent un en-tête de protection :

```yaml
# =====================================================
# FICHIER GÉNÉRÉ AUTOMATIQUEMENT
# =====================================================
# ATTENTION: Ce fichier est généré automatiquement
# Ne pas modifier - Utiliser config/eloquence.config.yaml
# =====================================================
```

## ✅ Validation de Configuration

### Vérifications Automatiques

Le validateur vérifie :

- **Ports** : Valeurs valides (1-65535), pas de conflits
- **Services** : Configuration complète, hôtes internes/externes
- **URLs** : Format valide, cohérence Docker/externe
- **Sécurité** : Credentials présents, longueur des secrets
- **Multi-agents** : Ports uniques, configuration cohérente
- **Conflits** : Ports en conflit avec la plage RTC

### Exemple de Validation

```bash
python config/eloquence_config_cli.py validate
```

Sortie :
```
🔍 Validation de la configuration...
✅ Configuration valide!
🎉 Aucun problème détecté!
```

## 🧪 Tests du Système

### Lancement des Tests

```bash
# Lancer tous les tests
python config/config_test.py

# Tests unitaires spécifiques
python -m unittest config.config_test.TestConfigSystem.test_config_loader
```

### Couverture des Tests

- ✅ Chargeur de configuration
- ✅ Validateur de configuration
- ✅ Générateur de fichiers
- ✅ Gestionnaire principal
- ✅ Client de configuration
- ✅ Mise à jour de configuration
- ✅ Sauvegarde et restauration
- ✅ Export de schéma
- ✅ Gestion des erreurs
- ✅ Configuration multi-agents

## 🔧 Intégration avec les Services

### Services Supportés

- **LiveKit Server** : Serveur WebRTC
- **LiveKit Agent** : Agent d'intelligence artificielle
- **Redis** : Base de données en mémoire
- **Mistral API** : Service de conversation IA
- **Vosk STT** : Reconnaissance vocale
- **HAProxy** : Équilibreur de charge
- **Multi-agents** : Instances multiples d'agents

### Configuration des Services

Chaque service peut être :
- **Activé/Désactivé** via `enabled: true/false`
- **Configuré** avec des images Docker spécifiques
- **Personnalisé** avec des hôtes internes/externes

## 📊 Monitoring et Statut

### Vérification du Statut

```python
# Vérifier le statut des services Docker
status = manager.check_service_status()

for service_name, service_status in status.items():
    print(f"{service_name}: {service_status['status']}")
    if service_status.get('healthy'):
        print("  ✅ Service en bonne santé")
```

### Métriques Disponibles

- Statut des conteneurs Docker
- Santé des services
- Ports d'écoute
- Connexions réseau

## 🚀 Workflow de Déploiement

### 1. Configuration Initiale

```bash
# Valider la configuration
python config/eloquence_config_cli.py validate

# Générer les fichiers
python config/eloquence_config_cli.py generate

# Vérifier le statut
python config/eloquence_config_cli.py status
```

### 2. Déploiement

```bash
# Démarrer les services
docker-compose up -d

# Vérifier le statut
python config/eloquence_config_cli.py status
```

### 3. Maintenance

```bash
# Sauvegarde avant modification
python config/eloquence_config_cli.py backup

# Modifier eloquence.config.yaml
# ... éditer le fichier ...

# Valider et régénérer
python config/eloquence_config_cli.py auto

# Redémarrer les services si nécessaire
docker-compose restart
```

## 🛠️ Dépannage

### Problèmes Courants

1. **Configuration invalide**
   ```bash
   python config/eloquence_config_cli.py validate
   ```

2. **Services non accessibles**
   ```bash
   python config/eloquence_config_cli.py status
   ```

3. **Conflits de ports**
   - Vérifier `network.ports` dans la configuration
   - Vérifier `rtc_port_range` pour les conflits

4. **Fichiers manquants**
   ```bash
   python config/eloquence_config_cli.py generate --force
   ```

### Logs et Debug

```python
import logging

# Activer les logs détaillés
logging.basicConfig(level=logging.DEBUG)

# Utiliser le gestionnaire
manager = get_config_manager()
```

## 🔒 Sécurité

### Bonnes Pratiques

- ✅ Utiliser des secrets forts (minimum 32 caractères)
- ✅ Limiter l'accès au fichier de configuration
- ✅ Sauvegarder régulièrement la configuration
- ✅ Valider avant chaque déploiement
- ✅ Utiliser des variables d'environnement pour les secrets sensibles

### Variables d'Environnement

```bash
# Exemple pour la production
export ELOQUENCE_ENV=production
export LIVEKIT_API_SECRET=votre_secret_production_tres_long
```

## 📚 Références

### Fichiers Clés

- **`eloquence.config.yaml`** : Configuration maître
- **`config_client.py`** : Interface client sécurisée
- **`config_manager.py`** : Gestionnaire principal
- **`eloquence_config_cli.py`** : Interface CLI

### Fonctions Principales

- `get_livekit_config()` : Configuration LiveKit
- `get_services_urls()` : URLs des services
- `get_agent_config()` : Configuration de l'agent
- `validate_and_generate()` : Validation et génération automatiques

## 🎯 Prochaines Étapes

1. **Migration** : Remplacer toute configuration hardcodée
2. **Tests** : Valider le système avec vos services
3. **Documentation** : Adapter à votre environnement
4. **Automatisation** : Intégrer dans votre pipeline CI/CD

---

**💡 Conseil** : Commencez par valider votre configuration actuelle avec `python config/eloquence_config_cli.py validate` pour identifier les problèmes potentiels.
