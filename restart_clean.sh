#!/bin/bash
# Script de redémarrage propre pour Eloquence

echo "🔄 Redémarrage propre d'Eloquence..."

# Arrêt des services
docker-compose down

# Nettoyage des fichiers compilés
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Redémarrage des services
docker-compose up -d

echo "✅ Redémarrage terminé"
echo "🎯 Le problème Thomas devrait être résolu"

