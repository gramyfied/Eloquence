# Documentation Docker - Eloquence

## Structure organisée

### Fichiers principaux
- `docker-compose.yml` : Configuration par défaut (services de base)
- `docker-compose.override.yml` : Overrides locaux (ne pas commiter)

### Configurations spécialisées
- `docker/compose/docker-compose.base.yml` : Services de base (Redis, APIs, LiveKit, Vosk, Mistral, etc.)
- `docker/compose/docker-compose.multiagent.yml` : Système multi-agents (Votre focus)
- `docker/compose/docker-compose.production.yml` : Configuration production sécurisée
- `docker/compose/docker-compose.monitoring.yml` : Monitoring (Prometheus, Grafana)

### Dockerfiles
- `docker/dockerfiles/livekit-agent.multiagent.Dockerfile` : Système multi-agents
- `docker/dockerfiles/livekit-agent.basic.Dockerfile` : Version basique

## Commandes essentielles

### Démarrer le système multi-agents (recommandé)
```bash
# Si vous testez depuis un appareil physique (mobile), exportez votre IP LAN
# Exemple Windows PowerShell:
$env:HOST_LAN_IP = "192.168.1.50"
# Exemple Linux/macOS:
export HOST_LAN_IP=192.168.1.50

docker compose -f docker-compose.yml -f docker/compose/docker-compose.multiagent.yml up -d

# Voir les logs
docker compose logs -f livekit-agent-multiagent

# Redémarrer seulement l'agent
docker compose restart livekit-agent-multiagent
```

### Développement
```bash
# Services de base (avec IP LAN pour accès depuis mobile)
# Windows PowerShell
$env:HOST_LAN_IP = "192.168.1.50"; docker compose up -d
# Linux/macOS
HOST_LAN_IP=192.168.1.50 docker compose up -d
docker compose up -d

# Avec monitoring
docker compose -f docker-compose.yml -f docker/compose/docker-compose.monitoring.yml up -d
```

### Production
```bash
docker compose -f docker-compose.yml -f docker/compose/docker-compose.production.yml up -d
```

## Variables d'environnement requises
Créer un fichier `.env` à la racine:
```bash
OPENAI_API_KEY=your_openai_key
MISTRAL_API_KEY=your_mistral_key
MISTRAL_MODEL=mistral-nemo-instruct-2407
LIVEKIT_API_KEY=APIkey1234567890
LIVEKIT_API_SECRET=secret1234567890
```

## Notes
- Les fichiers obsolètes ont été déplacés dans `docker/backup/` pour référence.
- Le réseau `eloquence-network` est partagé par défaut entre les services.

