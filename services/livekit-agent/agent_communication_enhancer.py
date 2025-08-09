"""
Module d'amélioration de la communication inter-agents
Corrige les problèmes de mutisme et améliore l'interactivité
"""
import asyncio
import logging
import time
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

from multi_agent_config import AgentPersonality, InteractionStyle

logger = logging.getLogger(__name__)


class CommunicationState(Enum):
    """États de communication possibles"""
    WAITING_USER = "waiting_user"
    AGENT_SPEAKING = "agent_speaking"
    WAITING_AGENT = "waiting_agent"
    SILENCE_DETECTED = "silence_detected"
    INTERVENTION_NEEDED = "intervention_needed"


@dataclass
class CommunicationMetrics:
    """Métriques de communication pour monitoring"""
    last_message_time: datetime
    silence_duration: float
    total_interactions: int
    agent_response_times: Dict[str, List[float]]
    intervention_count: int
    
    def update_response_time(self, agent_id: str, response_time: float):
        """Met à jour le temps de réponse d'un agent"""
        if agent_id not in self.agent_response_times:
            self.agent_response_times[agent_id] = []
        self.agent_response_times[agent_id].append(response_time)
        
        # Garder seulement les 10 dernières mesures
        if len(self.agent_response_times[agent_id]) > 10:
            self.agent_response_times[agent_id] = self.agent_response_times[agent_id][-10:]


class AgentCommunicationEnhancer:
    """Améliore la communication entre agents avec relances automatiques"""
    
    def __init__(self, agents: Dict[str, AgentPersonality]):
        self.agents = agents
        self.state = CommunicationState.WAITING_USER
        self.metrics = CommunicationMetrics(
            last_message_time=datetime.now(),
            silence_duration=0.0,
            total_interactions=0,
            agent_response_times={},
            intervention_count=0
        )
        
        # Configuration des timeouts
        self.SILENCE_THRESHOLD = 10.0  # secondes
        self.AGENT_TIMEOUT = 8.0  # secondes
        self.MAX_SILENCE_BEFORE_INTERVENTION = 15.0  # secondes
        
        # Phrases de relance par style d'agent
        self.relance_phrases = self._initialize_relance_phrases()
        
        logger.info(f"🔧 CommunicationEnhancer initialisé avec {len(agents)} agents")
    
    def _initialize_relance_phrases(self) -> Dict[InteractionStyle, List[str]]:
        """Initialise les phrases de relance par style d'agent"""
        return {
            InteractionStyle.MODERATOR: [
                "Excellente question ! Prenez votre temps pour répondre.",
                "Nous vous écoutons, continuez votre présentation.",
                "Très intéressant ! Développez ce point s'il vous plaît.",
                "Parfait ! Qui souhaite réagir à cette intervention ?",
                "Nous avons encore du temps, n'hésitez pas à détailler."
            ],
            
            InteractionStyle.CHALLENGER: [
                "Permettez-moi de creuser ce point...",
                "C'est intéressant, mais comment expliquez-vous que...",
                "Avez-vous des exemples concrets à nous donner ?",
                "Cette position soulève une question importante...",
                "Je souhaiterais challenger cet argument..."
            ],
            
            InteractionStyle.EXPERT: [
                "Pour bien comprendre le contexte...",
                "Mon expérience dans ce domaine me montre que...",
                "Il faut également considérer l'aspect...",
                "Historiquement, nous avons observé que...",
                "Permettez-moi d'apporter une perspective technique..."
            ],
            
            InteractionStyle.INTERVIEWER: [
                "Pouvez-vous me donner un exemple concret ?",
                "Comment gérez-vous ce type de situation ?",
                "Parlez-moi de votre expérience avec...",
                "Qu'est-ce qui vous motive dans ce domaine ?",
                "Décrivez-moi votre approche pour..."
            ],
            
            InteractionStyle.SUPPORTIVE: [
                "D'un point de vue technique, il faut noter que...",
                "Pour compléter cette information...",
                "Je peux confirmer que dans notre expérience...",
                "Effectivement, et il faut aussi considérer...",
                "C'est un point important, j'ajouterais que..."
            ]
        }
    
    async def monitor_communication(self) -> Optional[str]:
        """
        Surveille la communication et génère des interventions si nécessaire
        
        Returns:
            Optional[str]: Message d'intervention si nécessaire
        """
        current_time = datetime.now()
        silence_duration = (current_time - self.metrics.last_message_time).total_seconds()
        self.metrics.silence_duration = silence_duration
        
        # Détection de silence prolongé
        if silence_duration > self.SILENCE_THRESHOLD:
            logger.warning(f"⚠️ Silence détecté: {silence_duration:.1f}s")
            self.state = CommunicationState.SILENCE_DETECTED
            
            if silence_duration > self.MAX_SILENCE_BEFORE_INTERVENTION:
                logger.info("🚨 Intervention automatique nécessaire")
                return await self._generate_intervention()
        
        return None
    
    async def _generate_intervention(self) -> str:
        """Génère une intervention automatique pour relancer la conversation"""
        self.metrics.intervention_count += 1
        
        # Trouver le modérateur ou un agent approprié
        moderator = self._find_agent_by_style(InteractionStyle.MODERATOR)
        if moderator:
            agent = moderator
            style = InteractionStyle.MODERATOR
        else:
            # Fallback vers le premier agent disponible
            agent = list(self.agents.values())[0]
            style = agent.interaction_style
        
        # Sélectionner une phrase de relance appropriée
        phrases = self.relance_phrases.get(style, self.relance_phrases[InteractionStyle.MODERATOR])
        phrase = phrases[self.metrics.intervention_count % len(phrases)]
        
        intervention = f"[{agent.name}]: {phrase}"
        
        logger.info(f"🎯 Intervention générée: {agent.name} ({style.value})")
        logger.info(f"   Message: {phrase}")
        
        # Mettre à jour les métriques
        self.metrics.last_message_time = datetime.now()
        self.state = CommunicationState.AGENT_SPEAKING
        
        return intervention
    
    def _find_agent_by_style(self, style: InteractionStyle) -> Optional[AgentPersonality]:
        """Trouve un agent par son style d'interaction"""
        for agent in self.agents.values():
            if agent.interaction_style == style:
                return agent
        return None
    
    async def process_user_message(self, message: str) -> Dict[str, Any]:
        """
        Traite un message utilisateur et détermine la réponse appropriée
        
        Args:
            message: Message de l'utilisateur
            
        Returns:
            Dict contenant les informations de traitement
        """
        self.metrics.last_message_time = datetime.now()
        self.metrics.total_interactions += 1
        self.state = CommunicationState.WAITING_AGENT
        
        logger.info(f"👤 Message utilisateur traité: {message[:50]}...")
        
        # Analyser le message pour déterminer qui doit répondre
        responding_agent = await self._determine_responding_agent(message)
        
        # Générer des réactions secondaires potentielles
        secondary_agents = await self._determine_secondary_reactions(message, responding_agent)
        
        return {
            'primary_responder': responding_agent,
            'secondary_responders': secondary_agents,
            'message_analysis': self._analyze_message_intent(message),
            'communication_state': self.state.value,
            'metrics': {
                'total_interactions': self.metrics.total_interactions,
                'silence_duration': self.metrics.silence_duration,
                'intervention_count': self.metrics.intervention_count
            }
        }
    
    async def _determine_responding_agent(self, message: str) -> str:
        """Détermine intelligemment quel agent doit répondre"""
        message_lower = message.lower()

        # 1. Détection de nom d'agent
        for agent_id, agent in self.agents.items():
            if agent.name.lower() in message_lower:
                logger.info(f"🎯 Nom d'agent '{agent.name}' détecté → {agent.name}")
                return agent.agent_id
        
        # 2. Mots-clés pour orienter vers des agents spécifiques
        keywords_mapping = {
            'technique': InteractionStyle.EXPERT,
            'techniquement': InteractionStyle.EXPERT,
            'comment': InteractionStyle.CHALLENGER,
            'pourquoi': InteractionStyle.CHALLENGER,
            'expérience': InteractionStyle.INTERVIEWER,
            'exemple': InteractionStyle.INTERVIEWER,
            'budget': InteractionStyle.EXPERT,
            'coût': InteractionStyle.EXPERT,
            'prix': InteractionStyle.CHALLENGER,
        }
        
        for keyword, style in keywords_mapping.items():
            if keyword in message_lower:
                agent = self._find_agent_by_style(style)
                if agent:
                    logger.info(f"🎯 Mot-clé '{keyword}' détecté → {agent.name} ({style.value})")
                    return agent.agent_id
        
        # 3. Par défaut, le modérateur répond
        moderator = self._find_agent_by_style(InteractionStyle.MODERATOR)
        if moderator:
            return moderator.agent_id
        
        # 4. Fallback vers le premier agent
        return list(self.agents.keys())[0]
    
    async def _determine_secondary_reactions(self, message: str, primary_agent_id: str) -> List[str]:
        """Détermine quels autres agents pourraient réagir"""
        secondary_agents = []
        
        # Les autres agents peuvent réagir selon le contexte
        for agent_id, agent in self.agents.items():
            if agent_id != primary_agent_id:
                # Probabilité de réaction selon le style
                should_react = False
                
                if agent.interaction_style == InteractionStyle.CHALLENGER:
                    # Les challengeurs réagissent souvent
                    should_react = len(message) > 50  # Messages substantiels
                elif agent.interaction_style == InteractionStyle.EXPERT:
                    # Les experts réagissent aux sujets techniques
                    should_react = any(word in message.lower() for word in 
                                     ['technique', 'solution', 'approche', 'méthode'])
                elif agent.interaction_style == InteractionStyle.SUPPORTIVE:
                    # Les supportifs complètent les informations
                    should_react = len(message) > 30
                
                if should_react:
                    secondary_agents.append(agent_id)
        
        return secondary_agents[:2]  # Maximum 2 réactions secondaires
    
    def _analyze_message_intent(self, message: str) -> Dict[str, Any]:
        """Analyse l'intention du message utilisateur"""
        message_lower = message.lower()
        
        intent_analysis = {
            'is_question': '?' in message,
            'is_technical': any(word in message_lower for word in 
                              ['technique', 'code', 'architecture', 'système']),
            'is_personal': any(word in message_lower for word in 
                             ['je', 'mon', 'ma', 'mes', 'moi']),
            'is_explanation': any(word in message_lower for word in 
                                ['parce que', 'car', 'donc', 'ainsi']),
            'length_category': 'short' if len(message) < 30 else 'medium' if len(message) < 100 else 'long',
            'estimated_complexity': 'simple' if len(message.split()) < 10 else 'complex'
        }
        
        return intent_analysis
    
    async def record_agent_response(self, agent_id: str, response_time: float):
        """Enregistre le temps de réponse d'un agent"""
        self.metrics.update_response_time(agent_id, response_time)
        self.metrics.last_message_time = datetime.now()
        self.state = CommunicationState.WAITING_USER
        
        logger.debug(f"📊 Temps de réponse {agent_id}: {response_time:.2f}s")
    
    def get_communication_health(self) -> Dict[str, Any]:
        """Retourne l'état de santé de la communication"""
        avg_response_times = {}
        for agent_id, times in self.metrics.agent_response_times.items():
            if times:
                avg_response_times[agent_id] = sum(times) / len(times)
        
        return {
            'state': self.state.value,
            'silence_duration': self.metrics.silence_duration,
            'total_interactions': self.metrics.total_interactions,
            'intervention_count': self.metrics.intervention_count,
            'average_response_times': avg_response_times,
            'health_score': self._calculate_health_score(),
            'recommendations': self._generate_recommendations()
        }
    
    def _calculate_health_score(self) -> float:
        """Calcule un score de santé de la communication (0-100)"""
        score = 100.0
        
        # Pénalité pour silence prolongé
        if self.metrics.silence_duration > self.SILENCE_THRESHOLD:
            score -= min(50, self.metrics.silence_duration * 2)
        
        # Pénalité pour trop d'interventions
        if self.metrics.intervention_count > 3:
            score -= (self.metrics.intervention_count - 3) * 10
        
        # Bonus pour interactions fréquentes
        if self.metrics.total_interactions > 5:
            score += min(20, self.metrics.total_interactions * 2)
        
        return max(0, min(100, score))
    
    def _generate_recommendations(self) -> List[str]:
        """Génère des recommandations pour améliorer la communication"""
        recommendations = []
        
        if self.metrics.silence_duration > self.SILENCE_THRESHOLD:
            recommendations.append("Réduire les temps de silence avec des relances plus fréquentes")
        
        if self.metrics.intervention_count > 5:
            recommendations.append("Améliorer la réactivité des agents pour réduire les interventions")
        
        if self.metrics.total_interactions < 3:
            recommendations.append("Encourager plus d'interactions avec des questions ouvertes")
        
        # Analyser les temps de réponse
        for agent_id, times in self.metrics.agent_response_times.items():
            if times and sum(times) / len(times) > self.AGENT_TIMEOUT:
                agent_name = self.agents[agent_id].name if agent_id in self.agents else agent_id
                recommendations.append(f"Optimiser le temps de réponse de {agent_name}")
        
        return recommendations


# Fonction utilitaire pour l'intégration
def create_communication_enhancer(agents: Dict[str, AgentPersonality]) -> AgentCommunicationEnhancer:
    """Crée un enhancer de communication pour les agents donnés"""
    return AgentCommunicationEnhancer(agents)