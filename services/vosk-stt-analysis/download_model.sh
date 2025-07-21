#!/bin/bash

MODEL_DIR="/app/models"
MODEL_NAME="vosk-model-fr-0.22"
MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-fr-0.22.zip"

echo "🔍 Vérification du modèle Vosk français..."

if [ ! -d "$MODEL_DIR/$MODEL_NAME" ]; then
    echo "📥 Téléchargement du modèle Vosk français..."
    mkdir -p "$MODEL_DIR"
    cd "$MODEL_DIR"
    
    # Téléchargement avec retry
    for i in {1..3}; do
        if wget -O "$MODEL_NAME.zip" "$MODEL_URL"; then
            echo "✅ Téléchargement réussi"
            break
        else
            echo "❌ Échec tentative $i/3"
            sleep 5
        fi
    done
    
    # Décompression
    if [ -f "$MODEL_NAME.zip" ]; then
        echo "📦 Décompression du modèle..."
        unzip -q "$MODEL_NAME.zip"
        rm "$MODEL_NAME.zip"
        echo "✅ Modèle installé : $MODEL_DIR/$MODEL_NAME"
    else
        echo "❌ Échec du téléchargement du modèle"
        exit 1
    fi
else
    echo "✅ Modèle déjà présent : $MODEL_DIR/$MODEL_NAME"
fi