#!/bin/bash

# Script pour démarrer le backend Eloquence
echo "🚀 Démarrage du backend Eloquence..."

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez installer Docker d'abord."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez installer Docker Compose d'abord."
    exit 1
fi

# Aller dans le répertoire du projet
cd "$(dirname "$0")"

echo "📁 Répertoire de travail: $(pwd)"

# Arrêter les services existants
echo "🛑 Arrêt des services existants..."
docker-compose down

# Construire et démarrer uniquement le backend et Redis
echo "🔨 Construction et démarrage du backend..."
docker-compose up -d --build backend-api redis

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 10

# Vérifier le statut des services
echo "📊 Vérification du statut des services..."
docker-compose ps

# Tester la connectivité
echo "🔍 Test de connectivité..."
echo "Backend API (port 8000):"
curl -f http://localhost:8000/health 2>/dev/null && echo "✅ Backend accessible" || echo "❌ Backend non accessible"

echo "Redis (port 6379):"
docker-compose exec redis redis-cli ping 2>/dev/null && echo "✅ Redis accessible" || echo "❌ Redis non accessible"

echo ""
echo "🎉 Backend démarré !"
echo "📍 API disponible sur: http://localhost:8000"
echo "📍 Documentation API: http://localhost:8000/docs"
echo "📍 Health check: http://localhost:8000/health"
echo ""
echo "📝 Pour voir les logs: docker-compose logs -f backend-api"
echo "🛑 Pour arrêter: docker-compose down"
