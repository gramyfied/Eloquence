#!/bin/bash

# Script pour ajouter l'endpoint manquant POST /api/v1/sessions/create
# au serveur Scaleway en production

echo "🚀 AJOUT DE L'ENDPOINT MANQUANT AU SERVEUR SCALEWAY"
echo "=================================================="

# Configuration
SCALEWAY_IP="51.159.110.4"
SCALEWAY_PORT="8000"
SERVER_URL="http://$SCALEWAY_IP:$SCALEWAY_PORT"

echo "🌐 Serveur cible: $SERVER_URL"
echo ""

# Test de l'endpoint manquant
echo "1. Vérification de l'endpoint manquant..."
response=$(curl -s -w "%{http_code}" -o /tmp/test_response.json \
    -X POST "$SERVER_URL/api/v1/sessions/create" \
    -H "Content-Type: application/json" \
    -d '{"exercise_type":"conversation","user_id":"test"}')

status_code="${response: -3}"

if [ "$status_code" = "200" ]; then
    echo "   ✅ L'endpoint existe déjà !"
    cat /tmp/test_response.json
    exit 0
else
    echo "   ❌ L'endpoint n'existe pas (Status: $status_code)"
fi

# Test de l'endpoint de remplacement
echo ""
echo "2. Test de l'endpoint de remplacement..."
response=$(curl -s -w "%{http_code}" -o /tmp/replacement_response.json \
    -X POST "$SERVER_URL/api/confidence-boost/session" \
    -H "Content-Type: application/json" \
    -d '{"scenario":"conversation","difficulty":"medium","duration":300}')

status_code="${response: -3}"

if [ "$status_code" = "200" ]; then
    echo "   ✅ L'endpoint de remplacement fonctionne"
    echo "   📄 Réponse: $(cat /tmp/replacement_response.json)"
else
    echo "   ❌ L'endpoint de remplacement ne fonctionne pas (Status: $status_code)"
    exit 1
fi

# Créer un patch pour ajouter l'endpoint
echo ""
echo "3. Création du patch pour ajouter l'endpoint..."

cat > /tmp/endpoint_patch.py << 'EOF'
# Patch pour ajouter l'endpoint POST /api/v1/sessions/create

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import requests

router = APIRouter()

class SessionCreateRequest(BaseModel):
    exercise_type: str
    user_id: str

class SessionCreateResponse(BaseModel):
    session_id: str
    exercise_type: str
    user_id: str
    status: str
    livekit_room: str
    livekit_token: str

@router.post("/api/v1/sessions/create", response_model=SessionCreateResponse)
async def create_session_v1(request: SessionCreateRequest):
    """Créer une session d'exercice (endpoint v1)"""
    
    # Mapping des types d'exercices
    mapping = {
        "conversation": {"scenario": "conversation", "difficulty": "medium", "duration": 300},
        "breathing": {"scenario": "relaxation", "difficulty": "easy", "duration": 240},
        "articulation": {"scenario": "pronunciation", "difficulty": "medium", "duration": 180},
        "presentation": {"scenario": "public_speaking", "difficulty": "hard", "duration": 600}
    }
    
    session_data = mapping.get(request.exercise_type, mapping["conversation"])
    
    try:
        # Appeler l'endpoint existant
        response = requests.post(
            "http://localhost:8000/api/confidence-boost/session",
            json=session_data,
            timeout=10
        )
        
        if response.status_code == 200:
            original_data = response.json()
            
            return SessionCreateResponse(
                session_id=f"session_{original_data['id']}",
                exercise_type=request.exercise_type,
                user_id=request.user_id,
                status="created",
                livekit_room=f"room_{original_data['id']}",
                livekit_token=f"token_{original_data['id']}"
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to create session")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")
EOF

echo "   ✅ Patch créé: /tmp/endpoint_patch.py"

# Instructions pour appliquer le patch
echo ""
echo "4. Instructions pour appliquer le patch sur Scaleway:"
echo "   📋 ÉTAPES À SUIVRE:"
echo ""
echo "   a) Se connecter au serveur Scaleway:"
echo "      ssh root@$SCALEWAY_IP"
echo ""
echo "   b) Localiser le fichier main.py du backend:"
echo "      find / -name 'main.py' -path '*/backend/*' 2>/dev/null"
echo ""
echo "   c) Ajouter le code suivant au fichier main.py:"
echo ""
echo "      # Ajouter après les imports existants:"
echo "      from fastapi import APIRouter, HTTPException"
echo "      from pydantic import BaseModel"
echo "      import requests"
echo ""
echo "      # Ajouter avant app = FastAPI():"
echo "      class SessionCreateRequest(BaseModel):"
echo "          exercise_type: str"
echo "          user_id: str"
echo ""
echo "      # Ajouter après la création de l'app:"
echo "      @app.post('/api/v1/sessions/create')"
echo "      async def create_session_v1(request: SessionCreateRequest):"
echo "          mapping = {"
echo "              'conversation': {'scenario': 'conversation', 'difficulty': 'medium', 'duration': 300},"
echo "              'breathing': {'scenario': 'relaxation', 'difficulty': 'easy', 'duration': 240},"
echo "              'articulation': {'scenario': 'pronunciation', 'difficulty': 'medium', 'duration': 180},"
echo "              'presentation': {'scenario': 'public_speaking', 'difficulty': 'hard', 'duration': 600}"
echo "          }"
echo "          session_data = mapping.get(request.exercise_type, mapping['conversation'])"
echo "          # Utiliser l'endpoint existant en interne"
echo "          # (code du patch ci-dessus)"
echo ""
echo "   d) Redémarrer le service backend"
echo ""

# Test final avec simulation
echo "5. Simulation du résultat attendu:"
echo ""

# Simuler l'appel à l'endpoint de remplacement
original_response=$(cat /tmp/replacement_response.json)
session_id=$(echo "$original_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)

echo "   📄 Réponse simulée pour POST /api/v1/sessions/create:"
cat << EOF
{
  "session_id": "session_$session_id",
  "exercise_type": "conversation",
  "user_id": "test_user",
  "status": "created",
  "livekit_room": "room_$session_id",
  "livekit_token": "token_$session_id"
}
EOF

echo ""
echo "🎯 RÉSUMÉ:"
echo "   ✅ Endpoint de remplacement confirmé fonctionnel"
echo "   📝 Patch créé pour ajouter l'endpoint manquant"
echo "   🔧 Instructions fournies pour l'application"
echo ""
echo "💡 ALTERNATIVE RAPIDE:"
echo "   Modifier le frontend pour utiliser:"
echo "   POST /api/confidence-boost/session au lieu de POST /api/v1/sessions/create"

# Nettoyage
rm -f /tmp/test_response.json /tmp/replacement_response.json

echo ""
echo "🎉 Script terminé !"
