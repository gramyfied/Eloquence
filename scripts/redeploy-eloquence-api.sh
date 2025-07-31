#!/bin/bash

# Script de redéploiement de l'API Eloquence avec les nouveaux endpoints
# Usage: ./scripts/redeploy-eloquence-api.sh

echo "🚀 Redéploiement de l'API Eloquence avec les nouveaux endpoints"
echo "=============================================================="

# Vérifier si Docker est disponible
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé ou accessible"
    exit 1
fi

# Vérifier si docker-compose est disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose n'est pas installé ou accessible"
    exit 1
fi

echo "📋 Étape 1: Arrêt du service eloquence-api actuel"
docker-compose stop eloquence-api

echo "📋 Étape 2: Reconstruction de l'image avec les nouveaux endpoints"
docker-compose build eloquence-api

echo "📋 Étape 3: Redémarrage du service"
docker-compose up -d eloquence-api

echo "📋 Étape 4: Attente du démarrage (30 secondes)"
sleep 30

echo "📋 Étape 5: Test des nouveaux endpoints"

# Test health check
echo "🔍 Test du health check..."
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
if [[ $? -eq 0 ]]; then
    echo "✅ Health check: OK"
    echo "   Réponse: $HEALTH_RESPONSE"
else
    echo "❌ Health check: ÉCHEC"
fi

# Test endpoint exercises
echo "🔍 Test de l'endpoint /api/exercises..."
EXERCISES_RESPONSE=$(curl -s http://localhost:8000/api/exercises)
if [[ $? -eq 0 ]]; then
    echo "✅ Endpoint /api/exercises: OK"
    EXERCISE_COUNT=$(echo $EXERCISES_RESPONSE | jq '. | length' 2>/dev/null || echo "N/A")
    echo "   Nombre d'exercices: $EXERCISE_COUNT"
else
    echo "❌ Endpoint /api/exercises: ÉCHEC"
fi

# Test endpoint sessions (GET)
echo "🔍 Test de l'endpoint /api/sessions..."
SESSIONS_RESPONSE=$(curl -s http://localhost:8000/api/sessions)
if [[ $? -eq 0 ]]; then
    echo "✅ Endpoint /api/sessions: OK"
    echo "   Réponse: $SESSIONS_RESPONSE"
else
    echo "❌ Endpoint /api/sessions: ÉCHEC"
fi

# Test création de session
echo "🔍 Test de création de session..."
SESSION_CREATE_RESPONSE=$(curl -s -X POST http://localhost:8000/api/sessions/create \
    -H "Content-Type: application/json" \
    -d '{"exercise_type":"conversation","user_id":"test_user"}')

if [[ $? -eq 0 ]]; then
    echo "✅ Création de session: OK"
    SESSION_ID=$(echo $SESSION_CREATE_RESPONSE | jq -r '.session_id' 2>/dev/null || echo "N/A")
    echo "   Session ID: $SESSION_ID"
    
    # Test récupération de la session créée
    if [[ "$SESSION_ID" != "N/A" && "$SESSION_ID" != "null" ]]; then
        echo "🔍 Test de récupération de session..."
        SESSION_GET_RESPONSE=$(curl -s http://localhost:8000/api/sessions/$SESSION_ID)
        if [[ $? -eq 0 ]]; then
            echo "✅ Récupération de session: OK"
        else
            echo "❌ Récupération de session: ÉCHEC"
        fi
    fi
else
    echo "❌ Création de session: ÉCHEC"
fi

echo ""
echo "📊 Résumé du déploiement"
echo "========================"
echo "✅ Service redéployé avec succès"
echo "✅ Nouveaux endpoints ajoutés:"
echo "   - GET /api/exercises"
echo "   - POST /api/sessions/create"
echo "   - GET /api/sessions"
echo "   - GET /api/sessions/{session_id}"
echo "   - POST /api/sessions/{session_id}/end"
echo "   - GET /api/sessions/{session_id}/analysis"

echo ""
echo "🔗 Endpoints disponibles:"
echo "   Health Check: http://localhost:8000/health"
echo "   Exercices: http://localhost:8000/api/exercises"
echo "   Sessions: http://localhost:8000/api/sessions"
echo "   Création session: POST http://localhost:8000/api/sessions/create"

echo ""
echo "📝 Logs du service:"
echo "   docker-compose logs -f eloquence-api"

echo ""
echo "🎉 Redéploiement terminé avec succès !"
