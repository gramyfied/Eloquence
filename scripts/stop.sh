#!/bin/bash
echo "🛑 Arrêt environnement Eloquence..."
docker-compose -f docker-compose-new.yml down -v
echo "✅ Environnement arrêté"
