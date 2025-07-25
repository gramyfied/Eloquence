from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import vosk
import numpy as np
import logging
from typing import Dict, Any, Optional
import httpx
import os

# Configuration des logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Eloquence Streaming API",
    description="Service de streaming audio et d'analyse en temps réel",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration VOSK (Doit correspondre à celle du service vosk-stt-analysis)
MODEL_PATH = "/app/models/vosk-model-fr-0.22" # Chemin local au contenu du conteneur Docker
SAMPLE_RATE = 16000

# Variables globales pour le modèle Vosk
vosk_model: Optional[vosk.Model] = None

@app.on_event("startup")
async def startup_event():
    global vosk_model
    logger.info("🚀 Démarrage du service de streaming VOSK...")
    # Vérifiez si le modèle est déjà chargé ou téléchargez-le si nécessaire
    if not os.path.exists(MODEL_PATH) or not all(os.listdir(MODEL_PATH)):
        logger.warning(f"⚠️ Modèle Vosk manquant ou incomplet à {MODEL_PATH}. Veuillez vous assurer qu'il est monté ou téléchargé.")
        # Pour le moment, nous n'ajouterons pas la logique de téléchargement ici.
        # Le modèle est censé être monté via Docker.
        # Si vous exécutez ce script directement, assurez-vous que le modèle est présent.
        # Exemple: L'image Docker `vosk-stt-analysis` s'en charge.
    
    try:
        vosk_model = vosk.Model(MODEL_PATH)
        logger.info("✅ Modèle VOSK chargé avec succès pour le streaming.")
    except Exception as e:
        logger.error(f"❌ Erreur critique lors du chargement du modèle VOSK: {e}")
        # En production, cela peut nécessiter un arrêt du service ou un mécanisme de retry
        raise

class VoskStreamProcessor:
    def __init__(self, sample_rate: int = 16000):
        self.sample_rate = sample_rate
        if vosk_model is None:
            raise RuntimeError("VOSK model not loaded.")
        self.recognizer = vosk.KaldiRecognizer(vosk_model, sample_rate)
        self.recognizer.SetWords(True)
        self.recognizer.SetPartialWords(True)
        logger.info(f"VoskStreamProcessor initialisé avec sample_rate: {sample_rate}")
        
    async def process_chunk(self, audio_chunk: bytes) -> Dict[str, Any]:
        """Traite un chunk audio et retourne transcription partielle/finale"""
        
        # Traitement Vosk
        if self.recognizer.AcceptWaveform(audio_chunk):
            # Phrase complète détectée
            result_json = self.recognizer.Result()
            result = json.loads(result_json)
            logger.debug(f"Résultat final Vosk: {result}")
            
            # Calcul scores de confiance et prosodie
            confidence = self._calculate_confidence(result)
            scores = self._calculate_prosody_scores(result)
            
            return {
                "final": True,
                "text": result.get("text", ""),
                "confidence": confidence,
                "scores": scores,
                "words": result.get("result", [])
            }
        else:
            # Transcription partielle
            partial_json = self.recognizer.PartialResult()
            partial = json.loads(partial_json)
            logger.debug(f"Résultat partiel Vosk: {partial}")
            return {
                "partial": partial.get("partial", ""),
                "confidence": 0.5  # Confiance partielle
            }
    
    def _calculate_confidence(self, result: Dict) -> float:
        """Calcule score de confiance global"""
        words = result.get("result", [])
        if not words:
            return 0.0
        
        confidences = [word.get("conf", 0.0) for word in words]
        return sum(confidences) / len(confidences) if confidences else 0.0
    
    def _calculate_prosody_scores(self, result: Dict) -> Dict[str, float]:
        """Calcule scores prosodiques (simplifié)"""
        words = result.get("result", [])
        
        if not words:
            return {"clarity": 0.0, "fluency": 0.0, "pace": 0.0, "confidence": 0.0}
        
        avg_confidence = self._calculate_confidence(result)
        word_count = len(words)
        
        return {
            "clarity": min(1.0, avg_confidence * 1.2),
            "fluency": min(1.0, word_count / 10.0), # Simplifié: basé sur le nombre de mots
            "pace": 0.7,  # Score fixe pour l'instant
            "confidence": avg_confidence
        }

class StreamingManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.vosk_streams: Dict[str, VoskStreamProcessor] = {}
        logger.info("StreamingManager initialisé.")
    
    async def connect(self, websocket: WebSocket, session_id: str):
        await websocket.accept()
        self.active_connections[session_id] = websocket
        try:
            self.vosk_streams[session_id] = VoskStreamProcessor(SAMPLE_RATE)
            logger.info(f"Connexion WebSocket établie et VoskStreamProcessor créé pour session: {session_id}")
        except RuntimeError as e:
            logger.error(f"Échec de la création de VoskStreamProcessor pour session {session_id}: {e}")
            await websocket.close(code=1011) # Indique une erreur interne
            raise
        
    async def disconnect(self, session_id: str):
        if session_id in self.active_connections:
            logger.info(f"Déconnexion WebSocket pour session: {session_id}")
            del self.active_connections[session_id]
        if session_id in self.vosk_streams:
            logger.info(f"VoskStreamProcessor supprimé pour session: {session_id}")
            del self.vosk_streams[session_id]

streaming_manager = StreamingManager()

async def generate_mistral_response(text: str, session_id: str, scenario: str = "confidence_boost") -> str:
    """Génère une réponse via Mistral AI."""
    logger.info(f"🔵 Envoi vers Mistral pour session {session_id} avec texte: {text[:50]}...")
    mistral_payload = {
        "model": "mistral-nemo-instruct-2407",
        "messages": [
            {
                "role": "system",
                "content": f"""Tu es Marie, coach en confiance vocale pour l'exercice '{scenario}'.
                Analyse cette transcription et donne un feedback constructif et encourageant en français.
                Sois bienveillante, précise et motivante. Limite ta réponse à 2-3 phrases.
                Si le texte est vide ou incompréhensible, indique gentiment que tu n'as pas compris."""
            },
            {
                "role": "user",
                "content": f"Voici ma réponse à analyser: '{text}'"
            }
        ],
        "temperature": 0.7,
        "max_tokens": 200
    }
    
    try:
        async with httpx.AsyncClient() as client:
            mistral_response = await client.post(
                "http://mistral-conversation:8001/v1/chat/completions",
                json=mistral_payload,
                timeout=30
            )
            mistral_response.raise_for_status()
            mistral_result = mistral_response.json()
            
            ai_response = mistral_result["choices"][0]["message"]["content"]
            logger.info(f"✅ Réponse Mistral reçue pour session {session_id}: {ai_response[:100]}...")
            return ai_response
    except httpx.RequestError as e:
        logger.error(f"❌ Erreur réseau Mistral pour session {session_id}: {e}")
        return "Désolé, je rencontre un problème technique avec mon cerveau. Réessayez dans quelques instants."
    except Exception as e:
        logger.error(f"❌ Erreur inattendue Mistral pour session {session_id}: {e}")
        return "Une erreur inattendue s'est produite lors de la génération de ma réponse. Veuillez réessayer."

@app.websocket("/ws/confidence-stream/{session_id}")
async def websocket_confidence_stream(websocket: WebSocket, session_id: str):
    logger.info(f"Tentative de connexion WebSocket pour session: {session_id}")
    await streaming_manager.connect(websocket, session_id)
    
    try:
        while True:
            # Recevoir chunk audio de Flutter
            # websocket.receive_bytes() est bloquant, asyncio.wait_for peut ajouter un timeout si nécessaire
            audio_data = await websocket.receive_bytes()
            
            if not audio_data:
                logger.warning(f"Chunk audio vide reçu pour session {session_id}. Ignoré.")
                continue

            vosk_processor = streaming_manager.vosk_streams.get(session_id)
            if not vosk_processor:
                logger.error(f"VoskStreamProcessor non trouvé pour session {session_id}. Déconnexion.")
                await websocket.close(code=1011) # Application Error
                break

            partial_result = await vosk_processor.process_chunk(audio_data)
            
            if partial_result.get("partial"):
                # Transcription partielle
                await websocket.send_json({
                    "type": "partial_transcription",
                    "text": partial_result["partial"],
                    "confidence": partial_result.get("confidence", 0.0)
                })
                logger.debug(f"Partiel envoyé pour session {session_id}: {partial_result['partial']}")
            
            if partial_result.get("final"):
                # Transcription finale - déclencher Mistral
                final_text = partial_result["text"]
                logger.info(f"Final reçu pour session {session_id}: {final_text}")
                
                # Générer réponse IA
                ai_response = await generate_mistral_response(final_text, session_id)
                
                await websocket.send_json({
                    "type": "final_result",
                    "transcription": final_text,
                    "ai_response": ai_response,
                    "confidence_score": partial_result.get("confidence", 0.0),
                    "metrics": partial_result.get("scores", {})
                })
                logger.info(f"Résultat final et AI réponse envoyés pour session {session_id}")
                
    except WebSocketDisconnect:
        logger.info(f"Client WebSocket déconnecté pour session: {session_id}")
    except RuntimeError as e:
        logger.error(f"Erreur d'exécution dans le WebSocket pour session {session_id}: {e}")
    except Exception as e:
        logger.exception(f"Erreur inattendue dans le WebSocket pour session {session_id}: {e}")
    finally:
        await streaming_manager.disconnect(session_id)

@app.get("/health")
async def health_check():
    """Endpoint de vérification de santé pour le service de streaming"""
    return {
        "status": "healthy",
        "service": "eloquence-streaming-api",
        "vosk_model_loaded": vosk_model is not None,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    # Le port 8003 est choisi pour ne pas entrer en conflit avec les autres services
    uvicorn.run(app, host="0.0.0.0", port=8003)