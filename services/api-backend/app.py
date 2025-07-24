from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
from celery import Celery
import os
import time
import uuid
import jwt
import asyncio
import threading
import logging
from datetime import datetime, timedelta
import logging # Ajouter l'import de logging ici
import httpx # Ajout de l'import httpx
import json # Ajout de l'import json pour la migration Vosk
 
# Configuration du logging pour le diagnostic
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("BACKEND_DIAGNOSTIC")

# Note: services LiveKit supprimés pour approche REST + Vosk pure

app = Flask(__name__)
CORS(app) # Active CORS pour toutes les routes

# Note: blueprint LiveKit supprimé pour approche REST + Vosk

# Configuration Celery
app.config['CELERY_BROKER_URL'] = os.getenv('REDIS_URL', 'redis://redis:6379/0')
app.config['CELERY_RESULT_BACKEND'] = os.getenv('REDIS_URL', 'redis://redis:6379/0')

# Configuration LiveKit
LIVEKIT_URL_INTERNAL = os.getenv('LIVEKIT_URL', 'ws://livekit:7880')  # Pour Docker interne
LIVEKIT_URL_EXTERNAL = os.getenv('LIVEKIT_URL_EXTERNAL', 'ws://192.168.1.44:7880') # Rendre cette variable configurable

# Initialisation Celery
celery = Celery(
    app.import_name,
    broker=app.config['CELERY_BROKER_URL'],
    backend=app.config['CELERY_RESULT_BACKEND']
)
celery.conf.update(app.config)

# Configuration du logging pour le diagnostic
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("BACKEND_DIAGNOSTIC")

# Registre des sessions actives pour éviter les doublons
active_sessions = {}
session_lock = threading.Lock()

# Tâches Celery
@celery.task
def example_task(param):
    """Tâche d'exemple pour tester Celery"""
    return f"Tâche exécutée avec le paramètre: {param}"

@celery.task
def process_audio_task(audio_data):
    """Tâche pour traiter l'audio"""
    # Logique de traitement audio ici
    return {"status": "processed", "data": audio_data}

@celery.task
def diagnostic_asr_task(audio_data):
    """DIAGNOSTIC: Tâche Celery pour tester l'ASR"""
    logger.info(f"🔄 DIAGNOSTIC: Tâche ASR Celery exécutée avec {len(audio_data) if audio_data else 0} bytes")
    try:
        # Simuler le traitement ASR
        import httpx
        import asyncio
        
        async def test_asr():
            async with httpx.AsyncClient() as client:
                response = await client.get("http://whisper-stt:8001/health", timeout=2.0)
                return response.status_code == 200
        
        # Exécuter le test ASR
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        asr_available = loop.run_until_complete(test_asr())
        loop.close()
        
        if asr_available:
            logger.info("✅ DIAGNOSTIC: Service ASR accessible depuis Celery")
            return {"status": "success", "asr_available": True}
        else:
            logger.warning("⚠️ DIAGNOSTIC: Service ASR non accessible depuis Celery")
            return {"status": "warning", "asr_available": False}
            
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur tâche ASR Celery: {e}")
        return {"status": "error", "error": str(e)}

@celery.task
def diagnostic_tts_task(text):
    """DIAGNOSTIC: Tâche Celery pour tester le TTS"""
    logger.info(f"🔄 DIAGNOSTIC: Tâche TTS Celery exécutée avec texte: '{text[:50]}...'")
    try:
        # Simuler le traitement TTS
        import httpx
        import asyncio
        
        async def test_tts():
            async with httpx.AsyncClient() as client:
                response = await client.get("http://piper-tts:5002/health", timeout=2.0)
                return response.status_code == 200
        
        # Exécuter le test TTS
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        tts_available = loop.run_until_complete(test_tts())
        loop.close()
        
        if tts_available:
            logger.info("✅ DIAGNOSTIC: Service TTS accessible depuis Celery")
            return {"status": "success", "tts_available": True}
        else:
            logger.warning("⚠️ DIAGNOSTIC: Service TTS non accessible depuis Celery")
            return {"status": "warning", "tts_available": False}
            
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur tâche TTS Celery: {e}")
        return {"status": "error", "error": str(e)}

@app.route('/')
def home():
    return "Bienvenue sur le backend Flask!"

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "eloquence-api"}), 200

@app.route('/api/data')
def get_data():
    data = {
        "message": "Données du backend Flask",
        "version": "1.0"
    }
    return jsonify(data)

@app.route('/api/test-celery')
def test_celery():
    """Endpoint pour tester Celery"""
    task = example_task.delay("test")
    return jsonify({"task_id": task.id, "status": "Task started"})

def generate_livekit_token(room_name: str, participant_identity: str) -> str:
    """Génère un token LiveKit pour un participant"""
    import time
    now_timestamp = int(time.time())
    exp_timestamp = now_timestamp + (24 * 3600)  # +24 heures
    
    # Log pour diagnostic
    logger.info(f"🔑 GÉNÉRATION TOKEN: now={now_timestamp}, exp={exp_timestamp}")
    logger.info(f"🔑 Date now: {datetime.fromtimestamp(now_timestamp)}")
    logger.info(f"🔑 Date exp: {datetime.fromtimestamp(exp_timestamp)}")
    
    # CORRECTION: Format correct pour LiveKit
    payload = {
        'iss': os.getenv('LIVEKIT_API_KEY'),
        'sub': participant_identity,
        'iat': now_timestamp,
        'exp': exp_timestamp,
        'nbf': now_timestamp,
        'video': {
            'room': room_name,
            'roomJoin': True,
            'roomList': True,
            'roomRecord': False,
            'roomAdmin': False,
            'roomCreate': False,
            'canPublish': True,
            'canSubscribe': True,
            'canPublishData': True,
            'canUpdateOwnMetadata': True
        }
    }
    
    # CORRECTION CRITIQUE: Utiliser les bonnes clés depuis les variables d'environnement
    api_key = os.getenv('LIVEKIT_API_KEY', 'devkey')
    api_secret = os.getenv('LIVEKIT_API_SECRET', 'secret')
    
    logger.info(f"🔑 Utilisation clés: API_KEY={api_key}, SECRET={'*' * len(api_secret)}")
    
    payload['iss'] = api_key
    
    return jwt.encode(payload, api_secret, algorithm='HS256')

@app.route('/api/scenarios', methods=['GET'])
def get_scenarios():
    """Retourne la liste des scénarios disponibles"""
    try:
        language = request.args.get('language', 'fr')
        
        # Scénarios de démonstration
        scenarios = [
            {
                "id": "demo-1",
                "title": "Entretien d'embauche" if language == 'fr' else "Job Interview",
                "description": "Préparez-vous pour un entretien d'embauche avec un coach IA" if language == 'fr' else "Prepare for a job interview with an AI coach",
                "category": "professional",
                "difficulty": "intermediate",
                "duration_minutes": 15,
                "language": language,
                "tags": ["entretien", "professionnel", "coaching"] if language == 'fr' else ["interview", "professional", "coaching"],
                "created_at": "2025-06-17T00:00:00Z",
                "updated_at": "2025-06-17T00:00:00Z"
            },
            {
                "id": "demo-2",
                "title": "Présentation publique" if language == 'fr' else "Public Speaking",
                "description": "Améliorez vos compétences de présentation en public" if language == 'fr' else "Improve your public speaking skills",
                "category": "communication",
                "difficulty": "advanced",
                "duration_minutes": 20,
                "language": language,
                "tags": ["présentation", "public", "communication"] if language == 'fr' else ["presentation", "public", "communication"],
                "created_at": "2025-06-17T00:00:00Z",
                "updated_at": "2025-06-17T00:00:00Z"
            },
            {
                "id": "demo-3",
                "title": "Conversation informelle" if language == 'fr' else "Casual Conversation",
                "description": "Pratiquez une conversation détendue avec l'IA" if language == 'fr' else "Practice casual conversation with AI",
                "category": "social",
                "difficulty": "beginner",
                "duration_minutes": 10,
                "language": language,
                "tags": ["conversation", "social", "débutant"] if language == 'fr' else ["conversation", "social", "beginner"],
                "created_at": "2025-06-17T00:00:00Z",
                "updated_at": "2025-06-17T00:00:00Z"
            }
        ]
        
        logger.info(f"✅ Scénarios récupérés pour langue: {language}")
        return jsonify({
            "scenarios": scenarios,
            "total": len(scenarios),
            "language": language,
            "timestamp": datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération scénarios: {str(e)}")
        return jsonify({"error": f"Erreur lors de la récupération des scénarios: {str(e)}"}), 500

@app.route('/api/sessions', methods=['POST'])
def create_session():
    """Crée une session LiveKit pour les tests"""
    try:
        data = request.get_json()
        
        # Validation des données requises
        if not data:
            return jsonify({"error": "Données JSON requises"}), 400
            
        user_id = data.get('user_id')
        scenario_id = data.get('scenario_id', 'default')
        language = data.get('language', 'fr')
        
        if not user_id:
            return jsonify({"error": "user_id requis"}), 400
        
        # Clé unique pour identifier la session
        session_key = f"{user_id}_{scenario_id}"
        
        with session_lock:
            # Vérifier si une session active existe déjà
            if session_key in active_sessions:
                existing_session = active_sessions[session_key]
                # Vérifier si la session est encore valide (moins de 30 minutes)
                session_age = time.time() - existing_session.get('created_timestamp', 0)
                if session_age < 1800:  # 30 minutes
                    logger.info(f"🔄 Réutilisation session existante: {existing_session['room_name']}")
                    # Régénérer le token pour le client
                    new_token = generate_livekit_token(existing_session['room_name'], f"user_{user_id}")
                    existing_session['livekit_token'] = new_token
                    return jsonify(existing_session), 200
                else:
                    # Session expirée, la supprimer
                    logger.info(f"🗑️ Session expirée supprimée: {existing_session['room_name']}")
                    del active_sessions[session_key]
        
        # Créer une nouvelle session
        room_name = f"session_{scenario_id}_{int(time.time())}"
        
        # Générer le token LiveKit
        participant_identity = f"user_{user_id}"
        livekit_token = generate_livekit_token(room_name, participant_identity)
        
        # Message initial selon le scénario
        initial_messages = {
            'debat_politique': "Bienvenue dans ce débat politique. Je suis votre interlocuteur IA. Quel sujet souhaitez-vous aborder ?",
            'coaching_vocal': "Bonjour ! Je suis votre coach vocal IA. Commençons par quelques exercices de diction.",
            'default': "Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider aujourd'hui ?"
        }
        
        initial_message = initial_messages.get(scenario_id, initial_messages['default'])
        
        # Réponse avec les informations de session
        session_data = {
            "session_id": str(uuid.uuid4()),
            "user_id": user_id,
            "scenario_id": scenario_id,
            "language": language,
            "room_name": room_name,
            "livekit_url": LIVEKIT_URL_EXTERNAL,  # Utiliser l'URL externe pour les clients
            "livekit_token": livekit_token,
            "participant_identity": participant_identity,
            "initial_message": {
                "text": initial_message,
                "timestamp": int(time.time())
            },
            "created_at": datetime.utcnow().isoformat(),
            "created_timestamp": time.time(),  # Pour vérifier l'expiration
            "status": "active"
        }
        
        # CORRECTION CRITIQUE: Connecter l'agent AUTOMATIQUEMENT avec identité unique
        unique_suffix = f"{int(time.time())}_{str(uuid.uuid4())[:8]}"
        agent_identity = f"ai_agent_{unique_suffix}"
        
        logger.info(f"🤖 LANCEMENT AGENT AUTOMATIQUE pour room: {room_name} avec identité: {agent_identity}")
        
        # Ajouter l'identité unique aux données de session avant de démarrer l'agent
        session_data['agent_identity'] = agent_identity
        
        # Note: Connexion agent désactivée pour approche REST + Vosk
        logger.info(f"🔧 Session REST + Vosk créée sans agent LiveKit")
        session_data['agent_connected'] = False
        
        # Enregistrer la session dans le registre
        with session_lock:
            active_sessions[session_key] = session_data
            logger.info(f"📝 Session enregistrée: {room_name} (clé: {session_key})")
        
        # TEMPORAIRE: Désactiver Celery pour test agent
        logger.info("🔧 DIAGNOSTIC: Tests Celery désactivés temporairement")
        
        return jsonify(session_data), 201
        
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur création session: {str(e)}")
        return jsonify({"error": f"Erreur lors de la création de session: {str(e)}"}), 500

@app.route('/api/session/start', methods=['POST'])
def start_session():
    """Endpoint alternatif pour démarrer une session (compatibilité)"""
    try:
        data = request.get_json()
        
        # Validation des données requises
        if not data:
            return jsonify({"error": "Données JSON requises"}), 400
            
        user_id = data.get('user_id')
        scenario_id = data.get('scenario_id', 'default')
        language = data.get('language', 'fr')
        
        if not user_id:
            return jsonify({"error": "user_id requis"}), 400
        
        # Générer un nom de room unique
        room_name = f"session_{scenario_id}_{int(time.time())}"
        
        # Générer le token LiveKit
        participant_identity = f"user_{user_id}"
        livekit_token = generate_livekit_token(room_name, participant_identity)
        
        # Réponse simplifiée pour compatibilité
        session_data = {
            "session_id": str(uuid.uuid4()),
            "user_id": user_id,
            "scenario_id": scenario_id,
            "language": language,
            "room_name": room_name,
            "livekit_url": LIVEKIT_URL_EXTERNAL,
            "livekit_token": livekit_token,
            "participant_identity": participant_identity,
            "status": "active",
            "created_at": datetime.utcnow().isoformat()
        }
        
        logger.info(f"✅ Session démarrée via endpoint alternatif: {session_data['session_id']}")
        return jsonify(session_data), 201
        
    except Exception as e:
        logger.error(f"❌ Erreur démarrage session: {str(e)}")
        return jsonify({"error": f"Erreur lors du démarrage de session: {str(e)}"}), 500

@app.route('/api/diagnostic', methods=['GET'])
def get_diagnostic_status():
    """
    DIAGNOSTIC: Endpoint pour vérifier l'état des services
    """
    try:
        logger.info("🔧 DIAGNOSTIC: Vérification état des services")
        
        diagnostic_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "backend_status": "running",
            "services_status": {},
            "celery_status": "unknown"
        }
        
        # Tester la connectivité des services
        import httpx
        import asyncio
        
        async def test_services():
            services = {
                "asr": "http://whisper-stt:8001/health",
                "tts": "http://openai-tts:5002/health", # CHANGÉ de piper-tts
                "redis": "redis://redis:6379"
            }
            
            results = {}
            
            # Test ASR
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(services["asr"], timeout=2.0)
                    results["asr"] = {
                        "status": "ok" if response.status_code == 200 else "error",
                        "response_code": response.status_code
                    }
            except (httpx.RequestError, asyncio.TimeoutError) as e:
                results["asr"] = {"status": "error", "error": f"Connexion ASR échouée: {e}"}
            except Exception as e:
                results["asr"] = {"status": "error", "error": f"Erreur inattendue ASR: {e}"}
            
            # Test TTS
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(services["tts"], timeout=2.0)
                    results["tts"] = {
                        "status": "ok" if response.status_code == 200 else "error",
                        "response_code": response.status_code
                    }
            except (httpx.RequestError, asyncio.TimeoutError) as e:
                results["tts"] = {"status": "error", "error": f"Connexion TTS échouée: {e}"}
            except Exception as e:
                results["tts"] = {"status": "error", "error": f"Erreur inattendue TTS: {e}"}
            
            # Test Redis (via Celery)
            try:
                test_task = example_task.delay("diagnostic_test")
                results["redis"] = {
                    "status": "ok",
                    "celery_task_id": test_task.id
                }
                diagnostic_data["celery_status"] = "ok"
            except Exception as e:
                results["redis"] = {"status": "error", "error": str(e)}
                diagnostic_data["celery_status"] = "error"
            
            return results
        
        # Exécuter les tests de service
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        services_results = loop.run_until_complete(test_services())
        loop.close()
        
        diagnostic_data["services_status"] = services_results
        
        logger.info(f"✅ DIAGNOSTIC: État des services récupéré")
        return jsonify(diagnostic_data), 200
        
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur récupération état: {str(e)}")
        return jsonify({"error": f"Erreur diagnostic: {str(e)}"}), 500

@app.route('/api/diagnostic/logs', methods=['GET'])
def get_diagnostic_logs():
    """
    DIAGNOSTIC: Endpoint pour récupérer les logs de diagnostic
    """
    try:
        # Récupérer les derniers logs (simulation)
        logs = []
        
        return jsonify({
            "logs": logs,
            "timestamp": datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur récupération logs: {str(e)}")
        return jsonify({"error": f"Erreur logs diagnostic: {str(e)}"}), 500

@app.route('/api/confidence-analysis', methods=['POST'])
async def analyze_confidence():
    """
    Analyse de confiance vocale avec VOSK + Mistral (corrigé)
    """
    logger.info("🎯 Requête reçue sur /api/confidence-analysis - transfert vers vosk-stt + mistral")
    
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400

    audio_file = request.files['audio']
    session_id = request.form.get('session_id', f"session_{int(time.time())}")
    scenario = request.form.get('scenario', 'confidence_boost')
    
    try:
        # ÉTAPE 1: Transcription avec Vosk
        async with httpx.AsyncClient() as client:
            files = {'audio': (audio_file.filename, audio_file.read(), audio_file.mimetype)}
            data = {
                'session_id': session_id,
                'scenario': scenario,
                'language': 'fr'
            }
            
            logger.info(f"🔵 Envoi vers Vosk STT: {session_id}")
            vosk_response = await client.post(
                "http://vosk-stt:8002/analyze",
                files=files,
                data=data,
                timeout=30
            )
            vosk_response.raise_for_status()
            vosk_result = vosk_response.json()
            
            transcription = vosk_result.get("transcription", "")
            logger.info(f"✅ Transcription Vosk: {transcription[:100]}...")
            
            if not transcription.strip():
                return jsonify({
                    "error": "Aucune transcription détectée",
                    "transcription": "",
                    "ai_response": "Je n'ai pas pu comprendre votre audio. Pouvez-vous répéter ?",
                    "confidence_score": 0.0
                }), 200
        
        # ÉTAPE 2: Génération réponse IA avec Mistral
        async with httpx.AsyncClient() as client:
            mistral_payload = {
                "model": "mistral-nemo-instruct-2407",
                "messages": [
                    {
                        "role": "system",
                        "content": f"""Tu es Marie, coach en confiance vocale pour l'exercice '{scenario}'.
                        Analyse cette transcription et donne un feedback constructif et encourageant en français.
                        Sois bienveillante, précise et motivante. Limite ta réponse à 2-3 phrases."""
                    },
                    {
                        "role": "user",
                        "content": f"Voici ma réponse à analyser: '{transcription}'"
                    }
                ],
                "temperature": 0.7,
                "max_tokens": 200
            }
            
            logger.info(f"🔵 Envoi vers Mistral: {session_id}")
            mistral_response = await client.post(
                "http://mistral-conversation:8001/v1/chat/completions",
                json=mistral_payload,
                timeout=30
            )
            mistral_response.raise_for_status()
            mistral_result = mistral_response.json()
            
            ai_response = mistral_result["choices"][0]["message"]["content"]
            logger.info(f"✅ Réponse Mistral: {ai_response[:100]}...")
        
        # ÉTAPE 3: Calcul score de confiance basique
        confidence_score = min(0.9, len(transcription.split()) / 10.0)
        
        # ÉTAPE 4: Réponse formatée pour Flutter
        result = {
            "transcription": transcription,
            "ai_response": ai_response,
            "confidence_score": confidence_score,
            "session_id": session_id,
            "scenario": scenario,
            "metrics": {
                "clarity": vosk_result.get("scores", {}).get("clarity", confidence_score),
                "fluency": vosk_result.get("scores", {}).get("fluency", confidence_score),
                "confidence": confidence_score,
                "pace": vosk_result.get("scores", {}).get("pace", 0.7)
            },
            "timestamp": time.time()
        }
        
        logger.info(f"✅ Analyse complète terminée pour {session_id}")
        return jsonify(result), 200

    except httpx.RequestError as e:
        logger.error(f"❌ Erreur réseau: {e}")
        return jsonify({
            "error": f"Erreur de communication: {str(e)}",
            "transcription": "",
            "ai_response": "Désolé, je rencontre un problème technique. Réessayez dans quelques instants.",
            "confidence_score": 0.0
        }), 500
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        return jsonify({
            "error": f"Erreur interne: {str(e)}",
            "transcription": "",
            "ai_response": "Une erreur inattendue s'est produite. Veuillez réessayer.",
            "confidence_score": 0.0
        }), 500

@app.route('/api/sessions/active', methods=['GET'])
def get_active_sessions():
    """
    DIAGNOSTIC: Endpoint pour consulter les sessions actives
    """
    try:
        with session_lock:
            # Nettoyer les sessions expirées
            current_time = time.time()
            expired_keys = []
            for key, session in active_sessions.items():
                session_age = current_time - session.get('created_timestamp', 0)
                if session_age > 1800:  # 30 minutes
                    expired_keys.append(key)
            
            for key in expired_keys:
                logger.info(f"🗑️ Nettoyage session expirée: {active_sessions[key]['room_name']}")
                del active_sessions[key]
            
            sessions_info = {
                "active_sessions": dict(active_sessions),
                "total_active": len(active_sessions),
                "timestamp": datetime.utcnow().isoformat()
            }
        
        logger.info(f"📊 Sessions actives consultées: {len(active_sessions)} sessions")
        return jsonify(sessions_info), 200
        
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur consultation sessions: {str(e)}")
        return jsonify({"error": f"Erreur consultation sessions: {str(e)}"}), 500

@app.route('/api/agents/status', methods=['GET'])
def get_agents_status():
    """
    DIAGNOSTIC: Endpoint pour consulter l'état des agents
    """
    try:
        # Note: Service agent désactivé pour approche REST + Vosk
        agents_info = {
            "active_agents_count": 0,
            "timestamp": datetime.utcnow().isoformat(),
            "service_status": "disabled_rest_mode"
        }
        
        logger.info("🔧 Service agent désactivé - Mode REST + Vosk")
        return jsonify(agents_info), 200
        
    except Exception as e:
        logger.error(f"❌ DIAGNOSTIC: Erreur consultation agents: {str(e)}")
        return jsonify({"error": f"Erreur consultation agents: {str(e)}"}), 500


# SYSTEME ADAPTATIF - Endpoints de monitoring
@app.route('/adaptive/status', methods=['GET'])
def get_adaptive_status():
    """Obtenir le statut du système adaptatif"""
    try:
        # Vérifier si le système adaptatif est disponible
        try:
            from services.streaming_integration import StreamingIntegration
            available = True
        except ImportError:
            available = False
        
        if hasattr(app, 'adaptive_streamer') and app.adaptive_streamer:
            metrics = app.adaptive_streamer.get_performance_report()
            return jsonify({
                'status': 'active',
                'available': True,
                'efficiency': metrics.get('global_efficiency_percent', 0),
                'profile': metrics.get('current_profile', 'unknown'),
                'sessions': metrics.get('sessions_count', 0),
                'improvement': metrics.get('improvement_factor', 0)
            })
        else:
            return jsonify({
                'status': 'available_not_active' if available else 'not_available',
                'available': available,
                'message': 'Systeme adaptatif disponible mais pas encore utilise' if available else 'Fichiers adaptatifs manquants'
            })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'available': False,
            'error': str(e)
        })

@app.route('/adaptive/test', methods=['POST'])
def test_adaptive_system():
    """Tester le système adaptatif"""
    try:
        from services.streaming_integration import StreamingIntegration
        from unittest.mock import Mock
        
        # Mock room pour test
        mock_room = Mock()
        mock_room.local_participant = Mock()
        
        # Test d'intégration
        integration = StreamingIntegration(mock_room, use_adaptive=True)
        
        return jsonify({
            'status': 'success',
            'message': 'Systeme adaptatif fonctionnel',
            'mode': integration.get_current_mode()
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        })

@app.route('/dashboard')
def serve_dashboard():
    """Servir le dashboard adaptatif via le serveur Flask"""
    try:
        import os
        dashboard_path = os.path.join(os.path.dirname(__file__), 'dashboard_adaptive.html')
        return send_file(dashboard_path)
    except Exception as e:
        return jsonify({
            'error': 'Dashboard non trouvé',
            'details': str(e)
        }), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
