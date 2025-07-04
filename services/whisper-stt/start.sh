#!/bin/bash
set -e

echo "🚀 Vérification et téléchargement de Whisper Large-v3-Turbo..."
python whisper-download-models-turbo.py

echo "🎯 Démarrage du service ASR Whisper Large-v3-Turbo (8x plus rapide)..."
exec python whisper_asr_service.py