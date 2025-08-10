"""
Gestionnaire de conversations pour Eloquence
Gère les tours de parole, silences et continuité conversationnelle
"""
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional, Callable
from livekit.agents import AgentSession
from conversation_health_monitor import ConversationHealthMonitor

logger = logging.getLogger(__name__)

class ConversationManager:
    """Gère les tours de parole et la continuité conversationnelle"""
    
    def __init__(self, agent_session: AgentSession, exercise_config, silence_timeout=8.0):
        self.agent_session = agent_session
        self.exercise_config = exercise_config
        self.silence_timeout = silence_timeout
        self.last_user_speech = None
        self.last_ai_response = None
        self.conversation_active = True
        self.silence_count = 0
        self.total_interactions = 0
        
        # NOUVEAU: Monitoring de santé
        self.health_monitor = ConversationHealthMonitor(exercise_config.exercise_id)
        
        # Configurer les callbacks avec le health monitor
        self.on_interaction_complete = self.health_monitor.log_interaction
        self.on_silence_timeout = self.health_monitor.log_silence_timeout
        
        logger.info(f"🎯 ConversationManager initialisé pour {exercise_config.exercise_id}")
    
    async def start_conversation_monitoring(self):
        """Démarre la surveillance de la conversation"""
        logger.info("🔄 Démarrage surveillance conversationnelle")
        
        # Tâche de surveillance des silences
        silence_task = asyncio.create_task(self.monitor_silence())
        
        # Message de bienvenue si configuré
        if self.exercise_config.welcome_message:
            await self.send_ai_message(self.exercise_config.welcome_message)
        
        return silence_task
    
    async def handle_user_speech_end(self, user_message: str):
        """Appelé quand l'utilisateur arrête de parler"""
        logger.info(f"👤 Fin de parole utilisateur: '{user_message[:50]}...'")
        
        self.last_user_speech = datetime.now()
        self.total_interactions += 1
        
        # Attendre un court délai pour s'assurer que l'utilisateur a fini
        await asyncio.sleep(1.0)
        
        # Générer et envoyer la réponse IA
        start_time = datetime.now()
        ai_response = await self.generate_ai_response(user_message)
        response_time = (datetime.now() - start_time).total_seconds()
        
        if ai_response:
            await self.send_ai_message(ai_response)
            self.last_ai_response = datetime.now()
            
            # Callback pour monitoring
            if self.on_interaction_complete:
                await self.on_interaction_complete(user_message, ai_response, response_time)
        else:
            logger.error("❌ Aucune réponse IA générée")
            await self.send_fallback_response()
    
    async def generate_ai_response(self, user_message: str) -> str:
        """Génère une réponse IA contextuelle"""
        try:
            # Construire le contexte conversationnel
            context = self.build_conversation_context(user_message)
            
            # Générer la réponse via l'agent
            # Note: Adapter selon l'API LiveKit exacte
            response = await self.agent_session.generate_response(context)
            
            if response and len(response.strip()) > 0:
                logger.info(f"🤖 Réponse IA générée: '{response[:50]}...'")
                return response.strip()
            else:
                logger.warning("⚠️ Réponse IA vide")
                return None
                
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse IA: {e}")
            return None
    
    def build_conversation_context(self, user_message: str) -> str:
        """Construit le contexte conversationnel"""
        context_parts = []
        
        # Instructions spécialisées
        context_parts.append(self.exercise_config.instructions)
        
        # Contexte de silence si applicable
        if self.silence_count > 0:
            context_parts.append(f"\nCONTEXTE: L'utilisateur a été silencieux {self.silence_count} fois. Sois plus encourageant.")
        
        # Contexte d'interaction
        if self.total_interactions == 1:
            context_parts.append("\nCONTEXTE: Première interaction, sois accueillant.")
        elif self.total_interactions > 10:
            context_parts.append("\nCONTEXTE: Conversation avancée, approfondis les sujets.")
        
        # Message utilisateur
        context_parts.append(f"\nUTILISATEUR: {user_message}")
        context_parts.append("\nRÉPONDS EN 1-2 PHRASES MAXIMUM:")
        
        return "\n".join(context_parts)
    
    async def send_ai_message(self, message: str):
        """Envoie un message IA à l'utilisateur"""
        try:
            await self.agent_session.say(text=message)
            logger.info(f"🤖 Message IA envoyé: '{message[:50]}...'")
        except Exception as e:
            logger.error(f"❌ Erreur envoi message IA: {e}")
    
    async def send_fallback_response(self):
        """Envoie une réponse de fallback en cas d'erreur"""
        fallback_messages = {
            'confidence_boost': "Je vous écoute attentivement. Continuez, vous vous en sortez très bien !",
            'tribunal_idees_impossibles': "Maître, la cour vous écoute. Développez votre argumentation.",
            'default': "Je vous écoute. Continuez, s'il vous plaît."
        }
        
        message = fallback_messages.get(
            self.exercise_config.exercise_id, 
            fallback_messages['default']
        )
        
        await self.send_ai_message(message)
    
    async def monitor_silence(self):
        """Surveille les silences et relance la conversation"""
        logger.info("👂 Surveillance des silences activée")
        
        while self.conversation_active:
            await asyncio.sleep(2.0)
            
            if self.last_user_speech:
                silence_duration = (datetime.now() - self.last_user_speech).total_seconds()
                
                if silence_duration > self.silence_timeout:
                    await self.handle_silence_timeout(silence_duration)
                    self.last_user_speech = datetime.now()  # Reset timer
    
    async def handle_silence_timeout(self, silence_duration: float):
        """Gère les timeouts de silence"""
        self.silence_count += 1
        logger.info(f"⏰ Timeout silence #{self.silence_count} après {silence_duration:.1f}s")
        
        # Messages de relance spécialisés
        silence_messages = self.get_silence_messages()
        
        if self.silence_count <= len(silence_messages):
            message = silence_messages[self.silence_count - 1]
            await self.send_ai_message(message)
        else:
            # Silence prolongé, message générique
            await self.send_ai_message("Je reste à votre disposition quand vous souhaitez continuer.")
        
        # Callback pour monitoring
        if self.on_silence_timeout:
            await self.on_silence_timeout(silence_duration, self.silence_count)
    
    def get_silence_messages(self) -> list:
        """Retourne les messages de relance spécialisés par exercice"""
        messages = {
            'confidence_boost': [
                "Je vous écoute, prenez votre temps...",
                "N'hésitez pas à partager ce qui vous passe par la tête.",
                "Voulez-vous qu'on commence par un exercice simple ?"
            ],
            'tribunal_idees_impossibles': [
                "Maître, la cour attend votre argumentation...",
                "Prenez votre temps pour structurer votre plaidoirie.",
                "Souhaitez-vous que la cour vous propose une thèse impossible ?"
            ],
            'studio_situations_pro': [
                "Prenez votre temps pour réfléchir...",
                "Y a-t-il un point sur lequel vous aimeriez revenir ?",
                "Voulez-vous qu'on aborde un autre aspect ?"
            ],
            'default': [
                "Je vous écoute...",
                "Continuez quand vous êtes prêt.",
                "Que souhaitez-vous faire maintenant ?"
            ]
        }
        
        return messages.get(self.exercise_config.exercise_id, messages['default'])
    
    def stop_conversation(self):
        """Arrête la surveillance de la conversation"""
        self.conversation_active = False
        self.health_monitor.stop_monitoring()
        logger.info("🛑 Surveillance conversationnelle arrêtée")
    
    def get_conversation_stats(self) -> dict:
        """Retourne les statistiques de conversation"""
        return {
            'total_interactions': self.total_interactions,
            'silence_timeouts': self.silence_count,
            'conversation_duration': (
                (datetime.now() - self.last_user_speech).total_seconds() 
                if self.last_user_speech else 0
            ),
            'last_activity': self.last_user_speech.isoformat() if self.last_user_speech else None
        }
    
    def get_health_report(self):
        """Retourne le rapport de santé conversationnelle"""
        return self.health_monitor.get_health_report()