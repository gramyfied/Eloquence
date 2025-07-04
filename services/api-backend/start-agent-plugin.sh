#!/bin/bash

# Script de démarrage de l'agent avec le plugin OpenAI officiel

echo "🚀 Démarrage de l'agent LiveKit avec plugin OpenAI..."
echo "📅 $(date)"

# Vérifier les variables d'environnement
echo -e "\n📋 Vérification des variables d'environnement..."

check_env_var() {
    if [ -z "${!1}" ]; then
        echo "❌ $1 n'est pas définie!"
        return 1
    else
        if [[ "$1" == *"KEY"* ]] || [[ "$1" == *"SECRET"* ]]; then
            echo "✅ $1: ***${!1: -4}"
        else
            echo "✅ $1: ${!1}"
        fi
        return 0
    fi
}

# Variables requises
REQUIRED_VARS=(
    "LIVEKIT_URL"
    "LIVEKIT_API_KEY"
    "LIVEKIT_API_SECRET"
    "OPENAI_API_KEY"
    "MISTRAL_API_KEY"
)

ALL_VARS_SET=true
for var in "${REQUIRED_VARS[@]}"; do
    if ! check_env_var "$var"; then
        ALL_VARS_SET=false
    fi
done

if [ "$ALL_VARS_SET" = false ]; then
    echo -e "\n❌ Des variables d'environnement sont manquantes!"
    echo "Veuillez les définir dans votre fichier .env"
    exit 1
fi

# Définir le répertoire de travail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "\n📂 Répertoire de travail: $(pwd)"

# Vérifier que le fichier existe
AGENT_FILE="services/real_time_voice_agent_with_plugin.py"
if [ ! -f "$AGENT_FILE" ]; then
    echo "❌ Fichier non trouvé: $AGENT_FILE"
    exit 1
fi

echo "✅ Fichier agent trouvé: $AGENT_FILE"

# Installer les dépendances si nécessaire
echo -e "\n📦 Vérification des dépendances..."
if ! python -c "import livekit.plugins.openai" 2>/dev/null; then
    echo "⚠️  Plugin OpenAI non installé, installation..."
    pip install livekit-plugins-openai
fi

# Démarrer l'agent
echo -e "\n🎯 Démarrage de l'agent avec plugin OpenAI..."
echo "📟 Commande: python $AGENT_FILE dev"
echo -e "\n" + "="*60

# Exécuter l'agent
exec python "$AGENT_FILE" dev