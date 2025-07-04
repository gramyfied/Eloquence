#!/usr/bin/env python3
"""
Service TTS avec OpenAI - API compatible OpenAI
"""

import os
import sys
import tempfile
import requests
import json
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse
import uvicorn
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="TTS Service OpenAI", version="1.0.0")

# Configuration OpenAI TTS
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', 'YOUR_OPENAI_API_KEY')
DEFAULT_OPENAI_VOICE = os.getenv('TTS_VOICE', 'alloy') # Voix par défaut pour OpenAI
RESPONSE_FORMAT = os.getenv('TTS_RESPONSE_FORMAT', 'wav')

# Voix disponibles pour OpenAI TTS
AVAILABLE_OPENAI_VOICES = [
    'alloy',
    'echo',
    'fable',
    'onyx',
    'nova',
    'shimmer'
]

def generate_openai_audio(text: str, output_path: str, voice: str = None):
    """Génère un fichier audio WAV avec OpenAI TTS"""
    try:
        selected_voice = voice or DEFAULT_OPENAI_VOICE
        
        if selected_voice not in AVAILABLE_OPENAI_VOICES:
            logger.warning(f"Voix {selected_voice} non disponible sur OpenAI, utilisation de la voix par défaut: {DEFAULT_OPENAI_VOICE}")
            selected_voice = DEFAULT_OPENAI_VOICE
        
        logger.info(f"🎯 Génération audio OpenAI pour: '{text[:50]}...'" )
        logger.info(f"   Voix: {selected_voice}")
        
        payload = {
            "model": "tts-1",
            "input": text,
            "voice": selected_voice,
            "response_format": RESPONSE_FORMAT
        }
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}"
        }
        
        response = requests.post(
            "https://api.openai.com/v1/audio/speech",
            json=payload,
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            with open(output_path, 'wb') as f:
                f.write(response.content)
            
            if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
                logger.info(f"✅ Audio OpenAI généré: {output_path}")
                logger.info(f"   Taille: {os.path.getsize(output_path)} octets")
                return True
            else:
                raise Exception("Fichier audio non généré ou trop petit par OpenAI TTS")
        else:
            error_msg = f"Erreur API OpenAI TTS: {response.status_code}"
            try:
                error_detail = response.json()
                error_msg += f" - {error_detail}"
            except:
                error_msg += f" - {response.text}"
            raise Exception(error_msg)
            
    except Exception as e:
        logger.error(f"❌ Erreur OpenAI TTS: {e}")
        return False

@app.on_event("startup")
async def startup_event():
    """Vérifie la configuration OpenAI au démarrage"""
    logger.info("🚀 Démarrage du service TTS OpenAI...")
    logger.info(f"   Voix par défaut OpenAI: {DEFAULT_OPENAI_VOICE}")
    
    if not OPENAI_API_KEY or OPENAI_API_KEY == 'YOUR_OPENAI_API_KEY':
        logger.warning("ATTENTION: OPENAI_API_KEY non configurée ou générique. Le service risque de ne pas fonctionner.")
    
    logger.info("✅ Service TTS OpenAI prêt à écouter les requêtes!")

@app.post('/api/tts')
async def text_to_speech(data: dict):
    """Génère un audio avec OpenAI TTS"""
    try:
        text = data.get('text', '')
        voice = data.get('voice', None)
        
        if not text:
            raise HTTPException(status_code=400, detail="Texte manquant")
        
        if len(text) > 2000:
            raise HTTPException(status_code=400, detail="Texte trop long (max 2000 caractères)")
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            temp_path = tmp_file.name
        
        success = generate_openai_audio(text, temp_path, voice)
        
        if success and os.path.exists(temp_path) and os.path.getsize(temp_path) > 100:
            return FileResponse(
                temp_path,
                media_type='audio/wav',
                filename=f"openai_tts_output.wav",
                headers={
                    "Content-Disposition": "attachment; filename=openai_tts_output.wav",
                    "X-Audio-Engine": "openai",
                    "X-Audio-Quality": "high"
                }
            )
        else:
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            raise HTTPException(status_code=500, detail="Impossible de générer l'audio avec OpenAI TTS")
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur TTS: {str(e)}")

@app.get('/api/voices')
async def list_voices():
    """Liste les voix disponibles pour OpenAI TTS"""
    try:
        voices_info = []
        for voice in AVAILABLE_OPENAI_VOICES:
            voice_info = {
                'id': voice,
                'name': f'Voix {voice}',
                'language': 'en-US', # À adapter selon les voix OpenAI disponibles
                'gender': 'neutral',
                'quality': 'high'
            }
            voices_info.append(voice_info)
        
        return {
            'available_voices': voices_info,
            'default_voice': DEFAULT_OPENAI_VOICE,
            'engine': 'openai',
            'language': 'en-US' # À adapter
        }
        
    except Exception as e:
        return {'error': f'Erreur voix OpenAI: {str(e)}'}

@app.get('/api/models')
async def list_models():
    """Informations sur le modèle OpenAI TTS"""
    return {
        'engine': 'openai',
        'version': 'tts-1',
        'language': 'en-US', # À adapter
        'quality': 'high',
        'sample_rate': 24000,
        'model_loaded': True,
        'features': [
            'API OpenAI',
            'Haute qualité',
            'Diverses voix'
        ]
    }

@app.get('/health')
async def health():
    """Vérification de santé du service OpenAI TTS"""
    openai_available = True
    if not OPENAI_API_KEY or OPENAI_API_KEY == 'YOUR_OPENAI_API_KEY':
        openai_available = False
    
    return {
        'status': 'ok' if openai_available else 'warning',
        'engine': 'openai',
        'openai_available': openai_available,
        'language': 'en-US', # À adapter
        'quality': 'high',
        'sample_rate': 24000,
        'voices_available': len(AVAILABLE_OPENAI_VOICES)
    }

@app.get('/')
async def root():
    """Page d'accueil du service OpenAI TTS"""
    return {
        'service': 'TTS OpenAI Service',
        'version': '1.0.0',
        'description': 'Service de synthèse vocale avec OpenAI TTS',
        'endpoints': [
            'POST /api/tts - Générer audio',
            'GET /api/voices - Lister les voix',
            'GET /api/models - Informations modèle',
            'GET /health - Vérification santé'
        ]
    }

if __name__ == '__main__':
    logger.info("🚀 Démarrage du service TTS OpenAI...")
    uvicorn.run(app, host='0.0.0.0', port=5002)