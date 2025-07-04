#!/bin/bash
set -e

echo "==================================="
echo "Démarrage Agent LiveKit v1.x"
echo "==================================="

# Vérifier les variables d'environnement
echo "LIVEKIT_URL: ${LIVEKIT_URL}"
echo "LIVEKIT_API_KEY: ${LIVEKIT_API_KEY}"
echo "LiveKit SDK Version: $(pip show livekit | grep Version)"
echo "LiveKit Agents Version: $(pip show livekit-agents | grep Version)"

# Démarrer l'agent avec le nouveau framework v1.x (version avec corrections appliquées)
echo "Lancement de l'agent LiveKit v1.x (Docker Fixed)..."
echo "Répertoire actuel: $(pwd)"
echo "Contenu du répertoire:"
ls -la
echo "Tentative de lancement du script Python..."
echo "Test 1: Vérification de Python..."
python --version
echo "Test 2: Test d'importation asyncio..."
python -c "import asyncio; print('asyncio OK')"
echo "Test 3: Test d'importation livekit..."
python -c "import livekit; print('livekit OK')"
echo "Test 4: Test d'importation agents..."
python -c "from livekit import agents; print('agents OK')"
echo "Test 5: Lancement du script principal..."
echo "🚀 Agent LiveKit démarré - En attente de connexions..."
python -u services/real_time_voice_agent_force_audio_fixed.py
