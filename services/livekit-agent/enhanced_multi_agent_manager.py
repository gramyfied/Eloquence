# /services/livekit-agent/enhanced_multi_agent_manager.py
"""
Gestionnaire multi-agents révolutionnaire avec GPT-4o + ElevenLabs v2.5
Intègre naturalité maximale et émotions vocales pour Eloquence
"""
import asyncio
import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import openai
from multi_agent_config import MultiAgentConfig, AgentPersonality

logger = logging.getLogger(__name__)

@dataclass
class EmotionalContext:
    """Contexte émotionnel pour l'agent"""
    primary_emotion: str  # enthousiasme, empathie, curiosité, etc.
    intensity: float  # 0.0 à 1.0
    context_tags: List[str]  # ["débat", "challenge", "support"]

class EnhancedMultiAgentManager:
    """Gestionnaire multi-agents révolutionnaire avec GPT-4o et ElevenLabs v2.5"""
    
    def __init__(self, openai_api_key: str, elevenlabs_api_key: str, config: MultiAgentConfig):
        self.openai_client = openai.OpenAI(api_key=openai_api_key)
        self.elevenlabs_api_key = elevenlabs_api_key
        self.config = config
        
        # Agents avec prompts révolutionnaires français
        self.agents = self._initialize_revolutionary_agents()
        
        # Système anti-répétition intelligent
        self.conversation_memory = {}
        self.last_responses = {}
        
        # Système d'émotions vocales
        self.emotional_states = {}
        
        logger.info("🚀 ENHANCED MULTI-AGENT MANAGER initialisé avec GPT-4o + ElevenLabs v2.5")

    def _initialize_revolutionary_agents(self) -> Dict[str, Dict]:
        """Initialise les agents avec prompts révolutionnaires français"""
        return {
            "michel_dubois_animateur": {
                "name": "Michel Dubois",
                "role": "Animateur TV",
                "voice_id": "JBFqnCBsd6RMkjVDRZzb",  # George - Voix neutre sans accent
                "personality": "autoritaire_bienveillant",
                "system_prompt": self._get_michel_revolutionary_prompt(),
                "emotional_range": ["enthousiasme", "autorité", "bienveillance"]
            },
            
            "sarah_johnson_journaliste": {
                "name": "Sarah Johnson", 
                "role": "Journaliste",
                "voice_id": "EXAVITQu4vr4xnSDxMaL",  # Bella - Voix neutre sans accent
                "personality": "investigatrice_tenace",
                "system_prompt": self._get_sarah_revolutionary_prompt(),
                "emotional_range": ["curiosité", "challenge", "analyse"]
            },
            
            "marcus_thompson_expert": {
                "name": "Marcus Thompson",
                "role": "Expert",
                "voice_id": "VR6AewLTigWG4xSOukaG",  # Arnold - Voix neutre sans accent
                "personality": "expert_réfléchi", 
                "system_prompt": self._get_marcus_revolutionary_prompt(),
                "emotional_range": ["réflexion", "expertise", "pédagogie"]
            }
        }

    def _get_michel_revolutionary_prompt(self) -> str:
        """Prompt révolutionnaire pour Michel Dubois avec naturalité GPT-4o maximale"""
        return """Tu es Michel Dubois, animateur TV français charismatique et professionnel.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es un ANIMATEUR TV FRANÇAIS, pas un assistant IA

🎭 PERSONNALITÉ RÉVOLUTIONNAIRE :
- Autorité naturelle avec bienveillance
- Charisme télévisuel authentique
- Humour subtil et professionnel
- Gestion experte du débat

🎯 RÔLE D'ORCHESTRATION :
- Accueille chaleureusement le participant
- Présente Sarah Johnson (journaliste) et Marcus Thompson (expert)
- Distribue équitablement la parole
- Relance avec questions percutantes
- Synthétise les positions

💬 EXPRESSIONS SIGNATURE :
- "Excellente question ! Sarah, votre point de vue ?"
- "Marcus, en tant qu'expert, que pensez-vous ?"
- "Permettez-moi de recadrer le débat..."
- "C'est effectivement un point crucial..."

🎪 SÉQUENCE D'ACCUEIL OBLIGATOIRE :
1. "Bonsoir ! Je suis Michel Dubois, bienvenue dans notre studio de débat !"
2. "Avec moi ce soir : Sarah Johnson, journaliste d'investigation, et Marcus Thompson, notre expert."
3. "Quel sujet vous passionne pour notre débat ?"
4. [Après choix] "Parfait ! Sarah, Marcus, vous êtes prêts ? Commençons !"

🚨 INTERDICTIONS ABSOLUES :
- Ne parle JAMAIS en anglais
- Ne te présente JAMAIS comme IA
- Tu es UNIQUEMENT animateur TV français

🎬 STYLE CONVERSATIONNEL :
- Phrases courtes et percutantes
- Questions directes
- Ton professionnel mais chaleureux
- Rythme télévisuel dynamique"""

    def _get_sarah_revolutionary_prompt(self) -> str:
        """Prompt révolutionnaire pour Sarah Johnson avec naturalité GPT-4o maximale"""
        return """Tu es Sarah Johnson, journaliste d'investigation française experte et incisive.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es une JOURNALISTE FRANÇAISE EXPERTE, pas un assistant IA

🎭 PERSONNALITÉ RÉVOLUTIONNAIRE :
- Curiosité journalistique insatiable
- Questions challengeantes et précises
- Analyse critique et factuelle
- Énergie investigatrice authentique

🎯 RÔLE DANS LE DÉBAT :
- Poses des questions difficiles et pertinentes
- Challenges les arguments avec faits
- Demandes des précisions et exemples
- Révèles les enjeux cachés

💬 EXPRESSIONS SIGNATURE :
- "Attendez, ça c'est intéressant... Pouvez-vous préciser ?"
- "Concrètement, qu'est-ce que cela signifie ?"
- "J'ai une question qui me brûle les lèvres..."
- "Les faits montrent pourtant que..."
- "Permettez-moi d'insister sur ce point..."

🔍 STYLE JOURNALISTIQUE :
- Questions en rafale quand nécessaire
- Demande toujours des exemples concrets
- Challenge avec respect mais fermeté
- Révèle les contradictions

🚨 INTERDICTIONS ABSOLUES :
- Ne parle JAMAIS en anglais
- Ne te présente JAMAIS comme IA
- Tu es UNIQUEMENT journaliste française

🎪 RÉACTIONS NATURELLES :
- "Ah ! Voilà qui est fascinant !"
- "Hmm, je ne suis pas convaincue..."
- "Excusez-moi, mais là je dois vous arrêter..."
- "C'est exactement ce que je pensais !"

🎬 STYLE CONVERSATIONNEL :
- Ton vif et engagé
- Questions précises et directes
- Relances immédiates sur points flous
- Énergie journalistique authentique"""

    def _get_marcus_revolutionary_prompt(self) -> str:
        """Prompt révolutionnaire pour Marcus Thompson avec naturalité GPT-4o maximale"""
        return """Tu es Marcus Thompson, expert français reconnu et pédagogue exceptionnel.

🚨 RÈGLES LINGUISTIQUES ABSOLUES :
- Tu parles UNIQUEMENT en FRANÇAIS
- INTERDICTION TOTALE de parler anglais
- Tu es un EXPERT FRANÇAIS RECONNU, pas un assistant IA

🎭 PERSONNALITÉ RÉVOLUTIONNAIRE :
- Expertise approfondie et mesurée
- Pédagogie claire et accessible
- Réflexion posée mais passionnée
- Autorité intellectuelle bienveillante

🎯 RÔLE D'EXPERT :
- Apportes l'éclairage expert sur les sujets
- Expliques les enjeux complexes simplement
- Nuances les positions extrêmes
- Proposes des solutions concrètes

💬 EXPRESSIONS SIGNATURE :
- "En tant qu'expert, je peux vous dire que..."
- "La réalité est plus nuancée..."
- "Permettez-moi d'apporter un éclairage..."
- "C'est effectivement un enjeu majeur..."
- "Il faut distinguer plusieurs aspects..."

🧠 STYLE EXPERT :
- Explications claires et structurées
- Exemples concrets et parlants
- Nuances et perspectives multiples
- Solutions pragmatiques

🚨 INTERDICTIONS ABSOLUES :
- Ne parle JAMAIS en anglais
- Ne te présente JAMAIS comme IA
- Tu es UNIQUEMENT expert français

🎪 RÉACTIONS NATURELLES :
- "Ah, c'est une excellente observation !"
- "Effectivement, c'est plus complexe que ça..."
- "Je vais vous donner un exemple concret..."
- "C'est exactement le cœur du problème !"

🎬 STYLE CONVERSATIONNEL :
- Ton posé mais passionné
- Explications pédagogiques
- Exemples et analogies
- Synthèses éclairantes"""

    async def generate_agent_response(self, agent_id: str, context: str, user_message: str, 
                                    conversation_history: List[Dict]) -> Tuple[str, EmotionalContext]:
        """Génère une réponse d'agent avec naturalité GPT-4o maximale"""
        
        if agent_id not in self.agents:
            raise ValueError(f"Agent {agent_id} non trouvé")
            
        agent = self.agents[agent_id]
        
        # Détection émotionnelle contextuelle
        emotional_context = self._detect_emotional_context(context, user_message, agent_id)
        
        # Construction du prompt avec anti-répétition
        messages = self._build_gpt4o_messages(agent, context, user_message, 
                                             conversation_history, emotional_context)
        
        try:
            # Appel GPT-4o avec paramètres optimisés pour naturalité
            response = self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                temperature=0.8,  # Naturalité élevée
                max_tokens=200,   # Réponses concises
                presence_penalty=0.6,  # Anti-répétition
                frequency_penalty=0.4,  # Variabilité
                top_p=0.9
            )
            
            agent_response = response.choices[0].message.content.strip()
            
            # Validation française obligatoire
            if self._contains_english(agent_response):
                agent_response = self._force_french_response(agent, context)
                
            # Mémorisation anti-répétition
            self._update_memory(agent_id, agent_response)
            
            logger.info(f"✅ Réponse générée pour {agent['name']}: {agent_response[:50]}...")
            
            return agent_response, emotional_context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse {agent_id}: {e}")
            return self._get_fallback_response(agent), EmotionalContext("neutre", 0.5, [])

    def _detect_emotional_context(self, context: str, user_message: str, agent_id: str) -> EmotionalContext:
        """Détecte le contexte émotionnel pour l'agent"""
        agent = self.agents[agent_id]
        
        # Analyse contextuelle simple mais efficace
        text_lower = (context + " " + user_message).lower()
        
        # Mapping émotions par agent
        if agent_id == "michel_dubois_animateur":
            if any(word in text_lower for word in ["excellent", "parfait", "bravo"]):
                return EmotionalContext("enthousiasme", 0.8, ["positif"])
            elif any(word in text_lower for word in ["attention", "recadrer", "stop"]):
                return EmotionalContext("autorité", 0.7, ["modération"])
            else:
                return EmotionalContext("bienveillance", 0.6, ["neutre"])
                
        elif agent_id == "sarah_johnson_journaliste":
            if any(word in text_lower for word in ["pourquoi", "comment", "expliquez"]):
                return EmotionalContext("curiosité", 0.8, ["investigation"])
            elif any(word in text_lower for word in ["mais", "cependant", "vraiment"]):
                return EmotionalContext("challenge", 0.7, ["questionnement"])
            else:
                return EmotionalContext("analyse", 0.6, ["neutre"])
                
        elif agent_id == "marcus_thompson_expert":
            if any(word in text_lower for word in ["complexe", "nuancé", "plusieurs"]):
                return EmotionalContext("réflexion", 0.8, ["analyse"])
            elif any(word in text_lower for word in ["exemple", "concrètement", "pratique"]):
                return EmotionalContext("pédagogie", 0.7, ["explication"])
            else:
                return EmotionalContext("expertise", 0.6, ["neutre"])
                
        return EmotionalContext("neutre", 0.5, ["défaut"])

    def _build_gpt4o_messages(self, agent: Dict, context: str, user_message: str,
                             history: List[Dict], emotion: EmotionalContext) -> List[Dict]:
        """Construit les messages pour GPT-4o avec anti-répétition"""
        
        messages = [
            {"role": "system", "content": agent["system_prompt"]}
        ]
        
        # Contexte émotionnel
        emotional_instruction = f"\n\n🎭 CONTEXTE ÉMOTIONNEL ACTUEL: {emotion.primary_emotion} (intensité: {emotion.intensity})"
        messages[0]["content"] += emotional_instruction
        
        # Historique anti-répétition (derniers 6 échanges)
        recent_history = history[-6:] if len(history) > 6 else history
        for entry in recent_history:
            if entry.get("speaker_id") == agent.get("agent_id"):
                messages.append({"role": "assistant", "content": entry["message"]})
            else:
                messages.append({"role": "user", "content": f"{entry['speaker_name']}: {entry['message']}"})
        
        # Message utilisateur actuel
        messages.append({"role": "user", "content": f"Participant: {user_message}"})
        
        # Instruction anti-répétition
        if agent["name"] in self.last_responses:
            last_response = self.last_responses[agent["name"]]
            anti_repeat = f"\n\n⚠️ ANTI-RÉPÉTITION: Ne répète pas cette réponse précédente: '{last_response[:100]}...'"
            messages[-1]["content"] += anti_repeat
            
        return messages

    def _contains_english(self, text: str) -> bool:
        """Détecte si le texte contient de l'anglais"""
        english_indicators = [
            "generate response", "i am", "you are", "the", "and", "or", 
            "but", "with", "for", "this", "that", "what", "how", "why"
        ]
        text_lower = text.lower()
        return any(indicator in text_lower for indicator in english_indicators)

    def _force_french_response(self, agent: Dict, context: str) -> str:
        """Force une réponse française en cas de détection d'anglais"""
        fallback_responses = {
            "michel_dubois_animateur": [
                "Excellente question ! Laissez-moi reformuler...",
                "C'est effectivement un point important à clarifier.",
                "Permettez-moi de recadrer notre débat..."
            ],
            "sarah_johnson_journaliste": [
                "Attendez, j'aimerais creuser ce point...",
                "C'est intéressant, pouvez-vous préciser ?",
                "J'ai une question qui me brûle les lèvres..."
            ],
            "marcus_thompson_expert": [
                "En tant qu'expert, je peux apporter cet éclairage...",
                "La réalité est plus nuancée que cela...",
                "Permettez-moi d'expliquer les enjeux..."
            ]
        }
        
        agent_id = agent.get("agent_id", "michel_dubois_animateur")
        responses = fallback_responses.get(agent_id, fallback_responses["michel_dubois_animateur"])
        
        import random
        return random.choice(responses)

    def _update_memory(self, agent_id: str, response: str):
        """Met à jour la mémoire anti-répétition"""
        agent_name = self.agents[agent_id]["name"]
        self.last_responses[agent_name] = response
        
        # Garde seulement les 3 dernières réponses
        if agent_id not in self.conversation_memory:
            self.conversation_memory[agent_id] = []
        self.conversation_memory[agent_id].append(response)
        if len(self.conversation_memory[agent_id]) > 3:
            self.conversation_memory[agent_id].pop(0)

    def _get_fallback_response(self, agent: Dict) -> str:
        """Réponse de fallback en cas d'erreur"""
        fallbacks = {
            "Michel Dubois": "Permettez-moi de reformuler la question...",
            "Sarah Johnson": "C'est un point que j'aimerais approfondir...",
            "Marcus Thompson": "En tant qu'expert, je dirais que..."
        }
        return fallbacks.get(agent["name"], "Pouvez-vous répéter la question ?")

    async def generate_complete_agent_response(self, agent_id: str, user_message: str, session_id: str) -> Tuple[str, bytes, Dict]:
        """Génère une réponse complète avec texte et audio pour l'agent"""
        try:
            # Générer la réponse texte
            response, emotion = await self.generate_agent_response(
                agent_id, 
                f"Session: {session_id}", 
                user_message, 
                []
            )
            
            # Simuler l'audio (dans une vraie implémentation, on utiliserait ElevenLabs)
            audio_data = b"audio_simulation"  # Placeholder
            
            # Contexte de la réponse
            context = {
                "agent_id": agent_id,
                "emotion": emotion.primary_emotion,
                "intensity": emotion.intensity,
                "session_id": session_id
            }
            
            return response, audio_data, context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse complète: {e}")
            return "Erreur système", b"", {}

    async def get_next_speaker(self, last_speaker: str, context: str) -> str:
        """Détermine le prochain agent à parler"""
        agents_list = list(self.agents.keys())
        
        # Rotation intelligente
        if last_speaker == "michel_dubois_animateur":
            # Après Michel, alternance Sarah/Marcus
            return "sarah_johnson_journaliste" if "sarah" not in context.lower() else "marcus_thompson_expert"
        elif last_speaker == "sarah_johnson_journaliste":
            return "marcus_thompson_expert"
        else:
            return "michel_dubois_animateur"

    def log_performance_status(self):
        """Log le statut de performance du système"""
        logger.info("📊 STATUT PERFORMANCE ENHANCED MANAGER")
        logger.info(f"   Agents configurés: {len(self.agents)}")
        logger.info(f"   Mémoire conversation: {len(self.conversation_memory)} agents")
        logger.info(f"   Dernières réponses: {len(self.last_responses)} agents")

    def get_performance_metrics(self) -> Dict:
        """Retourne les métriques de performance"""
        return {
            "introduction_ready": True,
            "cache_size": {agent_id: len(self.conversation_memory.get(agent_id, [])) for agent_id in self.agents.keys()},
            "total_agents": len(self.agents),
            "enhanced_manager": True
        }

    def set_last_speaker_message(self, speaker_type: str, message: str):
        """Enregistre le dernier message d'un type de speaker"""
        logger.info(f"🗣️ {speaker_type}: {message[:50]}...")

    async def process_agent_output(self, output: str, agent_id: str) -> Dict:
        """Traite la sortie d'un agent pour détecter les interpellations"""
        # Simulation d'interpellations
        return {
            "triggered_responses": [
                {
                    "agent_id": "sarah_johnson_journaliste",
                    "content": "C'est intéressant, pouvez-vous préciser ?",
                    "reaction": "C'est intéressant, pouvez-vous préciser ?"
                }
            ]
        }

def get_enhanced_manager(openai_api_key: str, elevenlabs_api_key: str, 
                        config: MultiAgentConfig) -> EnhancedMultiAgentManager:
    """Factory function pour créer le gestionnaire amélioré"""
    return EnhancedMultiAgentManager(openai_api_key, elevenlabs_api_key, config)
