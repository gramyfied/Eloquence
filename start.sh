#!/bin/bash

echo "🚀 DÉMARRAGE ELOQUENCE - CONFIGURATION SIMPLE"
echo "=============================================="

# Vérifier que .env existe
if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant"
    echo "Copiez env_template.txt vers .env et configurez OPENAI_API_KEY"
    exit 1
fi

# Vérifier que OPENAI_API_KEY est configurée
if ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo "❌ OPENAI_API_KEY non configurée dans .env"
    echo "Ajoutez votre vraie clé OpenAI dans le fichier .env"
    exit 1
fi

# Arrêter les services existants
echo "🛑 Arrêt des services existants..."
docker-compose down

# Nettoyer les images orphelines
echo "🧹 Nettoyage des images orphelines..."
docker system prune -f

# Construire et démarrer les services
echo "🔨 Construction et démarrage des services..."
docker-compose up --build -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier le statut des services
echo "📊 Statut des services:"
docker-compose ps

# Tester la connectivité
echo "🧪 Test de connectivité:"
echo "  Redis: $(curl -s http://localhost:6379 && echo "✅ OK" || echo "❌ ÉCHEC")"
echo "  LiveKit: $(curl -s http://localhost:7880 && echo "✅ OK" || echo "❌ ÉCHEC")"
echo "  Agent: $(curl -s http://localhost:8080/health && echo "✅ OK" || echo "❌ ÉCHEC")"

echo ""
echo "🎉 ELOQUENCE DÉMARRÉ AVEC SUCCÈS !"
echo "📱 Vous pouvez maintenant tester vos exercices"
echo "🔗 URLs importantes:"
echo "   - LiveKit: ws://localhost:7880"
echo "   - Agent: http://localhost:8080"
echo "   - API: http://localhost:8003"
