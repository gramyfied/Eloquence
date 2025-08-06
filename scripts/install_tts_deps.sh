#!/bin/bash
# Installation des dépendances TTS pour les tests d'intégration

echo "🔊 Installation des dépendances TTS..."

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 non trouvé!"
    exit 1
fi

# Installer pyttsx3 (TTS local)
echo "📦 Installation pyttsx3 (TTS local)..."
pip3 install pyttsx3

# Installer gTTS (TTS internet, fallback)
echo "📦 Installation gTTS (TTS internet)..."
pip3 install gtts

# Installer aiohttp pour les tests API
echo "📦 Installation aiohttp..."
pip3 install aiohttp

echo "✅ Installation terminée!"
echo ""
echo "🚀 Pour lancer les tests:"
echo "   python3 test_livekit_ia_integration.py"
echo ""
echo "📋 Prérequis:"
echo "   - Services Docker en cours: docker-compose up -d"
echo "   - Vosk STT disponible sur port 8002"
echo "   - Mistral IA disponible sur port 8001"