#!/bin/bash

echo "🔄 Redémarrage des services avec les corrections appliquées..."

# Aller au répertoire racine du projet
cd ../../

echo "📋 Affichage des services actuels..."
docker-compose ps

echo "🛑 Arrêt des services LiveKit Agent..."
docker-compose stop livekit-agent-multiagent

echo "🔄 Reconstruction de l'image avec les nouvelles corrections..."
docker-compose build livekit-agent-multiagent

echo "🚀 Redémarrage du service avec les corrections..."
docker-compose up -d livekit-agent-multiagent

echo "📊 Vérification du statut..."
docker-compose ps livekit-agent-multiagent

echo "📝 Affichage des derniers logs (10 dernières lignes)..."
docker-compose logs --tail=10 livekit-agent-multiagent

echo "✅ Services redémarrés avec les corrections !"
echo "🔍 Pour surveiller les logs en temps réel :"
echo "   docker-compose logs -f livekit-agent-multiagent"
