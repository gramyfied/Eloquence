#!/usr/bin/env python3
"""
Test WebSocket streaming pour Eloquence LiveKit Conversation Service
"""

import asyncio
import websockets
import requests
import json

BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

async def test_streaming():
    # 1. Créer une session
    resp = requests.post(f"{BASE_URL}/api/sessions/create", json={
        "exercise_type": "confidence_boost",
        "user_id": "test_user"
    })
    assert resp.status_code == 200, f"Erreur création session: {resp.text}"
    session_id = resp.json()["session_id"]
    print("Session créée:", session_id)

    # 2. Connexion WebSocket
    ws_url = f"{WS_URL}/api/sessions/{session_id}/stream"
    async with websockets.connect(ws_url) as ws:
        # 3. Réception message d'accueil
        welcome = await ws.recv()
        print("Réception:", welcome)
        welcome_data = json.loads(welcome)
        assert welcome_data.get("type") == "welcome", "Pas de message welcome"

        # 4. Envoi d'un chunk audio simulé (texte encodé)
        fake_audio = "Bonjour, je souhaite vous présenter notre solution innovante"
        message = {
            "type": "audio_chunk",
            "data": fake_audio,  # Simule un envoi audio
            "timestamp": "2025-07-22T22:08:00"
        }
        await ws.send(json.dumps(message))

        # 5. Réception de la réponse conversationnelle
        response = await ws.recv()
        print("Réponse conversation_update:", response)
        data = json.loads(response)
        assert data.get("type") == "conversation_update", "Pas de conversation_update"
        print("Transcription:", data.get("transcription"))
        print("Réponse IA:", data.get("ai_response"))
        print("Métriques:", data.get("speech_analysis"))

        # 6. Fin de session
        await ws.send(json.dumps({"type": "end_session"}))
        print("Session terminée.")

if __name__ == "__main__":
    asyncio.run(test_streaming())