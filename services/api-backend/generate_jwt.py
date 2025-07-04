import jwt
import os
import time

api_key = os.environ.get("LIVEKIT_API_KEY")
api_secret = os.environ.get("LIVEKIT_API_SECRET")

if not api_key or not api_secret:
    print("LIVEKIT_API_KEY and LIVEKIT_API_SECRET must be set in environment variables.")
    # Permet de vérifier facilement si les variables sont définies dans le conteneur
    print(f"LIVEKIT_API_KEY: {'set' if api_key else 'not set'}")
    print(f"LIVEKIT_API_SECRET: {'set' if api_secret else 'not set'}")
    exit(1)

# Payload pour l'API REST avec permissions d'administration
payload = {
    "exp": int(time.time()) + 60 * 60,  # Expire in 1 hour
    "iss": api_key,
    "name": "api-backend", # Identifiant du client
    "video": {
        "roomAdmin": True, # Permission administrative globale
    },
}

token = jwt.encode(payload, api_secret, algorithm="HS256")
print(token)