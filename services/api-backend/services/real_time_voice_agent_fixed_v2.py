import asyncio
import logging
import os
import json
import aiohttp
from dotenv import load_dotenv
from typing import Union, Literal
from dataclasses import dataclass

from livekit import agents
from livekit.agents import (
    AgentSession,
    Agent,
    JobContext,
    tts,
    llm,
)
from livekit.agents.llm import (
    LLMStream,
    ChatContext,
    ChatChunk,
    ChoiceDelta,
    CompletionUsage,
)
from livekit.agents.llm.chat_context import ChatRole
from livekit.agents.tts import SynthesizeStream
from livekit.plugins import silero

# Charger les variables d'environnement du fichier .env
load_dotenv()

# Configuration du logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


# --- Plugins Personnalisés (Compatible livekit-agents v1.1.5) ---

@dataclass
class ConnectionOptions:
    timeout: float = 30.0

class MistralLLMStream(LLMStream):
    def __init__(
        self,
        llm: "MistralLLM",
        chat_ctx: ChatContext,
        conn_options: ConnectionOptions,
        api_key: str,
        model: str,
        base_url: str,
    ):
        super().__init__(llm=llm, chat_ctx=chat_ctx, tools=[], conn_options=conn_options)
        self._api_key = api_key
        self._model = model
        self._base_url = base_url
        self._conn_options = conn_options

    async def _run(self) -> None:
        messages = self._prepare_messages()
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        payload = {"model": self._model, "messages": messages, "stream": True}
        
        logger.debug(f"🔵 [MISTRAL] Envoi à Mistral - Base URL: {self._base_url}, Payload: {payload}, Headers: {{'Authorization': 'Bearer ...'}}")

        try:
            timeout = aiohttp.ClientTimeout(total=self._conn_options.timeout)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(
                    self._base_url, json=payload, headers=headers
                ) as response:
                    response.raise_for_status()
                    async for line in response.content:
                        line = line.decode("utf-8").strip()
                        if not line or not line.startswith("data: "):
                            continue
                        if line == "data: [DONE]":
                            break
                        try:
                            json_data = line[6:]
                            data = json.loads(json_data)
                            chunk = self._create_chat_chunk(data)
                            self._event_ch.send_nowait(chunk)
                        except json.JSONDecodeError:
                            logger.warning(f"Failed to parse JSON: {json_data}")
        except aiohttp.ClientResponseError as e:
            if e.status == 401:
                logger.error(f"❌ [MISTRAL] Clé API Mistral invalide ou manquante (401 Unauthorized)")
                # Envoyer une réponse de fallback au lieu de faire planter l'agent
                fallback_chunk = self._create_fallback_chunk()
                self._event_ch.send_nowait(fallback_chunk)
            else:
                logger.error(f"❌ [MISTRAL] Erreur HTTP {e.status}: {e}")
                # Log du contenu de la réponse pour debug
                try:
                    error_text = await e.response.text()
                    logger.error(f"❌ [MISTRAL] Détails de l'erreur: {error_text}")
                except:
                    pass
                fallback_chunk = self._create_fallback_chunk()
                self._event_ch.send_nowait(fallback_chunk)
        except Exception as e:
            logger.error(f"❌ [MISTRAL] Erreur inattendue: {e}")
            # Envoyer une réponse de fallback au lieu de faire planter l'agent
            fallback_chunk = self._create_fallback_chunk()
            self._event_ch.send_nowait(fallback_chunk)

    def _prepare_messages(self) -> list[dict]:
        """Prépare les messages pour l'API Mistral - CORRIGÉ pour éviter les messages consécutifs du même rôle"""
        
        try:
            messages = []
            
            # Message système par défaut
            system_message = {
                "role": "system",
                "content": "You are a helpful voice AI assistant for eloquence coaching. Be encouraging and provide clear feedback."
            }
            messages.append(system_message)
            
            # Accéder aux messages via l'attribut 'items' (nouvelle API v1.1.5)
            if hasattr(self._chat_ctx, 'items') and self._chat_ctx.items:
                logger.info(f"✅ [CHATCONTEXT] Trouvé {len(self._chat_ctx.items)} messages via 'items'")
                
                last_role = "system"  # Pour suivre le dernier rôle ajouté
                
                for msg in self._chat_ctx.items:
                    # Convertir le ChatMessage en format Mistral
                    if hasattr(msg, 'role') and hasattr(msg, 'content'):
                        # Gérer le contenu qui peut être une liste ou une chaîne
                        content = msg.content
                        if isinstance(content, list):
                            content = ' '.join(str(item) for item in content)
                        elif not isinstance(content, str):
                            content = str(content)
                        
                        # Filtrer les messages avec contenu vide
                        if content.strip():
                            # Éviter les messages consécutifs du même rôle
                            if msg.role == last_role and msg.role == "assistant":
                                logger.warning(f"⚠️ [CHATCONTEXT] Message assistant consécutif ignoré pour éviter l'erreur 400")
                                continue
                            
                            # Ignorer les messages système supplémentaires
                            if msg.role == "system":
                                continue
                                
                            messages.append({
                                "role": msg.role,
                                "content": content
                            })
                            last_role = msg.role
                            logger.debug(f"[CHATCONTEXT] Message ajouté: {msg.role} -> {content[:50]}...")
                        else:
                            logger.warning(f"⚠️ [CHATCONTEXT] Message ignoré avec contenu vide pour le rôle {msg.role}.")
                
                # S'assurer que le dernier message n'est pas un message assistant
                # Si c'est le cas, ajouter un message user générique
                if messages and messages[-1]["role"] == "assistant":
                    logger.info("ℹ️ [CHATCONTEXT] Ajout d'un message user pour équilibrer la conversation")
                    messages.append({
                        "role": "user",
                        "content": "Continue"
                    })
            
            # Validation finale : s'assurer qu'on a au moins un message système
            if not messages:
                messages.append(system_message)
            
            logger.info(f"✅ [CHATCONTEXT] {len(messages)} messages préparés pour Mistral API")
            # Log de la structure des messages pour debug
            roles_sequence = [msg["role"] for msg in messages]
            logger.debug(f"[CHATCONTEXT] Séquence des rôles: {roles_sequence}")
            
            return messages
            
        except Exception as e:
            logger.error(f"❌ [CHATCONTEXT] Erreur lors de la préparation des messages: {e}")
            # Fallback en cas d'erreur
            return [{
                "role": "system",
                "content": "You are a helpful voice AI assistant for eloquence coaching."
            }]

    def _create_chat_chunk(self, data: dict) -> ChatChunk:
        content = ""
        if 'choices' in data and len(data['choices']) > 0:
            choice = data['choices'][0]
            if 'delta' in choice and 'content' in choice['delta']:
                content = choice['delta']['content'] or ""
        
        delta = ChoiceDelta(role="assistant", content=content)
        return ChatChunk(delta=delta, id=data.get('id', ''))

    def _create_fallback_chunk(self) -> ChatChunk:
        """Create a fallback ChatChunk when API calls fail."""
        fallback_message = "Je rencontre des difficultés techniques avec le service LLM. Pouvez-vous répéter votre question ?"
        delta = ChoiceDelta(role="assistant", content=fallback_message)
        return ChatChunk(delta=delta, id="fallback")


class MistralLLM(llm.LLM):
    def __init__(self):
        super().__init__()
        self._api_key = os.environ.get("MISTRAL_API_KEY")
        self._model = os.getenv("MISTRAL_MODEL", "mistral-small-latest")
        self._base_url = os.getenv("MISTRAL_BASE_URL", "https://api.mistral.ai/v1/chat/completions")

    def chat(
        self,
        *,
        chat_ctx: ChatContext,
        conn_options: ConnectionOptions | None = None,
        **kwargs,
    ) -> LLMStream:
        conn_options = conn_options or ConnectionOptions()
        return MistralLLMStream(
            llm=self,
            chat_ctx=chat_ctx,
            conn_options=conn_options,
            api_key=self._api_key,
            model=self._model,
            base_url=self._base_url,
        )


class LocalOpenAITTSStream(SynthesizeStream):
    def __init__(
        self,
        tts: "LocalOpenAITTS",
        text: str,
        endpoint: str,
        conn_options: ConnectionOptions,
        api_key: str,
    ):
        super().__init__(tts=tts, conn_options=conn_options)
        self._text = text
        self._endpoint = endpoint
        self._conn_options = conn_options
        self._api_key = api_key

    async def _run(self, *args, **kwargs) -> None:
        """CORRIGÉ: Validation du texte et gestion d'erreur améliorée"""
        output_emitter = kwargs.get('output_emitter') if 'output_emitter' in kwargs else (args[0] if args else None)
        if not output_emitter:
            logger.error("❌ [TTS] output_emitter n'a pas été trouvé dans _run")
            raise ValueError("output_emitter est requis pour SynthesizeStream")

        # CORRECTION: Valider que le texte n'est pas vide
        if not self._text or not self._text.strip():
            logger.warning("⚠️ [TTS] Texte vide reçu, utilisation d'un texte par défaut")
            self._text = "Je suis là pour vous aider."

        payload = {"model": "tts-1", "input": self._text, "voice": "alloy", "response_format": "pcm"}
        headers = {"Authorization": f"Bearer {self._api_key}"}
        
        logger.debug(f"🔵 [TTS] Envoi à OpenAI TTS - Endpoint: {self._endpoint}, Text: '{self._text[:50]}...', Headers: {{'Authorization': 'Bearer ...'}}")

        try:
            timeout = aiohttp.ClientTimeout(total=self._conn_options.timeout)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(self._endpoint, json=payload, headers=headers) as response:
                    response.raise_for_status()
                    audio_data = await response.read()
                    chunk_size = 4096
                    for i in range(0, len(audio_data), chunk_size):
                        # CORRIGÉ: Utiliser output_emitter au lieu de self._event_ch
                        await output_emitter(
                            tts.SynthesizeStreamData(data=audio_data[i : i + chunk_size])
                        )
                        await asyncio.sleep(0.01)
                    logger.info(f"✅ [TTS] Audio généré avec succès: {len(audio_data)} bytes pour le texte: '{self._text[:50]}...'")
        except aiohttp.ClientResponseError as e:
            logger.error(f"❌ [TTS] Erreur HTTP {e.status} dans LocalOpenAITTSStream._run")
            # Log du contenu de la réponse pour debug
            try:
                error_text = await e.response.text()
                logger.error(f"❌ [TTS] Détails de l'erreur: {error_text}")
            except:
                pass
            # Ne pas propager l'erreur pour éviter de faire planter l'agent
            # Envoyer un audio vide ou silence
            silence_data = b'\x00' * 4096  # 4KB de silence
            await output_emitter(tts.SynthesizeStreamData(data=silence_data))
        except Exception as e:
            logger.error(f"❌ [TTS] Erreur inattendue dans LocalOpenAITTSStream._run: {e}")
            # Envoyer un audio vide ou silence
            silence_data = b'\x00' * 4096  # 4KB de silence
            await output_emitter(tts.SynthesizeStreamData(data=silence_data))


class LocalOpenAITTS(tts.TTS):
    def __init__(self):
        super().__init__(
            capabilities=tts.TTSCapabilities(streaming=True),
            sample_rate=16000,
            num_channels=1
        )
        self._endpoint = "https://api.openai.com/v1/audio/speech"  # Utilisation de l'API OpenAI externe, URL directe
        self._api_key = os.getenv("OPENAI_API_KEY")  # Récupération de la clé API

    def synthesize(
        self, *, text: str, conn_options: ConnectionOptions | None = None
    ) -> SynthesizeStream:
        conn_options = conn_options or ConnectionOptions()
        # CORRECTION: Valider le texte avant de créer le stream
        if not text or not text.strip():
            logger.warning("⚠️ [TTS] synthesize() appelé avec texte vide, utilisation d'un texte par défaut")
            text = "Je suis là pour vous aider."
        
        return LocalOpenAITTSStream(
            tts=self, text=text, endpoint=self._endpoint, conn_options=conn_options, api_key=self._api_key
        )

    def stream(self, *, conn_options: ConnectionOptions | None = None) -> SynthesizeStream:
        """Méthode stream() requise pour le streaming TTS dans livekit-agents v1.1.5"""
        conn_options = conn_options or ConnectionOptions()
        # Pour le streaming, on retourne un stream vide qui sera alimenté par synthesize()
        return LocalOpenAITTSStream(
            tts=self, text="", endpoint=self._endpoint, conn_options=conn_options, api_key=self._api_key
        )


# --- Agent ---

# Définition de notre agent personnalisé
class EloquenceCoach(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions="You are a helpful voice AI assistant for eloquence coaching. Be encouraging and provide clear feedback. Always respond in French."
        )
        # Compteur pour suivre les erreurs consécutives
        self.error_count = 0
        self.max_errors = 3

    # Cette méthode est appelée lorsque l'agent doit répondre.
    # Pour l'instant, nous laissons AgentSession la gérer implicitement.

async def entrypoint(ctx: agents.JobContext):
    """
    Point d'entrée principal pour le worker de l'agent, utilisant le framework moderne v1.0.
    """
    logger.info("🚀 [ENTRYPOINT] Démarrage du job de l'agent (v1.0)")

    # Utilisation de nos plugins personnalisés
    session = AgentSession(
        llm=MistralLLM(),
        tts=LocalOpenAITTS(),
        vad=silero.VAD.load(),
    )

    # L'agent personnalisé qui définit le comportement
    agent = EloquenceCoach()

    # Démarrer la session. AgentSession gère automatiquement la création
    # et la publication des pistes audio.
    logger.info("🔧 [SESSION] Démarrage de la session Agent...")
    await session.start(
        room=ctx.room,
        agent=agent,
    )
    logger.info("✅ [SESSION] Session Agent démarrée.")

    # Connexion à la room
    await ctx.connect()
    logger.info(f"✅ [ROOM] Agent connecté à la room: {ctx.room.name}")

    # Envoyer un message de bienvenue pour indiquer que l'agent est prêt
    logger.info("🎙️ [WELCOME] Envoi du message de bienvenue...")
    try:
        await session.generate_reply(
            instructions="Bonjour ! Je suis votre coach d'éloquence IA. Je suis maintenant connecté et prêt à vous aider. Parlez-moi pour commencer notre session."
        )
        logger.info("✅ [WELCOME] Message de bienvenue envoyé.")
    except Exception as e:
        logger.error(f"❌ [WELCOME] Erreur lors de l'envoi du message de bienvenue: {e}")

    # Surveiller les événements de transcription (STT) et les messages du chat
    try:
        async for e in session.events():
            if isinstance(e, agents.Agent.AgentSpeechEvent):
                if e.type == agents.Agent.AgentSpeechEventTypes.STARTED:
                    logger.info("🔊 [SPEECH] Détection de parole STARTED")
                elif e.type == agents.Agent.AgentSpeechEventTypes.FINISHED:
                    logger.info("🔊 [SPEECH] Détection de parole FINISHED")
            elif isinstance(e, agents.Agent.AgentUserSpeechEvent):
                logger.info(f"🗣️ [USER_SPEECH] Transcription utilisateur: {e.text}")
                if e.text:
                    logger.info(f"✅ [STT] Texte transcrit non vide: {e.text}")
                    # Réinitialiser le compteur d'erreurs sur une interaction réussie
                    agent.error_count = 0
                else:
                    logger.warning(f"⚠️ [STT] Texte transcrit vide reçu.")
            elif isinstance(e, agents.Agent.AgentChatMessageEvent):
                logger.info(f"💬 [CHAT] Message de chat reçu: {e.message.body}")
                # Réinitialiser le compteur d'erreurs sur une interaction réussie
                agent.error_count = 0
    except Exception as e:
        logger.error(f"❌ [EVENTS] Erreur dans la boucle d'événements: {e}")
        agent.error_count += 1
        
        # Si trop d'erreurs consécutives, essayer de réinitialiser le contexte
        if agent.error_count >= agent.max_errors:
            logger.warning("⚠️ [AGENT] Trop d'erreurs consécutives, tentative de réinitialisation du contexte")
            try:
                # Réinitialiser le contexte de chat si possible
                if hasattr(session, '_chat_ctx'):
                    session._chat_ctx.clear()
                    logger.info("✅ [AGENT] Contexte de chat réinitialisé")
                agent.error_count = 0
            except Exception as reset_e:
                logger.error(f"❌ [AGENT] Erreur lors de la réinitialisation: {reset_e}")

# Point d'entrée principal du script
if __name__ == "__main__":
    print("[MAIN] Demarrage du worker de l'agent Eloquence (v1.0)...", flush=True)
    
    # Utilisation de la méthode recommandée pour lancer l'agent.
    # cli.run_app gère la boucle asyncio, la création du worker, et les signaux d'arrêt.
    agents.cli.run_app(agents.WorkerOptions(entrypoint_fnc=entrypoint))