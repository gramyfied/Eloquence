#!/bin/bash

echo "🔧 REDÉMARRAGE COMPLET AVEC NETTOYAGE DOCKER"
echo "=============================================="

# 1. Arrêter tous les conteneurs
echo "🛑 Arrêt de tous les conteneurs..."
docker-compose down --remove-orphans

# 2. Nettoyer les images et caches Docker
echo "🧹 Nettoyage des caches Docker..."
docker system prune -f
docker builder prune -f

# 3. Supprimer les volumes Docker (optionnel, décommentez si nécessaire)
# echo "🗑️ Suppression des volumes Docker..."
# docker volume prune -f

# 4. Nettoyer les fichiers Python compilés
echo "🧹 Nettoyage des fichiers Python compilés..."
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# 5. Reconstruire les images Docker
echo "🔨 Reconstruction des images Docker..."
docker-compose build --no-cache livekit-agent

# 6. Redémarrer les services
echo "🚀 Redémarrage des services..."
docker-compose up -d

# 7. Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 10

# 8. Vérifier le statut
echo "📊 Vérification du statut..."
docker-compose ps

echo ""
echo "✅ REDÉMARRAGE COMPLET TERMINÉ !"
echo "🎯 Testez maintenant avec studio_debatPlateau_test"
echo "📋 Logs attendus :"
echo "   - 🚀 === UNIFIED ENTRYPOINT STARTED ==="
echo "   - ✅ Exercice détecté: studio_debate_tv"
echo "   - 🎬 DÉMARRAGE SYSTÈME DÉBAT TV"
echo "   - 🎭 Agents: Michel Dubois, Sarah Johnson, Marcus Thompson"

