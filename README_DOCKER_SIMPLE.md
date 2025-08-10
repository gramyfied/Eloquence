# 🚀 ELOQUENCE - Configuration Docker Simple

## ✨ NOUVELLE CONFIGURATION PROPRE ET FONCTIONNELLE

Après le nettoyage complet de la configuration Docker complexe, voici la nouvelle architecture **SIMPLE** qui fonctionne :

## 🏗️ ARCHITECTURE SIMPLIFIÉE

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│  LiveKit Agent  │────│  OpenAI API     │
│   (Port 8080)   │    │   (Port 8080)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│  LiveKit Server │    │      Redis      │
│   (Port 7880)   │    │   (Port 6379)   │
└─────────────────┘    └─────────────────┘
```

## 🚀 DÉMARRAGE RAPIDE

### 1. Configuration de l'environnement
```bash
# Copier le template d'environnement
cp env_template.txt .env

# Éditer .env et ajouter votre vraie clé OpenAI
# OPENAI_API_KEY=sk-proj-VOTRE_VRAIE_CLE_ICI
```

### 2. Démarrer les services
```bash
# Windows PowerShell
.\start.ps1

# Linux/Mac
./start.sh
```

## 🔧 SERVICES INCLUS

| Service | Port | Description |
|---------|------|-------------|
| **LiveKit Server** | 7880 | Serveur de streaming WebRTC |
| **LiveKit Agent** | 8080 | Agent IA pour les exercices |
| **Redis** | 6379 | Base de données en mémoire |
| **Flutter App** | 8080 | Interface utilisateur |

## ❌ CE QUI A ÉTÉ SUPPRIMÉ

- ❌ **4 agents multiples** → 1 seul agent simple
- ❌ **HAProxy** → Communication directe
- ❌ **Services inutiles** → Vosk, Mistral, etc.
- ❌ **Dockerfiles multiples** → 1 Dockerfile par service
- ❌ **Configuration générée** → Fichiers statiques simples

## ✅ AVANTAGES DE LA NOUVELLE CONFIGURATION

- ✅ **Simple** : 4 services au lieu de 10+
- ✅ **Fiable** : Pas de complexité inutile
- ✅ **Maintenable** : Code lisible et modulaire
- ✅ **Performant** : Communication directe entre services
- ✅ **Débogable** : Logs clairs et erreurs explicites

## 🧪 TEST DE FONCTIONNEMENT

Après le démarrage, testez :

1. **Connectivité Redis** : `http://localhost:6379`
2. **Serveur LiveKit** : `ws://localhost:7880`
3. **Agent IA** : `http://localhost:8080/health`
4. **Application Flutter** : Ouvrez l'app et testez un exercice

## 🆘 DÉPANNAGE

### Problème : "Agent non disponible"
```bash
# Vérifier les logs de l'agent
docker-compose logs livekit-agent

# Redémarrer le service
docker-compose restart livekit-agent
```

### Problème : "Connexion LiveKit échouée"
```bash
# Vérifier que LiveKit Server fonctionne
docker-compose logs livekit-server

# Vérifier la configuration livekit.yaml
```

### Problème : "Clé OpenAI invalide"
```bash
# Vérifier le fichier .env
cat .env | grep OPENAI_API_KEY

# S'assurer que la clé commence par "sk-proj-"
```

## 🔄 MAINTENANCE

### Arrêter les services
```bash
docker-compose down
```

### Mettre à jour les images
```bash
docker-compose pull
docker-compose up -d
```

### Nettoyer l'espace disque
```bash
docker system prune -a
```

---

## 🎯 RÉSULTAT FINAL

**Avant** : Configuration complexe avec 4 agents + HAProxy qui ne fonctionnait pas
**Après** : Configuration simple avec 1 agent qui fonctionne parfaitement

Vos exercices Eloquence devraient maintenant fonctionner correctement avec l'IA ! 🎉
