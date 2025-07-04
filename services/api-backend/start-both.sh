#!/bin/bash
set -e

echo "==================================="
echo "Démarrage Backend + Agent LiveKit"
echo "==================================="

# Démarrer le backend Flask en arrière-plan
echo "🚀 Démarrage du backend Flask..."
python wsgi.py &
FLASK_PID=$!
echo "✅ Backend Flask démarré (PID: $FLASK_PID)"

# Attendre un peu que Flask démarre
sleep 3

# Diagnostic du répertoire
echo "📁 Répertoire actuel: $(pwd)"
echo "📂 Contenu du répertoire services:"
ls -la services/ || echo "❌ Répertoire services introuvable"

# Démarrer l'agent LiveKit directement avec logs de diagnostic
echo "🚀 Démarrage de l'agent LiveKit..."
if [ -f "services/real_time_voice_agent_force_audio.py" ]; then
    echo "✅ Fichier agent trouvé, démarrage..."
    python services/real_time_voice_agent_force_audio.py &
    AGENT_PID=$!
    echo "✅ Agent LiveKit démarré (PID: $AGENT_PID)"
else
    echo "❌ Fichier agent non trouvé dans services/, recherche dans le bon répertoire..."
    echo "🔍 Recherche du fichier agent..."
    find . -name "*real_time_voice_agent*" -type f
    echo "💡 Le fichier agent devrait se trouver dans: services/real_time_voice_agent_force_audio.py"
    exit 1
fi

# Attendre un peu pour voir les logs de démarrage
sleep 3
echo "📋 Vérification que l'agent démarre correctement..."

# Fonction de nettoyage
cleanup() {
    echo "🛑 Arrêt des processus..."
    kill $FLASK_PID $AGENT_PID 2>/dev/null || true
    wait $FLASK_PID $AGENT_PID 2>/dev/null || true
    echo "✅ Processus arrêtés"
}

# Capturer les signaux d'arrêt
trap cleanup SIGTERM SIGINT

echo "✅ Backend et Agent démarrés - En attente..."

# Attendre que les processus se terminent
wait $FLASK_PID $AGENT_PID

