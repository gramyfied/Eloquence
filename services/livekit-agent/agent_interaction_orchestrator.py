"""
Orchestrateur d'Interactions pour les Agents IA Eloquence
Force les interactions et gère les tours de parole pour des conversations fluides
"""
import asyncio
import logging
from typing import Dict, List, Any, Optional

from multi_agent_config import AgentPersonality, InteractionStyle
from exercise_router import ExerciseRouter, ExerciseType
from agent_communication_enhancer import AgentCommunicationEnhancer

logger = logging.getLogger(__name__)


class AgentInteractionOrchestrator:
    """Orchestre les interactions entre agents pour garantir la fluidité"""
    
    def __init__(self, agents: Dict[str, AgentPersonality], enhancer: AgentCommunicationEnhancer):
        self.agents = agents
        self.enhancer = enhancer
        self.turn_queue: List[str] = []
        self.current_speaker: Optional[str] = None
        self.last_interaction_time = asyncio.get_event_loop().time()
        
        # Configuration
        self.MAX_SILENCE_STREAK = 2  # Tours max sans parler pour un agent
        self.agent_silence_streak: Dict[str, int] = {agent_id: 0 for agent_id in agents}
        
        logger.info("🎼 Orchestrateur d'interactions initialisé")
    
    async def orchestrate_interaction(self, user_message: str, exercise_id: str) -> Dict[str, Any]:
        """
        Orchestre une interaction complète à partir d'un message utilisateur
        
        Args:
            user_message: Le message de l'utilisateur
            exercise_id: L'ID de l'exercice en cours
            
        Returns:
            Un dictionnaire contenant les actions à prendre
        """
        logger.info(f"🎶 Orchestration pour l'exercice '{exercise_id}'")
        
        # 1. Analyser le message et déterminer le répondeur principal
        analysis = await self.enhancer.process_user_message(user_message)
        primary_responder = analysis['primary_responder']
        
        # 2. Mettre à jour la file d'attente des tours de parole
        self._update_turn_queue(primary_responder, exercise_id)
        
        # 3. Vérifier et forcer les interactions si nécessaire
        forced_interactions = await self._check_and_force_interactions()
        
        # 4. Préparer la réponse de l'orchestrateur
        orchestration_plan = {
            'primary_agent_id': self.current_speaker,
            'secondary_agent_ids': analysis['secondary_responders'],
            'forced_interactions': forced_interactions,
            'turn_queue': self.turn_queue,
            'message_analysis': analysis['message_analysis']
        }
        
        logger.info(f"🎹 Plan d'orchestration:")
        logger.info(f"   - Agent principal: {self.current_speaker}")
        logger.info(f"   - Agents secondaires: {analysis['secondary_responders']}")
        logger.info(f"   - Interactions forcées: {len(forced_interactions)}")
        
        self.last_interaction_time = asyncio.get_event_loop().time()
        return orchestration_plan
        
    def _update_turn_queue(self, primary_responder: str, exercise_id: str):
        """Met à jour la file d'attente des tours de parole"""
        
        # Initialiser la file d'attente si elle est vide
        if not self.turn_queue:
            self.turn_queue = self._get_default_turn_order(exercise_id)
        
        # Placer le répondeur principal en tête de file
        if primary_responder in self.turn_queue:
            self.turn_queue.remove(primary_responder)
        self.turn_queue.insert(0, primary_responder)
        
        self.current_speaker = self.turn_queue.pop(0)
        self.turn_queue.append(self.current_speaker) # Le remet à la fin
        
        # Réinitialiser le compteur de silence pour l'agent qui parle
        self.agent_silence_streak[self.current_speaker] = 0
        
        # Incrémenter pour les autres
        for agent_id in self.agents:
            if agent_id != self.current_speaker:
                self.agent_silence_streak[agent_id] += 1
    
    def _get_default_turn_order(self, exercise_id: str) -> List[str]:
        """Retourne l'ordre de parole par défaut pour un exercice"""
        # TODO: Implémenter une logique plus fine basée sur les configs d'exercice
        
        # Simple ordre basé sur les rôles
        order = []
        moderator = self._find_agent_by_style(InteractionStyle.MODERATOR)
        challenger = self._find_agent_by_style(InteractionStyle.CHALLENGER)
        expert = self._find_agent_by_style(InteractionStyle.EXPERT)
        
        if moderator: order.append(moderator.agent_id)
        if challenger: order.append(challenger.agent_id)
        if expert: order.append(expert.agent_id)
        
        # Ajouter les agents restants
        for agent_id in self.agents:
            if agent_id not in order:
                order.append(agent_id)
                
        return order
        
    async def _check_and_force_interactions(self) -> List[Dict[str, str]]:
        """Vérifie si des agents sont silencieux et force une interaction"""
        forced_interactions = []
        
        for agent_id, streak in self.agent_silence_streak.items():
            if streak >= self.MAX_SILENCE_STREAK:
                logger.warning(f"🚨 Agent {agent_id} silencieux depuis {streak} tours. Forçage.")
                
                agent_to_force = self.agents[agent_id]
                
                # Générer une phrase de relance spécifique
                phrase = self._generate_force_phrase(agent_to_force)
                
                forced_interactions.append({
                    'agent_id': agent_id,
                    'message': f"[{agent_to_force.name}]: {phrase}"
                })
                
                # Réinitialiser son compteur
                self.agent_silence_streak[agent_id] = 0
        
        return forced_interactions
        
    def _generate_force_phrase(self, agent: AgentPersonality) -> str:
        """Génère une phrase pour forcer un agent à parler"""
        phrases = {
            InteractionStyle.CHALLENGER: "Je ne suis pas tout à fait d'accord, permettez-moi d'intervenir...",
            InteractionStyle.EXPERT: "D'un point de vue technique, il est important de préciser que...",
            InteractionStyle.SUPPORTIVE: "Pour compléter ce qui a été dit, j'ajouterais que...",
            InteractionStyle.MODERATOR: "Faisons un rapide tour de table. Votre avis sur ce point ?",
            InteractionStyle.INTERVIEWER: "C'est un bon point. Et comment cela s'applique-t-il à votre expérience ?"
        }
        
        return phrases.get(agent.interaction_style, "Qu'en pensez-vous ?")
        
    def _find_agent_by_style(self, style: InteractionStyle) -> Optional[AgentPersonality]:
        """Trouve un agent par son style d'interaction"""
        for agent in self.agents.values():
            if agent.interaction_style == style:
                return agent
        return None
        
    def get_orchestration_health(self) -> Dict[str, Any]:
        """Retourne l'état de santé de l'orchestration"""
        
        # Calculer la participation
        total_turns = sum(self.agent_silence_streak.values())
        participation = {
            agent_id: (total_turns - streak) / total_turns if total_turns > 0 else 0
            for agent_id, streak in self.agent_silence_streak.items()
        }
        
        # Équilibre de la participation (variance)
        if participation:
            mean_participation = sum(participation.values()) / len(participation)
            variance = sum([(p - mean_participation) ** 2 for p in participation.values()]) / len(participation)
            participation_balance = 1 - variance
        else:
            participation_balance = 0
            
        score = participation_balance * 100
        
        return {
            "health_score": max(0, min(100, score)),
            "participation_balance": participation_balance,
            "agent_participation": participation,
            "silence_streaks": self.agent_silence_streak
        }


# Fonction utilitaire pour l'intégration
def create_interaction_orchestrator(
    agents: Dict[str, AgentPersonality], 
    enhancer: AgentCommunicationEnhancer
) -> AgentInteractionOrchestrator:
    """Crée un orchestrateur d'interactions"""
    return AgentInteractionOrchestrator(agents, enhancer)