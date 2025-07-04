#!/bin/bash
# Configuration initiale Eloquence

echo "🚀 Configuration Eloquence..."

# Vérifier prérequis
command -v docker >/dev/null 2>&1 || { echo "Docker requis"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "Flutter requis"; exit 1; }

# Configuration Flutter
echo "📱 Configuration Flutter..."
cd frontend/flutter_app
flutter pub get
flutter doctor

# Configuration environnement
echo "⚙️ Configuration environnement..."
cd ../..
cp .env.example .env

# Build Docker
echo "🐳 Build services..."
docker-compose build

echo "✅ Configuration terminée !"