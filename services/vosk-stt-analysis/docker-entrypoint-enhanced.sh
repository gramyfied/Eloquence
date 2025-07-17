#!/bin/bash
set -e

echo "🚀 Démarrage service Vosk Eloquence avec auto-download"

# Configuration
VOSK_ENVIRONMENT=${VOSK_ENVIRONMENT:-production}
MODELS_DIR=${MODELS_DIR:-/app/models}

# Fonction de vérification des modèles
check_models() {
    echo "🔍 Vérification des modèles existants..."
    
    if [ "$VOSK_ENVIRONMENT" = "production" ]; then
        required_model="vosk-model-fr-large-0.22"
    elif [ "$VOSK_ENVIRONMENT" = "development" ]; then
        required_model="vosk-model-fr-small-0.22"
    else
        required_model="vosk-model-en-us-0.22" # Modèle par défaut pour multilingue
    fi
    
    model_path="$MODELS_DIR/$required_model"
    
    if [ -d "$model_path" ] && [ "$(ls -A $model_path)" ]; then
        echo "✅ Modèle $required_model déjà présent"
        return 0
    else
        echo "❌ Modèle $required_model manquant"
        return 1
    fi
}

# Fonction de téléchargement conditionnel
download_if_needed() {
    if ! check_models; then
        echo "📦 Téléchargement automatique des modèles..."
        
        python3 /app/vosk_auto_download_script.py \
            --environment "$VOSK_ENVIRONMENT" \
            --models-dir "$MODELS_DIR"
        
        if [ $? -eq 0 ]; then
            echo "✅ Modèles téléchargés avec succès"
        else
            echo "❌ Erreur téléchargement des modèles"
            exit 1
        fi
    else
        echo "✅ Modèles déjà présents, pas de téléchargement nécessaire"
    fi
}

# Fonction de démarrage du service existant
start_existing_service() {
    echo "🚀 Démarrage du service Vosk existant..."
    
    # Commande de démarrage existante identifiée
    exec uvicorn app:app --host 0.0.0.0 --port 8001 --workers 4
}

# Exécution principale
main() {
    echo "🔄 Initialisation service Vosk Eloquence..."
    
    # Téléchargement conditionnel
    download_if_needed
    
    # Démarrage service existant
    start_existing_service
}

# Gestion des signaux
trap 'echo "🛑 Arrêt service Vosk..."; exit 0' SIGTERM SIGINT

# Point d'entrée
main "$@"
