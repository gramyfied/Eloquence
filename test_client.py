#!/usr/bin/env python3
"""
Client de test pour Eloquence LiveKit Conversation Service
Valide les endpoints principaux (health, création session)
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    print("Test /health ...")
    resp = requests.get(f"{BASE_URL}/health")
    print("Status:", resp.status_code)
    print("Réponse:", resp.json())

def test_create_session():
    print("Test /api/sessions/create ...")
    data = {
        "exercise_type": "confidence_boost",
        "user_id": "test_user"
    }
    resp = requests.post(f"{BASE_URL}/api/sessions/create", json=data)
    print("Status:", resp.status_code)
    print("Réponse:", resp.json())

if __name__ == "__main__":
    test_health()
    test_create_session()