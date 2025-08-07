"""
Gestionnaire des interactions multi-agents pour Studio Situations Pro
"""
import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
import logging

from multi_agent_config import (
    MultiAgentConfig, 
    AgentPersonality, 
    InteractionStyle
)

logger = logging.getLogger(__name__)


@dataclass
class ConversationEntry:
    """Entrée dans l'historique de conversation"""
    speaker_id: str
    speaker_name: str
    message: str
    timestamp: datetime
    is_user: bool = False
    
    def to_dict(self) -> Dict:
        return {
            "speaker_id": self.speaker_id,
            "speaker_name": self.speaker_name,
            "message": self.message,
            "timestamp": self.timestamp.isoformat(),
            "is_user": self.is_user
        }


class MultiAgentManager:
    """Gestionnaire des interactions multi-agents"""
    
    def __init__(self, config: MultiAgentConfig):
        self.config = config
        self.agents: Dict[str, AgentPersonality] = {
            agent.agent_id: agent for agent in config.agents
        }
        self.current_speaker: Optional[str] = None
        self.conversation_history: List[ConversationEntry] = []
        self.turn_queue: List[str] = []
        self.session_start_time = datetime.now()
        self.last_speaker_change = datetime.now()
        self.speaking_times: Dict[str, float] = {agent_id: 0.0 for agent_id in self.agents}
        self.interaction_count: Dict[str, int] = {agent_id: 0 for agent_id in self.agents}
        self.is_session_active = False
        
    def initialize_session(self):
        """Initialise une nouvelle session de simulation"""
        logger.info(f"🎭 Initialisation session multi-agents: {self.config.exercise_id}")
        
        # Réinitialiser les métriques
        self.conversation_history.clear()
        self.session_start_time = datetime.now()
        self.last_speaker_change = datetime.now()
        self.speaking_times = {agent_id: 0.0 for agent_id in self.agents}
        self.interaction_count = {agent_id: 0 for agent_id in self.agents}
        self.is_session_active = True
        
        # Configurer l'ordre initial des tours
        self.setup_turn_management()
        
        logger.info(f"✅ Session initialisée avec {len(self.agents)} agents")
        
    def setup_turn_management(self):
        """Configure la gestion des tours de parole"""
        if self.config.turn_management == "moderator_controlled":
            # L'animateur contrôle qui parle
            moderator = self.find_agent_by_style(InteractionStyle.MODERATOR)
            if moderator:
                self.current_speaker = moderator.agent_id
                self.turn_queue = [
                    agent_id for agent_id in self.agents 
                    if agent_id != moderator.agent_id
                ]
                logger.info(f"🎯 Mode modérateur: {moderator.name} contrôle les tours")
        elif self.config.turn_management == "round_robin":
            # Tour à tour dans l'ordre
            self.turn_queue = list(self.agents.keys())
            self.current_speaker = self.turn_queue[0] if self.turn_queue else None
            logger.info("🔄 Mode round-robin activé")
        elif self.config.turn_management == "client_controlled":
            # Le client dirige
            client = self.find_agent_by_style(InteractionStyle.CHALLENGER)
            if client:
                self.current_speaker = client.agent_id
                logger.info(f"💼 Mode client: {client.name} dirige")
        else:
            # Par défaut: round robin
            self.turn_queue = list(self.agents.keys())
            self.current_speaker = self.turn_queue[0] if self.turn_queue else None
            
    def find_agent_by_style(self, style: InteractionStyle) -> Optional[AgentPersonality]:
        """Trouve un agent par son style d'interaction"""
        for agent in self.agents.values():
            if agent.interaction_style == style:
                return agent
        return None
    
    async def handle_user_input(self, user_message: str) -> Dict[str, Any]:
        """Gère l'input utilisateur et orchestre les réponses des agents"""
        
        if not self.is_session_active:
            logger.warning("⚠️ Session inactive, initialisation...")
            self.initialize_session()
        
        # Ajouter le message utilisateur à l'historique
        user_entry = ConversationEntry(
            speaker_id="user",
            speaker_name="Utilisateur",
            message=user_message,
            timestamp=datetime.now(),
            is_user=True
        )
        self.conversation_history.append(user_entry)
        
        logger.info(f"👤 Message utilisateur reçu: {user_message[:50]}...")
        
        # Déterminer quel agent doit répondre
        responding_agent_id = await self.determine_next_speaker(user_message)
        
        # Générer la réponse de l'agent principal
        primary_response = await self.generate_agent_response(
            responding_agent_id, 
            user_message
        )
        
        # Déclencher les réactions des autres agents si nécessaire
        secondary_responses = await self.trigger_agent_reactions(
            responding_agent_id, 
            primary_response
        )
        
        # Construire la réponse complète
        response = {
            "primary_speaker": responding_agent_id,
            "primary_response": primary_response,
            "secondary_responses": secondary_responses,
            "conversation_history": [entry.to_dict() for entry in self.conversation_history[-10:]],
            "session_metrics": self.get_session_metrics()
        }
        
        return response
    
    async def determine_next_speaker(self, user_message: str) -> str:
        """Détermine intelligemment quel agent doit répondre"""
        
        # Analyse du contexte du message
        message_lower = user_message.lower()
        
        # Détection de mots-clés pour orienter vers le bon agent
        if self.config.turn_management == "moderator_controlled":
            moderator = self.find_agent_by_style(InteractionStyle.MODERATOR)
            if moderator:
                # Le modérateur répond toujours en premier sauf si question spécifique
                if any(keyword in message_lower for keyword in ["technique", "techniquement", "code", "architecture"]):
                    expert = self.find_agent_by_style(InteractionStyle.EXPERT)
                    if expert:
                        logger.info(f"🎯 Question technique détectée -> {expert.name}")
                        return expert.agent_id
                        
                logger.info(f"🎙️ Modérateur répond: {moderator.name}")
                return moderator.agent_id
                
        elif self.config.turn_management == "round_robin":
            # Passer au suivant dans la liste
            next_speaker = self.get_next_in_rotation()
            logger.info(f"🔄 Tour de: {self.agents[next_speaker].name}")
            return next_speaker
            
        elif self.config.turn_management == "client_controlled":
            # Le client dirige mais peut déléguer
            client = self.find_agent_by_style(InteractionStyle.CHALLENGER)
            if client:
                if "technique" in message_lower or "comment" in message_lower:
                    # Déléguer à l'expert technique
                    support = self.find_agent_by_style(InteractionStyle.SUPPORTIVE)
                    if support:
                        logger.info(f"🔧 Client délègue à: {support.name}")
                        return support.agent_id
                        
                logger.info(f"💼 Client répond: {client.name}")
                return client.agent_id
                
        # Par défaut: premier agent disponible
        if not self.current_speaker and self.agents:
            return list(self.agents.keys())[0]
            
        return self.current_speaker or list(self.agents.keys())[0]
    
    def get_next_in_rotation(self) -> str:
        """Obtient le prochain agent dans la rotation"""
        if not self.turn_queue:
            self.turn_queue = list(self.agents.keys())
            
        if self.current_speaker in self.turn_queue:
            current_index = self.turn_queue.index(self.current_speaker)
            next_index = (current_index + 1) % len(self.turn_queue)
            return self.turn_queue[next_index]
        
        return self.turn_queue[0] if self.turn_queue else list(self.agents.keys())[0]
    
    async def generate_agent_response(self, agent_id: str, user_message: str) -> str:
        """Génère la réponse d'un agent spécifique"""
        
        if agent_id not in self.agents:
            logger.error(f"❌ Agent inconnu: {agent_id}")
            return "Désolé, une erreur s'est produite."
            
        agent = self.agents[agent_id]
        
        # Construire le contexte pour l'agent
        context = self.build_agent_context(agent_id, user_message)
        
        # Simuler le temps de réflexion
        await asyncio.sleep(0.5)
        
        # Générer une réponse contextuelle basée sur la personnalité
        # (En production, ceci appellerait le LLM)
        response = await self.simulate_agent_response(agent, context, user_message)
        
        # Mettre à jour les métriques
        speaking_duration = 3.0  # Durée simulée en secondes
        self.speaking_times[agent_id] += speaking_duration
        self.interaction_count[agent_id] += 1
        
        # Ajouter à l'historique
        agent_entry = ConversationEntry(
            speaker_id=agent_id,
            speaker_name=agent.name,
            message=response,
            timestamp=datetime.now(),
            is_user=False
        )
        self.conversation_history.append(agent_entry)
        
        # Mettre à jour le speaker actuel
        self.current_speaker = agent_id
        self.last_speaker_change = datetime.now()
        
        logger.info(f"🗣️ {agent.name}: {response[:50]}...")
        
        return response
    
    async def simulate_agent_response(self, agent: AgentPersonality, context: str, user_message: str) -> str:
        """Simule une réponse d'agent (remplacer par appel LLM en production)"""
        
        # Réponses simulées basées sur le rôle et le style
        if agent.interaction_style == InteractionStyle.MODERATOR:
            responses = [
                f"Excellente question ! {user_message[:30]}... est effectivement un point crucial.",
                f"Permettez-moi de reformuler : vous vous interrogez sur {user_message[:30]}...",
                "C'est un aspect fondamental. Qui souhaite apporter son expertise sur ce point ?",
                "Très pertinent ! Prenons un moment pour explorer cette dimension."
            ]
        elif agent.interaction_style == InteractionStyle.CHALLENGER:
            responses = [
                f"Mais concrètement, comment garantissez-vous que {user_message[:30]}... ?",
                "Les données montrent pourtant une tendance différente...",
                "Permettez-moi de challenger cette approche : n'est-ce pas risqué ?",
                "J'ai besoin de plus de détails sur l'implémentation pratique."
            ]
        elif agent.interaction_style == InteractionStyle.EXPERT:
            responses = [
                f"D'un point de vue technique, {user_message[:30]}... nécessite une approche structurée.",
                "Mon expérience dans le domaine montre que trois facteurs sont critiques ici...",
                "Il est important de considérer le contexte historique de cette problématique.",
                "Permettez-moi d'apporter une perspective plus nuancée sur ce sujet."
            ]
        elif agent.interaction_style == InteractionStyle.INTERVIEWER:
            responses = [
                f"Pouvez-vous me donner un exemple concret de {user_message[:30]}... ?",
                "Comment avez-vous géré une situation similaire dans le passé ?",
                "Qu'est-ce qui vous motive particulièrement dans cette approche ?",
                "Parlons de vos compétences dans ce domaine spécifique."
            ]
        else:  # SUPPORTIVE
            responses = [
                f"C'est effectivement un point important. Pour compléter...",
                "Je peux apporter des éléments techniques supplémentaires.",
                "Dans notre contexte, cela implique plusieurs considérations...",
                "Excellente observation ! Permettez-moi d'ajouter..."
            ]
        
        import random
        return random.choice(responses)
    
    async def trigger_agent_reactions(self, primary_agent_id: str, primary_response: str) -> List[Dict]:
        """Déclenche les réactions des autres agents si approprié"""
        
        reactions = []
        
        # Déterminer si d'autres agents doivent réagir
        should_react = await self.should_trigger_reactions(primary_response)
        
        if not should_react:
            return reactions
            
        # Attendre un peu pour simuler une réaction naturelle
        await asyncio.sleep(1.5)
        
        # Sélectionner 1-2 agents pour réagir
        reacting_agents = self.select_reacting_agents(primary_agent_id)
        
        for agent_id in reacting_agents:
            agent = self.agents[agent_id]
            
            # Générer une réaction courte
            reaction = await self.generate_agent_reaction(agent, primary_response)
            
            if reaction:
                reactions.append({
                    "agent_id": agent_id,
                    "agent_name": agent.name,
                    "reaction": reaction,
                    "delay_ms": 1500 + (len(reactions) * 1000)  # Délai progressif
                })
                
                # Ajouter à l'historique
                reaction_entry = ConversationEntry(
                    speaker_id=agent_id,
                    speaker_name=agent.name,
                    message=reaction,
                    timestamp=datetime.now(),
                    is_user=False
                )
                self.conversation_history.append(reaction_entry)
        
        return reactions
    
    async def should_trigger_reactions(self, primary_response: str) -> bool:
        """Détermine si des réactions doivent être déclenchées"""
        
        # Règles pour déclencher des réactions
        triggers = [
            "?" in primary_response,  # Question posée
            len(primary_response) > 200,  # Réponse longue
            any(word in primary_response.lower() for word in ["mais", "cependant", "toutefois"]),
            datetime.now() - self.last_speaker_change > timedelta(seconds=30)  # Trop long sans interaction
        ]
        
        return any(triggers)
    
    def select_reacting_agents(self, exclude_agent_id: str) -> List[str]:
        """Sélectionne les agents qui vont réagir"""
        
        eligible_agents = [
            agent_id for agent_id in self.agents 
            if agent_id != exclude_agent_id
        ]
        
        if not eligible_agents:
            return []
            
        # Prioriser les agents qui ont moins parlé
        sorted_agents = sorted(
            eligible_agents,
            key=lambda x: self.interaction_count.get(x, 0)
        )
        
        # Sélectionner 1-2 agents
        import random
        num_reactions = min(random.randint(1, 2), len(sorted_agents))
        return sorted_agents[:num_reactions]
    
    async def generate_agent_reaction(self, agent: AgentPersonality, primary_response: str) -> str:
        """Génère une réaction courte d'un agent"""
        
        # Réactions courtes simulées
        if agent.interaction_style == InteractionStyle.MODERATOR:
            reactions = [
                "Excellent point ! Poursuivons sur cette lancée.",
                "C'est très pertinent. Qui souhaite rebondir ?",
                "Gardons ce rythme dynamique !",
            ]
        elif agent.interaction_style == InteractionStyle.CHALLENGER:
            reactions = [
                "J'aimerais creuser ce point davantage.",
                "Intéressant, mais qu'en est-il de...",
                "Permettez-moi une objection...",
            ]
        elif agent.interaction_style == InteractionStyle.EXPERT:
            reactions = [
                "Effectivement, et j'ajouterais que...",
                "C'est conforme aux meilleures pratiques.",
                "Un point technique important ici...",
            ]
        else:
            reactions = [
                "Tout à fait d'accord.",
                "C'est un bon point.",
                "Je prends note.",
            ]
        
        import random
        return random.choice(reactions)
    
    def build_agent_context(self, agent_id: str, user_message: str) -> str:
        """Construit le contexte pour un agent spécifique"""
        
        # Historique récent (5 derniers messages)
        recent_history = self.conversation_history[-5:] if self.conversation_history else []
        
        context_parts = []
        
        # Informations sur la simulation
        context_parts.append(f"SIMULATION: {self.config.exercise_id}")
        elapsed_time = (datetime.now() - self.session_start_time).seconds // 60
        context_parts.append(f"DURÉE ÉCOULÉE: {elapsed_time} minutes")
        
        # Autres participants
        agent = self.agents[agent_id]
        other_agents = [
            a.name for a in self.agents.values() 
            if a.agent_id != agent_id
        ]
        context_parts.append(f"AUTRES PARTICIPANTS: {', '.join(other_agents)}")
        
        # Rôle et style
        context_parts.append(f"VOTRE RÔLE: {agent.role}")
        context_parts.append(f"STYLE: {agent.interaction_style.value}")
        
        # Historique récent
        if recent_history:
            context_parts.append("\nHISTORIQUE RÉCENT:")
            for entry in recent_history:
                if entry.speaker_id != agent_id:  # Ne pas inclure ses propres messages
                    context_parts.append(f"- {entry.speaker_name}: {entry.message[:100]}...")
        
        return "\n".join(context_parts)
    
    def get_session_metrics(self) -> Dict[str, Any]:
        """Obtient les métriques de la session"""
        
        elapsed_time = (datetime.now() - self.session_start_time).total_seconds()
        
        return {
            "session_duration_seconds": elapsed_time,
            "total_interactions": sum(self.interaction_count.values()),
            "agent_participation": {
                agent_id: {
                    "name": self.agents[agent_id].name,
                    "interactions": count,
                    "speaking_time": self.speaking_times[agent_id],
                    "participation_rate": (count / max(sum(self.interaction_count.values()), 1)) * 100
                }
                for agent_id, count in self.interaction_count.items()
            },
            "current_speaker": self.current_speaker,
            "messages_count": len(self.conversation_history)
        }
    
    async def generate_welcome_message(self) -> str:
        """Génère le message de bienvenue pour la simulation"""
        
        # Trouver le modérateur ou le premier agent
        moderator = self.find_agent_by_style(InteractionStyle.MODERATOR)
        
        if moderator:
            agent_names = [a.name + f" ({a.role})" for a in self.agents.values()]
            welcome = f"""Bonjour et bienvenue dans cette simulation {self.config.exercise_id.replace('_', ' ')} !

Je suis {moderator.name}, votre {moderator.role}. 

Aujourd'hui, nous allons recréer une situation professionnelle réaliste avec plusieurs interlocuteurs :
{chr(10).join(['• ' + name for name in agent_names])}

Cette simulation vous permettra de :
✓ Pratiquer votre communication professionnelle
✓ Gérer des interactions multiples
✓ Développer votre confiance face à différents types d'interlocuteurs
✓ Recevoir des feedbacks personnalisés

Vous pouvez commencer quand vous le souhaitez. N'hésitez pas à poser des questions ou à exprimer vos idées !

À vous la parole ! 🎙️"""
            
            # Ajouter à l'historique
            welcome_entry = ConversationEntry(
                speaker_id=moderator.agent_id,
                speaker_name=moderator.name,
                message=welcome,
                timestamp=datetime.now(),
                is_user=False
            )
            self.conversation_history.append(welcome_entry)
            self.current_speaker = moderator.agent_id
            
            return welcome
        else:
            # Fallback si pas de modérateur
            return "Bienvenue dans la simulation ! Vous pouvez commencer à parler."
    
    async def close_session(self) -> Dict[str, Any]:
        """Ferme la session et retourne les métriques finales"""
        
        self.is_session_active = False
        
        # Message de clôture
        moderator = self.find_agent_by_style(InteractionStyle.MODERATOR)
        if moderator:
            closing_message = f"""Merci pour cette excellente simulation !

Vous avez participé pendant {(datetime.now() - self.session_start_time).seconds // 60} minutes.

Points forts observés :
✓ Communication claire et structurée
✓ Bonne gestion des interactions multiples
✓ Réactivité face aux questions

Continuez à pratiquer pour développer encore plus votre aisance !

À bientôt pour une nouvelle session ! 👋"""
            
            closing_entry = ConversationEntry(
                speaker_id=moderator.agent_id,
                speaker_name=moderator.name,
                message=closing_message,
                timestamp=datetime.now(),
                is_user=False
            )
            self.conversation_history.append(closing_entry)
        
        # Retourner les métriques finales
        return {
            "session_summary": self.get_session_metrics(),
            "conversation_transcript": [entry.to_dict() for entry in self.conversation_history],
            "recommendations": self.generate_recommendations()
        }
    
    def generate_recommendations(self) -> List[str]:
        """Génère des recommandations basées sur la session"""
        
        recommendations = []
        
        # Analyser la participation
        user_messages = [e for e in self.conversation_history if e.is_user]
        
        if len(user_messages) < 5:
            recommendations.append("Essayez de participer davantage lors de la prochaine session")
        
        if len(user_messages) > 15:
            recommendations.append("Excellente participation ! Continuez ainsi")
        
        # Analyser la longueur des messages
        avg_length = sum(len(e.message) for e in user_messages) / max(len(user_messages), 1)
        
        if avg_length < 50:
            recommendations.append("Développez davantage vos réponses pour plus d'impact")
        elif avg_length > 200:
            recommendations.append("Essayez d'être plus concis dans vos interventions")
        
        # Toujours ajouter des encouragements
        recommendations.append("Continuez à pratiquer régulièrement pour progresser")
        recommendations.append("N'hésitez pas à varier les types de simulations")
        
        return recommendations