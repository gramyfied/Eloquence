# Gestionnaire Réseau Eloquence

Un gestionnaire réseau intelligent qui centralise la gestion de toutes les routes, endpoints, URLs et clés API avec détection automatique d'erreurs et validation des nouveaux exercices pour l'application Eloquence (coaching vocal).

## 🌟 Fonctionnalités

### Gestionnaire Réseau Principal
- ✅ **Monitoring intelligent** des services avec circuit breakers
- ✅ **Détection automatique** de l'architecture (principale/alternative/hybride)
- ✅ **Auto-réparation** des services défaillants via Docker
- ✅ **Pool de connexions HTTP** optimisé avec aiohttp
- ✅ **Support WebSocket** pour LiveKit
- ✅ **Intégration Redis** pour le cache
- ✅ **Métriques de performance** en temps réel
- ✅ **Rapports JSON** détaillés

### Validateur d'Exercices
- ✅ **Détection automatique** des exercices dans le code (Flutter/Python/JavaScript)
- ✅ **Validation de compatibilité** avec l'architecture réseau
- ✅ **Score de complétude** (0-100%) pour chaque exercice
- ✅ **Recommandations** d'optimisation personnalisées
- ✅ **Estimation du temps** de correction
- ✅ **Monitoring continu** des exercices

### Interface CLI Complète
- ✅ **Commandes intuitives** pour toutes les opérations
- ✅ **Affichage coloré** avec indicateurs visuels
- ✅ **Mode monitoring** en temps réel
- ✅ **Export JSON** des rapports
- ✅ **Auto-réparation** en une commande

## 🚀 Installation

### Prérequis
- Python 3.8+
- Docker (optionnel, pour l'auto-réparation)
- Services Eloquence démarrés

### Installation des dépendances
```bash
cd eloquence_network_manager
pip install -r requirements.txt
```

### Configuration des variables d'environnement
```bash
# Copiez .env.example vers .env et configurez
export LIVEKIT_API_KEY=devkey
export LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef
export LIVEKIT_URL=ws://localhost:7880
export MISTRAL_API_KEY=your_mistral_api_key_here
export SCALEWAY_MISTRAL_URL=https://api.scaleway.ai/[ID]/v1
```

## 📋 Utilisation

### Vérification Rapide
```bash
python3 eloquence_network_manager.py --check
```
```
🌐 Gestionnaire Réseau Eloquence - Vérification Complète

✅ eloquence_exercises_api (95ms) - Healthy
✅ livekit_server (85ms) - Healthy  
✅ livekit_token_service (120ms) - Healthy
✅ vosk_stt (450ms) - Healthy
❌ mistral_conversation (timeout) - Unhealthy
✅ redis (15ms) - Healthy

📊 Score de Santé Global: 83%
🔧 1 action recommandée: Redémarrer mistral_conversation
```

### Monitoring Continu
```bash
python3 eloquence_network_manager.py --monitor 60
```
```
[14:30:15] ✅ Score: 95% | Services: 6/6
[14:31:15] ⚠️ Score: 83% | Services: 5/6
  └─ mistral_conversation: timeout (Request timeout)
[14:32:15] ✅ Score: 100% | Services: 6/6
```

### Auto-Réparation
```bash
python3 eloquence_network_manager.py --fix
```
```
🔧 Correction automatique des problèmes...

✅ Actions entreprises:
  - Redémarré le service Docker: mistral-conversation
  - Timeout ajusté pour vosk_stt: 30s → 45s
  - Nettoyage du cache Redis effectué
```

### Rapport Complet
```bash
python3 eloquence_network_manager.py --report --output rapport.json
```

### Validation des Exercices

#### Scanner les exercices
```bash
python3 exercise_validator.py --scan
```
```
🔍 Scan des exercices dans: .

✅ 6 exercices détectés:

📋 cosmic_voice_screen
  └─ Type: cosmic
  └─ Fichier: lib/features/confidence_boost/cosmic_voice_screen.dart:5
  └─ Langage: flutter
  └─ Services requis: livekit_server, livekit_token_service, vosk_stt, eloquence_exercises_api

📋 confidence_boost_screen
  └─ Type: confidence
  └─ Fichier: lib/features/confidence_boost/confidence_boost_screen.dart:12
  └─ Langage: flutter
  └─ Services requis: mistral_conversation, eloquence_exercises_api
```

#### Valider un exercice spécifique
```bash
python3 exercise_validator.py --validate cosmic_voice_screen
```
```
✅ Validation: cosmic_voice_screen

🔍 Architecture: Principale
📊 Score de complétude: 85%
✅ Valide: True
⏱️ Temps estimé: 2 heures

🔧 Actions requises:
- Optimiser timeout service mistral_conversation
- Ajouter gestion d'erreur WebSocket LiveKit

💡 Recommandations:
- Implémenter un mécanisme de fallback pour les services critiques
- Ajouter une vérification de compatibilité WebRTC
```

#### Validation complète
```bash
python3 exercise_validator.py --validate-all
```
```
🔍 Validation de tous les exercices

📊 Résumé global:
  └─ Exercices valides: 4/6
  └─ Score moyen: 78.3%

✅ cosmic_voice_screen (85%)
✅ confidence_boost_screen (92%)
✅ breathing_exercise (88%)
✅ articulation_exercise (75%)
❌ conversation_exercise (45%)
  └─ Actions: Configurer et démarrer le service mistral_conversation
❌ voice_simulation (50%)
  └─ Actions: Vérifier la connectivité réseau vers livekit_server
```

#### Monitoring des exercices
```bash
python3 exercise_validator.py --monitor 300
```
```
🔄 Monitoring continu des exercices (intervalle: 300s)

[14:30:00] ✅ Exercices: 6/6 valides
[14:35:00] ⚠️ Exercices: 4/6 valides
  └─ cosmic_voice_screen: Optimiser timeout service vosk_stt
  └─ conversation_exercise: Redémarrer le service mistral_conversation
```

## 🏗️ Architecture

### Services Détectés Automatiquement

#### Services Critiques (docker-compose.yml)
- **eloquence_exercises_api** (http://localhost:8005) - API exercices spécialisés
- **livekit_server** (ws://localhost:7880) - Communication temps réel WebSocket
- **livekit_token_service** (http://localhost:8004) - Génération tokens LiveKit
- **vosk_stt** (http://localhost:8002) - Reconnaissance vocale
- **mistral_conversation** (http://localhost:8001) - IA conversationnelle
- **redis** (redis://localhost:6379) - Cache

#### Services Fallback (app_config.dart)
- **tts_service** (http://localhost:5002) - Service TTS fallback
- **whisper_stt** (http://localhost:8001) - Service STT Whisper fallback
- **llm_service_fallback** (http://localhost:8000) - Service LLM fallback

### Types d'Architecture Détectés
- **Principale** : ≥4 services critiques actifs
- **Alternative** : ≥2 services fallback actifs
- **Hybride** : Mix services principaux + fallback
- **Dégradée** : <2 services critiques actifs

## 🧪 Tests

### Exécuter tous les tests
```bash
cd tests
python -m pytest -v
```

### Tests avec couverture
```bash
python -m pytest --cov=.. --cov-report=html tests/
```

### Tests spécifiques
```bash
# Tests du gestionnaire réseau
python -m pytest tests/test_network_manager.py -v

# Tests du validateur d'exercices
python -m pytest tests/test_exercise_validator.py -v
```

## 📊 Configuration

### Structure du fichier eloquence_network_config.yaml
```yaml
services:
  - name: eloquence_exercises_api
    type: http
    url: http://localhost:8005
    health_endpoint: /health
    timeout: 10
    critical: true
    dependencies: [redis, livekit_server]
    docker_service: eloquence-exercises-api

monitoring:
  health_check_interval: 30
  retry_attempts: 3
  circuit_breaker_threshold: 5
  circuit_breaker_timeout: 60

exercise_patterns:
  flutter:
    - "class\\s+(\\w+)Screen\\s*extends\\s*StatefulWidget"
    - "class\\s+(\\w+)Exercise\\s*extends\\s*StatefulWidget"

service_keywords:
  voice: [vosk_stt, eloquence_exercises_api]
  cosmic: [livekit_server, livekit_token_service, vosk_stt, eloquence_exercises_api]
  conversation: [mistral_conversation, livekit_server, eloquence_exercises_api]
```

## 🔧 Fonctionnalités Avancées

### Circuit Breakers
- **Seuil automatique** : 5 échecs consécutifs
- **Timeout configurable** : 60 secondes par défaut
- **États** : fermé/ouvert/semi-ouvert
- **Récupération automatique**

### Auto-Réparation
- **Redémarrage Docker** des services défaillants
- **Ajustement automatique** des timeouts
- **Nettoyage cache Redis** si nécessaire
- **Régénération tokens** expirés

### Métriques de Performance
- **Temps de réponse** moyen/min/max par service
- **Score de fiabilité** (% de succès)
- **Tendances** (amélioration/dégradation)
- **Utilisation système** (CPU/RAM/Disque)

## 📈 Exemples de Rapports

### Rapport JSON Complet
```json
{
  "metadata": {
    "generated_at": "2024-01-15T14:30:00Z",
    "manager_version": "1.0.0"
  },
  "current_status": {
    "global_health_score": 85.0,
    "services": {
      "eloquence_exercises_api": {
        "status": "healthy",
        "response_time": 95.5
      }
    }
  },
  "performance_analysis": {
    "avg_response_times": {
      "eloquence_exercises_api": {
        "avg": 120.5,
        "min": 85.0,
        "max": 200.0
      }
    },
    "reliability_scores": {
      "eloquence_exercises_api": 98.5
    }
  },
  "recommendations": [
    "✅ Système en bonne santé - Aucune action requise"
  ]
}
```

## 🚨 Dépannage

### Problèmes Courants

#### Services non détectés
```bash
# Vérifier Docker
docker ps

# Vérifier la configuration
python3 eloquence_network_manager.py --check

# Forcer la détection
python3 eloquence_network_manager.py --fix
```

#### Timeouts fréquents
```bash
# Ajuster les timeouts automatiquement
python3 eloquence_network_manager.py --fix

# Monitoring pour identifier le problème
python3 eloquence_network_manager.py --monitor 30
```

#### Exercices non validés
```bash
# Re-scanner le projet
python3 exercise_validator.py --scan --project-path /chemin/vers/projet

# Vérifier les services requis
python3 exercise_validator.py --validate nom_exercice
```

### Logs de Debug
```bash
# Activer les logs détaillés
export PYTHONPATH=.
python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)
from eloquence_network_manager import EloquenceNetworkManager
"
```

## 🤝 Contribution

### Structure du Projet
```
eloquence_network_manager/
├── eloquence_network_manager.py    # Gestionnaire principal
├── exercise_validator.py           # Validateur d'exercices  
├── eloquence_network_config.yaml   # Configuration auto-générée
├── requirements.txt                # Dépendances Python
├── README.md                       # Cette documentation
└── tests/
    ├── test_network_manager.py     # Tests gestionnaire
    └── test_exercise_validator.py  # Tests validateur
```

### Ajouter un Nouveau Type de Service
1. Éditer `eloquence_network_config.yaml`
2. Ajouter la méthode `_check_{type}_health()` 
3. Mettre à jour les tests
4. Documenter le nouveau service

### Ajouter un Nouveau Type d'Exercice
1. Ajouter aux `exercise_patterns` dans la config
2. Mettre à jour `service_keywords` 
3. Ajouter des tests de détection
4. Documenter le pattern

## 📜 Licence

Ce projet fait partie d'Eloquence et suit la même licence.

## 🆘 Support

Pour toute question ou problème :
1. Vérifier cette documentation
2. Consulter les logs avec `--monitor`
3. Exécuter les tests pour valider l'installation
4. Utiliser `--fix` pour les corrections automatiques

---

**Version** : 1.0.0  
**Dernière mise à jour** : Janvier 2024  
**Compatibilité** : Eloquence Architecture Unique (docker-compose.yml)