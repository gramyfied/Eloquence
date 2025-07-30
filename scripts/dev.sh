#!/bin/bash
set -e

echo "🚀 Démarrage environnement de développement Eloquence"

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker non installé"
    exit 1
fi

# Nettoyer environnement précédent
echo "🧹 Nettoyage environnement..."
docker-compose -f docker-compose-new.yml down -v 2>/dev/null || true

# Construire et démarrer services
echo "🏗️ Construction des services..."
docker-compose -f docker-compose-new.yml build

echo "▶️ Démarrage des services..."
docker-compose -f docker-compose-new.yml up -d

# Attendre que les services soient prêts
echo "⏳ Attente des services..."
sleep 30

# Vérifier santé des services
echo "🔍 Vérification santé des services..."
curl -f http://localhost:8080/health || echo "⚠️ API principale non accessible"
curl -f http://localhost:8002/health || echo "⚠️ Vosk STT non accessible"
curl -f http://localhost:8001/health || echo "⚠️ Mistral non accessible"

echo "✅ Environnement de développement prêt !"
echo "📱 API principale: http://localhost:8080"
echo "🎤 Vosk STT: http://localhost:8002"
echo "🤖 Mistral: http://localhost:8001"
echo "🔴 Redis: localhost:6379"
echo "📺 LiveKit: ws://localhost:7880"
echo ""
echo "📋 Commandes utiles:"
echo "  ./scripts/logs.sh          - Voir tous les logs"
echo "  ./scripts/logs.sh [service] - Logs d'un service"
echo "  ./scripts/stop.sh          - Arrêter l'environnement"
