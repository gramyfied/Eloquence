#!/bin/bash

# Script de déploiement direct de l'API Eloquence sur Scaleway
# Ce script copie et redémarre l'API avec les nouveaux endpoints

echo "🚀 Déploiement de l'API Eloquence mise à jour sur Scaleway"
echo "============================================================"

# Configuration Scaleway
SCALEWAY_IP="51.159.110.4"
SCALEWAY_USER="root"
API_PORT="8005"

echo "📋 Étape 1: Copie du fichier API mis à jour"
scp services/eloquence-api/app.py ${SCALEWAY_USER}@${SCALEWAY_IP}:/opt/eloquence/services/eloquence-api/app.py

if [ $? -eq 0 ]; then
    echo "✅ Fichier API copié avec succès"
else
    echo "❌ Erreur lors de la copie du fichier API"
    exit 1
fi

echo "📋 Étape 2: Redémarrage du service API sur Scaleway"
ssh ${SCALEWAY_USER}@${SCALEWAY_IP} << 'EOF'
    cd /opt/eloquence
    
    # Arrêter le service actuel
    echo "🛑 Arrêt du service API..."
    pkill -f "uvicorn.*app:app.*8005" || true
    sleep 2
    
    # Redémarrer le service
    echo "🚀 Redémarrage du service API..."
    cd services/eloquence-api
    nohup python -m uvicorn app:app --host 0.0.0.0 --port 8005 > /var/log/eloquence-api.log 2>&1 &
    
    sleep 3
    
    # Vérifier que le service est démarré
    if pgrep -f "uvicorn.*app:app.*8005" > /dev/null; then
        echo "✅ Service API redémarré avec succès"
    else
        echo "❌ Erreur lors du redémarrage du service API"
        exit 1
    fi
EOF

if [ $? -eq 0 ]; then
    echo "✅ Service redémarré avec succès sur Scaleway"
else
    echo "❌ Erreur lors du redémarrage sur Scaleway"
    exit 1
fi

echo "📋 Étape 3: Test de l'API mise à jour"
sleep 5

# Test de santé
echo "🔍 Test de santé de l'API..."
HEALTH_RESPONSE=$(curl -s http://${SCALEWAY_IP}:${API_PORT}/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ API en bonne santé"
else
    echo "❌ Problème de santé de l'API: $HEALTH_RESPONSE"
fi

# Test des exercices
echo "🔍 Test de la liste des exercices..."
EXERCISES_RESPONSE=$(curl -s http://${SCALEWAY_IP}:${API_PORT}/api/exercises)
echo "📊 Réponse exercices: $EXERCISES_RESPONSE"

# Test de création de session
echo "🔍 Test de création de session..."
SESSION_RESPONSE=$(curl -s -X POST http://${SCALEWAY_IP}:${API_PORT}/api/sessions/create \
    -H "Content-Type: application/json" \
    -d '{"exercise_type": "conversation", "user_id": "test_user"}')
echo "📊 Réponse session: $SESSION_RESPONSE"

echo ""
echo "🎉 Déploiement terminé !"
echo "🌐 API accessible sur: http://${SCALEWAY_IP}:${API_PORT}"
echo "📚 Documentation: http://${SCALEWAY_IP}:${API_PORT}/docs"
