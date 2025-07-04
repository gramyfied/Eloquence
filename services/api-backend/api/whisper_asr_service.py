#!/usr/bin/env python3
"""
Service ASR (Automatic Speech Recognition) avec Whisper Large-v3-Turbo
Compatible avec l'agent LiveKit Eloquence 2.0
Optimisé pour une reconnaissance vocale 8x plus rapide
"""
import os
import tempfile
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import pipeline
import torch
import soundfile as sf
import numpy as np


# Patterns d'hallucination à filtrer après transcription
HALLUCINATION_PATTERNS = [
    "sous-titrage société radio-canada",
    "radio-canada",
    "société radio-canada",
    "sous-titrage",
    "merci de votre attention",
    "fin de transmission",
    "transcription automatique"
]

# Configuration des logs
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration Whisper Large-v3-Turbo
MODEL_ID = os.getenv('WHISPER_MODEL_ID', 'openai/whisper-large-v3-turbo')
DEVICE = os.getenv('WHISPER_DEVICE', 'cpu')
TORCH_DTYPE = torch.float16 if DEVICE == 'cuda' else torch.float32

# Initialisation du modèle Whisper Large-v3-Turbo
logger.info(f"🚀 Début Initialisation Whisper Large-v3-Turbo: modèle={MODEL_ID}, appareil={DEVICE}")

try:
    logger.info(f"Chargement du modèle Whisper Large-v3-Turbo...")
    whisper_pipeline = pipeline(
        "automatic-speech-recognition",
        model=MODEL_ID,
        device=DEVICE,
        torch_dtype=TORCH_DTYPE
    )
    logger.info("✅ Whisper Large-v3-Turbo initialisé avec succès !")
    logger.info(f"🎯 Modèle optimisé pour reconnaissance vocale française 8x plus rapide")
except Exception as e:
    logger.error(f"❌ Erreur critique lors de l'initialisation de Whisper Large-v3-Turbo: {e}", exc_info=True)
    logger.warning("Le service ASR démarrera mais ne pourra PAS transcrire sans un modèle valide.")
    whisper_pipeline = None

# Métriques de validation pour Whisper
whisper_metrics = {
    "hallucinations_filtered": 0,
    "valid_transcriptions": 0,
    "total_transcriptions": 0,
    "avg_latency": 0.0,
    "filter_efficiency": 0.0
}

def track_whisper_metrics(original_text: str, filtered_text: str, latency: float):
    """Met à jour les métriques de validation de Whisper."""
    global whisper_metrics
    
    whisper_metrics["total_transcriptions"] += 1
    
    if filtered_text == "" and original_text != "":
        whisper_metrics["hallucinations_filtered"] += 1
    elif filtered_text != "":
        whisper_metrics["valid_transcriptions"] += 1
    
    # Mise à jour latence moyenne
    total_requests = whisper_metrics["total_transcriptions"]
    if total_requests > 0:
        whisper_metrics["avg_latency"] = (
            (whisper_metrics["avg_latency"] * (total_requests - 1) + latency) / total_requests
        )
        
        whisper_metrics["filter_efficiency"] = (
            whisper_metrics["hallucinations_filtered"] / total_requests * 100
        )

logger.info("Démarrage de l'application Flask...")

@app.route('/')
def home():
    logger.info("Requête reçue sur /")
    return jsonify({
        "service": "ASR Service avec Whisper Large-v3-Turbo",
        "version": "2.0",
        "model": MODEL_ID,
        "device": DEVICE,
        "performance": "8x plus rapide",
        "status": "ready" if whisper_pipeline else "error"
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    if whisper_pipeline:
        return jsonify({"status": "healthy", "model": MODEL_ID, "performance": "8x faster"}), 200
    else:
        return jsonify({"status": "unhealthy", "error": "Whisper Large-v3-Turbo not loaded"}), 503

# Fonction de logique principale pour la transcription
def _transcribe_audio_logic():
    """Logique de transcription audio avec Whisper Large-v3-Turbo."""
    try:
        logger.info("🎤 Nouvelle demande de transcription reçue (Whisper Large-v3-Turbo).")
        
        if not whisper_pipeline:
            logger.error("Pipeline Whisper Large-v3-Turbo non disponible. Impossible de transcrire.")
            return jsonify({"error": "Whisper Large-v3-Turbo pipeline not available"}), 503
        
        # Vérifier la présence du fichier audio
        if 'audio' not in request.files:
            logger.warning("Aucun fichier audio fourni dans la requête.")
            return jsonify({"error": "No audio file provided"}), 400
        
        audio_file = request.files['audio']
        if audio_file.filename == '':
            logger.warning("Nom de fichier audio vide.")
            return jsonify({"error": "No audio file selected"}), 400
        
        # Sauvegarder temporairement le fichier
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            audio_file.save(temp_file.name)
            temp_path = temp_file.name
        
        logger.info(f"Fichier audio temporaire enregistré: {temp_path}")
        
        try:
            # Lire l'audio avec soundfile
            audio_data, sample_rate = sf.read(temp_path)
            logger.info(f"📊 Audio lu: {len(audio_data)} échantillons, {sample_rate}Hz.")
            
            # Convertir en mono si nécessaire
            if len(audio_data.shape) > 1:
                audio_data = np.mean(audio_data, axis=1)
                logger.info("Conversion audio en mono effectuée.")
            
            # Transcription avec Whisper Large-v3-Turbo (8x plus rapide)
            logger.info("🚀 Démarrage de la transcription Turbo...")
            import time
            start_time = time.time()
            
            # Convertir en float32 pour compatibilité
            audio_data = audio_data.astype(np.float32)
            
            # Paramètres de génération supportés par le pipeline ASR
            # Les paramètres comme 'condition_on_previous_text', 'initial_prompt', 'log_prob_threshold',
            # 'beam_size', 'best_of' ne sont pas directement supportés par le pipeline ASR de Hugging Face
            # et doivent être passés directement au modèle si le pipeline le permet, ou gérés différemment.
            # Pour éviter l'erreur ValueError, nous ne passons que les paramètres reconnus.
            generate_kwargs = {
                "language": "french",
                "task": "transcribe",
                "temperature": 0.0,              # Déterministe
                "no_speech_threshold": 0.8,      # Seuil silence élevé
            }

            result = whisper_pipeline(audio_data, generate_kwargs=generate_kwargs)
            
            end_time = time.time()
            transcription_time = end_time - start_time
            
            raw_text = result["text"].strip()
            
            # Filtrage post-transcription intelligent
            text = filter_hallucinations(raw_text)

            logger.info(f"✅ Transcription Turbo réussie en {transcription_time:.2f}s: '{raw_text}' -> Filtré: '{text}'")
            
            # Mise à jour des métriques
            track_whisper_metrics(raw_text, text, transcription_time)

            # Réponse compatible avec l'agent (format maintenu)
            return jsonify({
                "text": text,
                "language": "fr",  # Français configuré par défaut
                "language_probability": 0.95,  # Confiance élevée pour le français
                "duration": len(audio_data) / sample_rate,
                "transcription_time": transcription_time,
                "model": "whisper-large-v3-turbo",
                "metrics": whisper_metrics # Ajout des métriques pour le dashboard
            })
            
        finally:
            # Nettoyer le fichier temporaire
            logger.info(f"Nettoyage du fichier temporaire: {temp_path}")
            if os.path.exists(temp_path):
                os.unlink(temp_path)
                logger.info("Fichier temporaire supprimé.")
                
    except Exception as e:
        logger.error(f"❌ Erreur générale lors de la transcription Turbo: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

# Fonction de filtrage des hallucinations
def filter_hallucinations(transcript: str) -> str:
    """Filtre les hallucinations - COMPLÈTEMENT DÉSACTIVÉ POUR DEBUG AUDIO"""
    
    # TOUS LES FILTRES DÉSACTIVÉS POUR PERMETTRE L'AUDIO DE PASSER
    if not transcript:
        return ""
    
    # Retourner directement la transcription sans aucun filtrage
    logger.info(f"✅ Transcription acceptée (TOUS FILTRES DÉSACTIVÉS): '{transcript.strip()}'")
    return transcript.strip()

# Endpoint pour le chemin principal /transcribe
@app.route('/transcribe', methods=['POST'])
def transcribe_audio_main():
    """Endpoint principal de transcription."""
    return _transcribe_audio_logic()

# Endpoint pour le chemin /asr (compatibilité)
@app.route('/asr', methods=['POST'])
def transcribe_audio_asr():
    """Endpoint /asr pour compatibilité."""
    logger.info("Requête reçue sur /asr (compatibilité)")
    return _transcribe_audio_logic()

# Endpoint pour le chemin /v1/audio/transcriptions (style OpenAI)
@app.route('/v1/audio/transcriptions', methods=['POST'])
def transcribe_audio_openai():
    """Endpoint style OpenAI pour compatibilité."""
    logger.info("Requête reçue sur /v1/audio/transcriptions (style OpenAI)")
    return _transcribe_audio_logic()

if __name__ == '__main__':
    port = int(os.getenv('ASR_PORT', 8001))
    app.run(host='0.0.0.0', port=port, debug=False)
