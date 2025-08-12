#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Migration de la structure Docker Eloquence"

# Créer nouvelle structure
mkdir -p docker/compose docker/dockerfiles docker/backup

# Sauvegarder anciens fichiers
cp docker-compose*.yml docker/backup/ 2>/dev/null || true

# Déplacer fichiers essentiels
if [ -f docker-compose.yml ]; then mv -f docker-compose.yml docker/compose/docker-compose.base.yml; fi
if [ -f docker-compose.multiagent.yml ]; then mv -f docker-compose.multiagent.yml docker/compose/docker-compose.multiagent.yml; fi
if [ -f docker-compose.production.yml ]; then mv -f docker-compose.production.yml docker/compose/docker-compose.production.yml; fi

# Déplacer Dockerfiles
if [ -f services/livekit-agent/Dockerfile.multiagent ]; then mv -f services/livekit-agent/Dockerfile.multiagent docker/dockerfiles/livekit-agent.multiagent.Dockerfile; fi

# Créer nouveau docker-compose.yml principal
cat > docker-compose.yml << 'EOF'
version: '3.8'
include:
  - docker/compose/docker-compose.base.yml
EOF

echo "✅ Migration terminée. Vérifiez docker/README.md pour les instructions."

