#!/bin/bash
# services/vosk-stt-analysis/download_models.sh

set -e

MODEL_DIR="/app/models"
mkdir -p $MODEL_DIR

echo "🚀 Téléchargement des modèles Vosk..."

# Modèle français large (1.5GB) - Performance maximale
if [ ! -d "$MODEL_DIR/vosk-model-fr-large-0.22" ]; then
    echo "📥 Téléchargement modèle français large..."
    wget -O /tmp/vosk-model-fr-large-0.22.zip \
        https://alphacephei.com/vosk/models/vosk-model-fr-large-0.22.zip
    unzip /tmp/vosk-model-fr-large-0.22.zip -d $MODEL_DIR
    rm /tmp/vosk-model-fr-large-0.22.zip
fi

# Modèle français small (50MB) - Fallback rapide
if [ ! -d "$MODEL_DIR/vosk-model-fr-small-0.22" ]; then
    echo "📥 Téléchargement modèle français small..."
    wget -O /tmp/vosk-model-fr-small-0.22.zip \
        https://alphacephei.com/vosk/models/vosk-model-fr-small-0.22.zip
    unzip /tmp/vosk-model-fr-small-0.22.zip -d $MODEL_DIR
    rm /tmp/vosk-model-fr-small-0.22.zip
fi

# Modèle speaker identification (optionnel)
if [ ! -d "$MODEL_DIR/vosk-model-spk-0.4" ]; then
    echo "📥 Téléchargement modèle speaker identification..."
    wget -O /tmp/vosk-model-spk-0.4.zip \
        https://alphacephei.com/vosk/models/vosk-model-spk-0.4.zip
    unzip /tmp/vosk-model-spk-0.4.zip -d $MODEL_DIR
    rm /tmp/vosk-model-spk-0.4.zip
fi

echo "✅ Tous les modèles Vosk téléchargés"