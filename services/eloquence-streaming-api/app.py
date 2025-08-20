#!/usr/bin/env python3
"""
Service d'exercices vocaux Eloquence
Fournit les API pour Confidence Boost, Tribunal des Idées, etc.
"""

import os
import json
import logging
import asyncio
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import redis
import uuid

# Configuration logging
LOG_LEVEL = os.getenv("LOG_LEVEL", "DEBUG").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.DEBUG),
    format='%(asctime)s.%(msecs)03d %(levelname)s [%(name)s] %(filename)s:%(lineno)d - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Configuration Flask
app = Flask(__name__)
app.config['SECRET_KEY'] = 'dev-secret-key'
CORS(app, origins=['*'])
socketio = SocketIO(app, cors_allowed_origins='*', async_mode='threading')

# Configuration Redis
REDIS_URL = os.getenv('REDIS_URL', 'redis://redis:6379')
try:
    redis_client = redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=5, health_check_interval=30)
    # Test de connexion
    redis_client.ping()
    logger.info(f"✅ Redis connecté: {REDIS_URL}")
except Exception as e:
    logger.error(f"❌ Erreur connexion Redis: {e}")
    redis_client = None

# Configuration des clés API
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
SCALEWAY_API_KEY = os.getenv('SCALEWAY_API_KEY', '')

# Health check
@app.route('/health', methods=['GET'])
def health_check():
    """Health check pour vérifier le statut du service."""
    try:
        # Test Redis
        redis_status = 'disconnected'
        if redis_client:
            try:
                redis_client.ping()
                redis_status = 'connected'
            except:
                redis_status = 'error'
        
        status = {
            'status': 'healthy' if redis_status == 'connected' else 'degraded',
            'timestamp': datetime.now().isoformat(),
            'services': {
                'redis': redis_status,
                'openai': 'configured' if OPENAI_API_KEY else 'missing_key',
                'scaleway': 'configured' if SCALEWAY_API_KEY else 'missing_key'
            }
        }
        
        logger.info("✅ Health check réussi")
        return jsonify(status), 200
        
    except Exception as e:
        logger.error(f"❌ Health check échoué: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/diagnostics/logs', methods=['GET'])
def diagnostics_logs():
    return jsonify({
        'log_level': LOG_LEVEL,
        'time': datetime.now().isoformat(),
        'service': 'eloquence-streaming-api'
    }), 200

# Création de session d'exercice
@app.route('/api/sessions/create', methods=['POST'])
def create_exercise_session():
    """Crée une nouvelle session d'exercice vocal."""
    try:
        data = request.get_json()
        
        # Générer un ID unique pour la session
        session_id = f"session_{uuid.uuid4().hex[:12]}"
        
        # Données de session
        session_data = {
            'session_id': session_id,
            'exercise_id': data.get('exercise_id', 'unknown'),
            'participant_name': data.get('participant_name', 'anonymous'),
            'language': data.get('language', 'fr'),
            'scenario': data.get('scenario', 'default'),
            'created_at': datetime.now().isoformat(),
            'status': 'active',
            'messages': [],
            'metrics': {}
        }
        
        # Générer room LiveKit
        livekit_room = f"exercise_{session_id}"
        session_data['livekit_room'] = livekit_room
        
        # Sauvegarder en Redis
        if redis_client:
            try:
                redis_client.setex(
                    f"session:{session_id}",
                    7200,  # 2 heures
                    json.dumps(session_data)
                )
            except Exception as redis_error:
                logger.warning(f"⚠️ Redis non disponible: {redis_error}")
        
        logger.info(f"✅ Session créée: {session_id} pour exercice {data.get('exercise_id')}")
        
        return jsonify({
            'session_id': session_id,
            'livekit_room': livekit_room,
            'status': 'created',
            'expires_in': 7200
        }), 200
        
    except Exception as e:
        logger.error(f"❌ Erreur création session: {e}")
        return jsonify({'error': str(e)}), 500

# Finalisation d'exercice
@app.route('/api/sessions/<session_id>/complete', methods=['POST'])
def complete_exercise_session(session_id):
    """Finalise une session d'exercice et génère l'évaluation."""
    try:
        # Récupérer la session
        session_key = f"session:{session_id}"
        session_raw = None
        
        if redis_client:
            try:
                session_raw = redis_client.get(session_key)
            except Exception as redis_error:
                logger.warning(f"⚠️ Redis non disponible: {redis_error}")
        
        if not session_raw:
            # Session simulée si Redis indisponible
            session_data = {
                'session_id': session_id,
                'messages': [],
                'status': 'active'
            }
        else:
            session_data = json.loads(session_raw)
        
        # Données d'évaluation basiques (simulation)
        evaluation_data = {
            'session_id': session_id,
            'overall_score': 75.0,  # Score simulé
            'detailed_scores': {
                'confidence': 80.0,
                'articulation': 70.0,
                'fluency': 75.0
            },
            'evaluation': {
                'overall_score': 75.0,
                'detailed_scores': {
                    'confidence': 80.0,
                    'articulation': 70.0,
                    'fluency': 75.0
                },
                'strengths': [
                    'Bonne articulation',
                    'Débit adapté'
                ],
                'improvements': [
                    'Travaillez la confiance en soi',
                    'Augmentez l\'expressivité'
                ],
                'feedback': 'Excellent travail ! Continuez à pratiquer pour gagner en confiance.'
            },
            'total_duration_seconds': 120,
            'total_exchanges': len(session_data.get('messages', [])),
            'completed_at': datetime.now().isoformat()
        }
        
        # Marquer la session comme terminée
        session_data['status'] = 'completed'
        session_data['evaluation'] = evaluation_data
        
        # Sauvegarder les résultats
        if redis_client:
            try:
                redis_client.setex(session_key, 7200, json.dumps(session_data))
            except Exception as redis_error:
                logger.warning(f"⚠️ Redis non disponible pour sauvegarde: {redis_error}")
        
        logger.info(f"✅ Session terminée: {session_id} avec score {evaluation_data['overall_score']}")
        
        return jsonify(evaluation_data), 200
        
    except Exception as e:
        logger.error(f"❌ Erreur finalisation session: {e}")
        return jsonify({'error': str(e)}), 500

# Analyse audio
@app.route('/analyze-audio', methods=['POST'])
def analyze_audio():
    """Analyse un fichier audio et retourne transcription + réponse IA."""
    try:
        session_id = request.headers.get('X-Session-ID', 'unknown')
        
        # Vérifier qu'un fichier audio est présent
        if 'audio' not in request.files:
            return jsonify({'error': 'Aucun fichier audio fourni'}), 400
            
        audio_file = request.files['audio']
        
        # Simulation de transcription et réponse IA
        transcription = "Transcription simulée de votre message audio..."
        ai_response = "Très bien ! Je comprends votre message. Continuons la conversation..."
        
        # Métriques simulées
        response_data = {
            'transcription': transcription,
            'ai_response': ai_response,
            'confidence_score': 0.85,
            'metrics': {
                'audio_duration': 3.5,
                'words_count': 12,
                'clarity_score': 0.8
            },
            'processed_at': datetime.now().isoformat()
        }
        
        logger.info(f"✅ Audio analysé pour session: {session_id}")
        
        return jsonify(response_data), 200
        
    except Exception as e:
        logger.error(f"❌ Erreur analyse audio: {e}")
        return jsonify({'error': str(e)}), 500

# Analyse Virelangue (endpoint spécifique pour Flutter)
@app.route('/api/virelangue/analyze', methods=['POST'])
def analyze_virelangue():
    """Analyse un virelangue pour l'exercice Confidence Boost."""
    try:
        session_id = request.form.get('sessionId', 'unknown')
        text_cible = request.form.get('texteCible', '')
        
        # Vérifier qu'un fichier audio est présent
        if 'audioFile' not in request.files:
            return jsonify({'detail': 'Aucun fichier audio fourni'}), 400
            
        audio_file = request.files['audioFile']
        
        logger.info(f"📊 Analyse virelangue pour session: {session_id}")
        logger.info(f"🎯 Texte cible: {text_cible}")
        
        # Simulation d'analyse vocale (remplacera par Vosk + IA)
        transcription_simulee = text_cible.lower()  # Simulation
        score_prononciation = 85.0  # Score simulé
        
        # Résultat d'analyse
        analysis_result = {
            'sessionId': session_id,
            'transcription': transcription_simulee,
            'texteCible': text_cible,
            'scores': {
                'prononciation': score_prononciation,
                'fluidite': 80.0,
                'clarte': 90.0,
                'global': 85.0
            },
            'feedback': {
                'points_forts': [
                    'Excellente articulation des consonnes',
                    'Bon rythme de parole'
                ],
                'ameliorations': [
                    'Travaillez la liaison entre les mots',
                    'Attention à la précision des voyelles'
                ],
                'message_encouragement': 'Très bon travail ! Continuez à pratiquer pour perfectionner votre diction.'
            },
            'analysis_complete': True,
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"✅ Analyse virelangue terminée: score {score_prononciation}%")
        
        return jsonify(analysis_result), 200
        
    except Exception as e:
        logger.error(f"❌ Erreur d'analyse virelangue: {e}")
        return jsonify({
            'detail': f'Erreur d\'analyse virelangue: {str(e)}',
            'sessionId': request.form.get('sessionId', 'unknown'),
            'analysis_complete': False
        }), 500

# WebSocket pour l'analyse en temps réel
@socketio.on('connect')
def handle_connect():
    """Connexion WebSocket établie."""
    logger.info("🔗 Nouvelle connexion WebSocket")
    emit('connection_established', {'status': 'connected', 'timestamp': datetime.now().isoformat()})

@socketio.on('disconnect')
def handle_disconnect():
    """Connexion WebSocket fermée."""
    logger.info("🔌 Connexion WebSocket fermée")

@socketio.on('user_message')
def handle_user_message(data):
    """Traite un message utilisateur et génère une réponse IA."""
    try:
        content = data.get('content', '')
        timestamp = data.get('timestamp', datetime.now().isoformat())
        
        logger.info(f"📤 Message utilisateur reçu: {content}")
        
        # Simulation de réponse IA
        ai_response = f"Merci pour votre message : '{content}'. Comment puis-je vous aider davantage ?"
        
        # Émettre la réponse IA
        emit('ai_response', {
            'text': ai_response,
            'timestamp': datetime.now().timestamp(),
            'audio_format': 'mp3',
            'confidence_score': 0.9
        })
        
        logger.info(f"🤖 Réponse IA envoyée: {ai_response}")
        
    except Exception as e:
        logger.error(f"❌ Erreur traitement message: {e}")
        emit('error', {'message': str(e)})

@socketio.on('audio_chunk')
def handle_audio_chunk(data):
    """Traite un chunk audio en temps réel."""
    try:
        audio_data = data.get('data', '')
        timestamp = data.get('timestamp', datetime.now().isoformat())
        
        # Simulation de traitement audio
        emit('analysis_complete', {
            'confidence_score': 0.8,
            'partial_transcription': 'Transcription partielle...',
            'timestamp': datetime.now().isoformat()
        })
        
        logger.info("📊 Chunk audio traité")
        
    except Exception as e:
        logger.error(f"❌ Erreur traitement chunk audio: {e}")

if __name__ == '__main__':
    logger.info("🚀 Démarrage du service Eloquence Streaming API")
    logger.info(f"📡 Redis: {REDIS_URL}")
    logger.info(f"🔑 OpenAI configuré: {'✅' if OPENAI_API_KEY else '❌'}")
    logger.info(f"🔑 Scaleway configuré: {'✅' if SCALEWAY_API_KEY else '❌'}")
    
    # Démarrer le serveur
    socketio.run(
        app,
        host='0.0.0.0',
        port=8005,
        debug=True,
        allow_unsafe_werkzeug=True
    )