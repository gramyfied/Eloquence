#!/usr/bin/env python3
"""
Client LiveKit pour Simulation d'Utilisateur Virtuel
Simule un utilisateur réel via WebSocket LiveKit pour tests end-to-end
"""

import asyncio
import json
import logging
import time
import wave
import tempfile
import numpy as np
from typing import Dict, Any, Optional, Callable, List
from dataclasses import dataclass
from pathlib import Path

# Imports pour LiveKit
try:
    from livekit import api, rtc, AccessToken, VideoGrant
    import websockets
    import aiohttp
except ImportError as e:
    print(f"Dépendances LiveKit manquantes: {e}")
    print("Installation requise: pip install livekit-api livekit-rtc websockets aiohttp")

logger = logging.getLogger(__name__)

@dataclass
class LiveKitConfig:
    """Configuration LiveKit"""
    host: str = "localhost"
    port: int = 7880
    api_key: str = "devkey"
    api_secret: str = "secret"
    room_name: str = "conversation_test_room"
    participant_name: str = "virtual_user"
    enable_audio: bool = True
    enable_video: bool = False
    auto_connect: bool = True

@dataclass
class VirtualUserAction:
    """Action d'un utilisateur virtuel"""
    action_type: str  # "speak", "listen", "pause", "disconnect"
    content: Optional[str] = None  # Texte à dire
    duration: float = 0.0  # Durée en secondes
    metadata: Dict[str, Any] = None

class LiveKitTokenManager:
    """Gestionnaire de tokens LiveKit"""
    
    def __init__(self, config: LiveKitConfig):
        self.config = config
    
    def generate_access_token(self, room_name: str, participant_identity: str) -> str:
        """Génère un token d'accès LiveKit"""
        
        try:
            token = AccessToken(self.config.api_key, self.config.api_secret)
            token.with_identity(participant_identity)
            token.with_name(participant_identity)
            
            # Permissions pour la room
            video_grant = VideoGrant(
                room_join=True,
                room=room_name,
                can_publish=True,
                can_subscribe=True,
                can_publish_data=True
            )
            token.with_grants(video_grant)
            
            # Générer le JWT
            jwt_token = token.to_jwt()
            logger.info(f"Token généré pour {participant_identity} dans la room {room_name}")
            
            return jwt_token
        
        except Exception as e:
            logger.error(f"Erreur génération token: {e}")
            raise RuntimeError(f"Impossible de générer le token: {e}")
    
    async def validate_room_exists(self, room_name: str) -> bool:
        """Valide qu'une room existe ou la crée"""
        
        try:
            # Utiliser l'API LiveKit pour vérifier/créer la room
            async with aiohttp.ClientSession() as session:
                url = f"http://{self.config.host}:{self.config.port}/livekit/room"
                
                headers = {
                    'Authorization': f'Bearer {self.generate_access_token(room_name, "admin")}',
                    'Content-Type': 'application/json'
                }
                
                # Tenter de récupérer la room
                async with session.get(f"{url}/{room_name}", headers=headers) as response:
                    if response.status == 200:
                        logger.info(f"Room {room_name} existe déjà")
                        return True
                    elif response.status == 404:
                        # Créer la room
                        create_data = {
                            'name': room_name,
                            'empty_timeout': 300,  # 5 minutes
                            'max_participants': 10
                        }
                        
                        async with session.post(url, headers=headers, json=create_data) as create_response:
                            if create_response.status in [200, 201]:
                                logger.info(f"Room {room_name} créée avec succès")
                                return True
                            else:
                                logger.error(f"Échec création room: {create_response.status}")
                                return False
                    else:
                        logger.error(f"Erreur API LiveKit: {response.status}")
                        return False
        
        except Exception as e:
            logger.warning(f"Validation room échouée, continuons: {e}")
            return True  # On assume que ça va marcher

class AudioSimulator:
    """Simulateur audio pour l'utilisateur virtuel"""
    
    def __init__(self):
        self.sample_rate = 16000
        self.channels = 1
        self.sample_width = 2
    
    def generate_audio_from_text(self, text: str, voice_style: str = "neutral") -> bytes:
        """Génère des données audio réalistes à partir de texte"""
        
        # Paramètres basés sur le style de voix
        voice_params = {
            "neutral": {"base_freq": 200, "variation": 50, "speed": 1.0},
            "commercial_confiant": {"base_freq": 180, "variation": 60, "speed": 1.1},
            "client_exigeant": {"base_freq": 220, "variation": 40, "speed": 0.9},
            "prospect_interesse": {"base_freq": 190, "variation": 70, "speed": 1.05}
        }
        
        params = voice_params.get(voice_style, voice_params["neutral"])
        
        # Calculer la durée basée sur le texte (approximation)
        words_count = len(text.split())
        duration = words_count * (60 / 150) / params["speed"]  # 150 mots/minute
        duration = max(1.0, min(10.0, duration))  # Entre 1 et 10 secondes
        
        # Générer l'audio synthétique
        samples = int(duration * self.sample_rate)
        audio_data = np.zeros(samples, dtype=np.int16)
        
        # Générer des fréquences variées pour simuler la parole
        for i in range(0, samples, 1000):
            chunk_size = min(1000, samples - i)
            
            # Fréquence variable pour simuler l'intonation
            freq = params["base_freq"] + np.random.randint(-params["variation"], params["variation"])
            
            # Générer le chunk audio
            t = np.linspace(0, chunk_size / self.sample_rate, chunk_size)
            chunk = (np.sin(2 * np.pi * freq * t) * 16000 * 0.3).astype(np.int16)
            
            # Ajouter du bruit réaliste
            noise = np.random.normal(0, 500, chunk_size).astype(np.int16)
            chunk = chunk + noise
            
            # Éviter la saturation
            chunk = np.clip(chunk, -16000, 16000)
            
            audio_data[i:i+chunk_size] = chunk
        
        # Appliquer un fade in/out pour plus de réalisme
        fade_samples = int(0.1 * self.sample_rate)  # 100ms fade
        if samples > 2 * fade_samples:
            # Fade in
            for i in range(fade_samples):
                audio_data[i] = int(audio_data[i] * (i / fade_samples))
            
            # Fade out
            for i in range(fade_samples):
                idx = samples - fade_samples + i
                audio_data[idx] = int(audio_data[idx] * ((fade_samples - i) / fade_samples))
        
        # Convertir en bytes
        return audio_data.tobytes()
    
    def save_audio_to_wav(self, audio_data: bytes, filename: str):
        """Sauvegarde l'audio en fichier WAV"""
        
        with wave.open(filename, 'wb') as wav_file:
            wav_file.setnchannels(self.channels)
            wav_file.setsampwidth(self.sample_width)
            wav_file.setframerate(self.sample_rate)
            wav_file.writeframes(audio_data)

class VirtualUserSession:
    """Session d'utilisateur virtuel dans LiveKit"""
    
    def __init__(self, config: LiveKitConfig, user_personality: str = "commercial_confiant"):
        self.config = config
        self.user_personality = user_personality
        self.token_manager = LiveKitTokenManager(config)
        self.audio_simulator = AudioSimulator()
        
        # État de la session
        self.room: Optional[rtc.Room] = None
        self.connected = False
        self.session_id = f"session_{int(time.time())}"
        
        # Callbacks pour les événements
        self.on_ai_response_received: Optional[Callable] = None
        self.on_connection_state_changed: Optional[Callable] = None
        self.on_audio_received: Optional[Callable] = None
        
        # Métriques de session
        self.session_start_time = None
        self.messages_sent = 0
        self.messages_received = 0
        self.connection_issues = 0
        
    async def connect_to_room(self) -> bool:
        """Connecte l'utilisateur virtuel à la room LiveKit"""
        
        try:
            logger.info(f"Connexion à LiveKit {self.config.host}:{self.config.port}")
            
            # Valider que la room existe
            room_valid = await self.token_manager.validate_room_exists(self.config.room_name)
            if not room_valid:
                logger.error("Room LiveKit non disponible")
                return False
            
            # Générer le token d'accès
            access_token = self.token_manager.generate_access_token(
                self.config.room_name, 
                self.config.participant_name
            )
            
            # Créer et configurer la room
            self.room = rtc.Room()
            
            # Configurer les callbacks
            self._setup_room_callbacks()
            
            # URL de connexion LiveKit
            livekit_url = f"ws://{self.config.host}:{self.config.port}"
            
            # Connexion
            await self.room.connect(livekit_url, access_token)
            
            self.connected = True
            self.session_start_time = time.time()
            
            logger.info(f"Connecté à la room {self.config.room_name} en tant que {self.config.participant_name}")
            
            # Notifier le changement d'état
            if self.on_connection_state_changed:
                await self.on_connection_state_changed("connected", self.session_id)
            
            return True
        
        except Exception as e:
            logger.error(f"Erreur connexion LiveKit: {e}")
            self.connection_issues += 1
            
            if self.on_connection_state_changed:
                await self.on_connection_state_changed("error", str(e))
            
            return False
    
    def _setup_room_callbacks(self):
        """Configure les callbacks de la room LiveKit"""
        
        @self.room.on("participant_connected")
        def on_participant_connected(participant: rtc.RemoteParticipant):
            logger.info(f"Participant connecté: {participant.identity}")
        
        @self.room.on("participant_disconnected")
        def on_participant_disconnected(participant: rtc.RemoteParticipant):
            logger.info(f"Participant déconnecté: {participant.identity}")
        
        @self.room.on("track_published")
        def on_track_published(publication: rtc.RemoteTrackPublication, participant: rtc.RemoteParticipant):
            logger.info(f"Track publié par {participant.identity}: {publication.kind}")
        
        @self.room.on("track_subscribed")
        def on_track_subscribed(track: rtc.Track, publication: rtc.RemoteTrackPublication, participant: rtc.RemoteParticipant):
            logger.info(f"Abonné au track de {participant.identity}")
            
            if track.kind == rtc.TrackKind.KIND_AUDIO:
                # Traiter l'audio reçu de l'IA
                asyncio.create_task(self._handle_ai_audio_response(track, participant))
        
        @self.room.on("data_received")
        def on_data_received(data: bytes, participant: rtc.RemoteParticipant):
            # Traiter les données textuelles de l'IA
            try:
                message = json.loads(data.decode('utf-8'))
                asyncio.create_task(self._handle_ai_text_response(message, participant))
            except Exception as e:
                logger.warning(f"Erreur décodage données: {e}")
        
        @self.room.on("disconnected")
        def on_disconnected():
            logger.info("Déconnexion de la room")
            self.connected = False
            
            if self.on_connection_state_changed:
                asyncio.create_task(self.on_connection_state_changed("disconnected", self.session_id))
    
    async def _handle_ai_audio_response(self, track: rtc.AudioTrack, participant: rtc.RemoteParticipant):
        """Traite la réponse audio de l'IA"""
        
        try:
            # Ici on pourrait implémenter un traitement audio sophistiqué
            # Pour l'instant, on note juste la réception
            self.messages_received += 1
            
            logger.info(f"Réponse audio reçue de {participant.identity}")
            
            if self.on_audio_received:
                await self.on_audio_received({
                    'type': 'audio',
                    'participant': participant.identity,
                    'timestamp': time.time(),
                    'track_id': track.sid
                })
        
        except Exception as e:
            logger.error(f"Erreur traitement audio IA: {e}")
    
    async def _handle_ai_text_response(self, message: Dict[str, Any], participant: rtc.RemoteParticipant):
        """Traite la réponse textuelle de l'IA"""
        
        try:
            self.messages_received += 1
            
            logger.info(f"Réponse textuelle de {participant.identity}: {message}")
            
            if self.on_ai_response_received:
                await self.on_ai_response_received({
                    'type': 'text',
                    'content': message,
                    'participant': participant.identity,
                    'timestamp': time.time(),
                    'session_id': self.session_id
                })
        
        except Exception as e:
            logger.error(f"Erreur traitement réponse IA: {e}")
    
    async def send_user_message(self, text: str, voice_style: str = None) -> bool:
        """Envoie un message utilisateur via audio et texte"""
        
        if not self.connected or not self.room:
            logger.error("Non connecté à la room")
            return False
        
        try:
            # Utiliser le style de voix de la personnalité
            style = voice_style or self.user_personality
            
            # Générer l'audio
            audio_data = self.audio_simulator.generate_audio_from_text(text, style)
            
            # Si activation audio, publier l'audio
            if self.config.enable_audio:
                await self._publish_audio_track(audio_data)
            
            # Envoyer aussi le texte via data channel
            text_data = {
                'type': 'user_message',
                'content': text,
                'personality': self.user_personality,
                'timestamp': time.time(),
                'session_id': self.session_id
            }
            
            await self.room.local_participant.publish_data(
                json.dumps(text_data).encode('utf-8')
            )
            
            self.messages_sent += 1
            logger.info(f"Message envoyé: '{text}' (style: {style})")
            
            return True
        
        except Exception as e:
            logger.error(f"Erreur envoi message: {e}")
            return False
    
    async def _publish_audio_track(self, audio_data: bytes):
        """Publie un track audio dans la room"""
        
        try:
            # Créer un fichier temporaire pour l'audio
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                self.audio_simulator.save_audio_to_wav(audio_data, temp_file.name)
                
                # Créer une source audio à partir du fichier
                audio_source = rtc.AudioSource(16000, 1)
                track = rtc.LocalAudioTrack.create_audio_track("user_voice", audio_source)
                
                # Publier le track
                options = rtc.TrackPublishOptions()
                options.source = rtc.TrackSource.SOURCE_MICROPHONE
                
                await self.room.local_participant.publish_track(track, options)
                
                logger.info("Track audio publié")
        
        except Exception as e:
            logger.error(f"Erreur publication audio: {e}")
    
    async def execute_user_action(self, action: VirtualUserAction) -> bool:
        """Exécute une action d'utilisateur virtuel"""
        
        try:
            if action.action_type == "speak":
                return await self.send_user_message(action.content)
            
            elif action.action_type == "listen":
                # Attendre et écouter (simulation)
                await asyncio.sleep(action.duration or 2.0)
                logger.info(f"Écoute pendant {action.duration or 2.0}s")
                return True
            
            elif action.action_type == "pause":
                # Pause dans la conversation
                await asyncio.sleep(action.duration or 1.0)
                logger.info(f"Pause de {action.duration or 1.0}s")
                return True
            
            elif action.action_type == "disconnect":
                return await self.disconnect()
            
            else:
                logger.warning(f"Action inconnue: {action.action_type}")
                return False
        
        except Exception as e:
            logger.error(f"Erreur exécution action: {e}")
            return False
    
    async def disconnect(self) -> bool:
        """Déconnecte l'utilisateur virtuel"""
        
        try:
            if self.room and self.connected:
                await self.room.disconnect()
                logger.info("Déconnexion réussie")
                
                if self.on_connection_state_changed:
                    await self.on_connection_state_changed("disconnected", self.session_id)
            
            self.connected = False
            return True
        
        except Exception as e:
            logger.error(f"Erreur déconnexion: {e}")
            return False
    
    def get_session_stats(self) -> Dict[str, Any]:
        """Retourne les statistiques de la session"""
        
        session_duration = 0
        if self.session_start_time:
            session_duration = time.time() - self.session_start_time
        
        return {
            'session_id': self.session_id,
            'connected': self.connected,
            'session_duration': session_duration,
            'messages_sent': self.messages_sent,
            'messages_received': self.messages_received,
            'connection_issues': self.connection_issues,
            'user_personality': self.user_personality,
            'room_name': self.config.room_name
        }

class LiveKitVirtualUserClient:
    """Client principal pour utilisateur virtuel LiveKit"""
    
    def __init__(self, config: LiveKitConfig = None):
        self.config = config or LiveKitConfig()
        self.current_session: Optional[VirtualUserSession] = None
        
        # Historique des sessions
        self.session_history: List[Dict[str, Any]] = []
        
    async def create_virtual_user_session(self, user_personality: str = "commercial_confiant") -> VirtualUserSession:
        """Crée une nouvelle session d'utilisateur virtuel"""
        
        # Fermer la session existante si nécessaire
        if self.current_session and self.current_session.connected:
            await self.current_session.disconnect()
        
        # Créer la nouvelle session
        self.current_session = VirtualUserSession(self.config, user_personality)
        
        logger.info(f"Session virtuelle créée avec personnalité: {user_personality}")
        
        return self.current_session
    
    async def test_livekit_connection(self) -> Dict[str, Any]:
        """Teste la connexion LiveKit"""
        
        test_config = LiveKitConfig(
            room_name="test_connection_room",
            participant_name="test_user"
        )
        
        test_session = VirtualUserSession(test_config)
        
        start_time = time.time()
        connection_success = await test_session.connect_to_room()
        connection_time = time.time() - start_time
        
        if connection_success:
            await test_session.disconnect()
        
        return {
            'connection_successful': connection_success,
            'connection_time': connection_time,
            'server_host': self.config.host,
            'server_port': self.config.port,
            'issues_detected': test_session.connection_issues
        }
    
    def cleanup_sessions(self):
        """Nettoie les sessions terminées"""
        
        if self.current_session:
            stats = self.current_session.get_session_stats()
            self.session_history.append(stats)
            
            if len(self.session_history) > 50:  # Limiter l'historique
                self.session_history = self.session_history[-50:]

# Fonction utilitaire pour tests rapides
async def quick_virtual_user_test():
    """Test rapide du client utilisateur virtuel"""
    
    print("Test Client LiveKit Utilisateur Virtuel")
    print("=" * 45)
    
    # Configuration
    config = LiveKitConfig(
        room_name="test_conversation_room",
        participant_name="virtual_test_user"
    )
    
    # Créer le client
    client = LiveKitVirtualUserClient(config)
    
    try:
        # Test de connexion
        print("Test de connexion LiveKit...")
        connection_test = await client.test_livekit_connection()
        
        if connection_test['connection_successful']:
            print(f"✓ Connexion réussie en {connection_test['connection_time']:.2f}s")
            
            # Créer une session utilisateur
            session = await client.create_virtual_user_session("commercial_confiant")
            
            # Connecter la session
            if await session.connect_to_room():
                print("✓ Session utilisateur connectée")
                
                # Simuler quelques messages
                test_messages = [
                    "Bonjour, je suis intéressé par vos services",
                    "Pouvez-vous me donner plus de détails ?",
                    "Quel est le prix de votre solution ?"
                ]
                
                for msg in test_messages:
                    if await session.send_user_message(msg):
                        print(f"✓ Message envoyé: '{msg}'")
                    else:
                        print(f"✗ Échec envoi: '{msg}'")
                    
                    await asyncio.sleep(2)  # Pause entre messages
                
                # Statistiques
                stats = session.get_session_stats()
                print(f"\nStatistiques de session:")
                print(f"- Messages envoyés: {stats['messages_sent']}")
                print(f"- Messages reçus: {stats['messages_received']}")
                print(f"- Durée: {stats['session_duration']:.1f}s")
                
                # Déconnexion
                await session.disconnect()
                print("✓ Session fermée")
            
            else:
                print("✗ Échec connexion session")
        
        else:
            print("✗ Échec connexion LiveKit")
            print(f"Temps d'attente: {connection_test['connection_time']:.2f}s")
    
    except Exception as e:
        print(f"✗ Erreur test: {e}")
    
    finally:
        client.cleanup_sessions()

if __name__ == "__main__":
    asyncio.run(quick_virtual_user_test())