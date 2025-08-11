"""
Gestionnaire des interactions multi-agents pour Studio Situations Pro
"""
import asyncio
import random
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
        # Mémoire pour éviter les répétitions de Michel
        self._michel_last_phrase: Optional[str] = None
        # Mémoire de la dernière réaction par agent pour limiter les redites
        self._last_reaction_by_agent: Dict[str, str] = {}
    def get_michel_prompt(self, primary_response: str, conversation_count: int) -> str:
        """Prompts variés pour Michel selon le contexte.

        Remarque: self.config.subject peut ne pas exister dans la config actuelle.
        On fait un fallback sur exercise_id lisible.
        """
        # Sujet/fallback lisible
        subject = getattr(self.config, 'subject', self.config.exercise_id.replace('_', ' '))

        # Première intervention : se présenter
        if conversation_count == 0:
            return (
                f"Michel: Bonjour et bienvenue dans notre débat ! Je suis Michel Dubois et nous allons "
                f"explorer ensemble {subject}. Commençons par vous écouter."
            )

        # Interventions suivantes : formules variées
        formules_transition = [
            "Michel: Très intéressant ! Sarah, votre point de vue de journaliste ?",
            "Michel: Creusons ce point. Marcus, qu'en dit l'expert ?",
            "Michel: Permettez-moi de relancer le débat...",
            "Michel: Voilà qui mérite d'être approfondi !",
            "Michel: Excellent ! Continuons sur cette lancée...",
            "Michel: C'est exactement le type de réflexion que nous cherchons !",
            "Michel: Passionnant ! Et vous, que répondez-vous à cela ?",
            "Michel: Voilà qui va faire réagir nos invités !",
            "Michel: On touche là un point crucial...",
            "Michel: Cette perspective ouvre de nouvelles questions...",
        ]

        # Sollicitations utilisateur
        formules_sollicitation = [
            "Michel: Et vous, qu'en pensez-vous ? Votre avis nous intéresse !",
            "Michel: Nous aimerions connaître votre position sur ce point...",
            "Michel: Vous qui nous écoutez, quelle est votre réaction ?",
            "Michel: Donnez-nous votre point de vue, c'est important !",
            "Michel: Votre expérience peut enrichir ce débat...",
        ]

        # Relances contradictoires
        formules_contradiction = [
            "Michel: Attendez, n'y a-t-il pas une contradiction ici ?",
            "Michel: Permettez-moi de jouer l'avocat du diable...",
            "Michel: Mais certains pourraient objecter que...",
            "Michel: N'est-ce pas un peu optimiste ?",
            "Michel: Cette vision ne fait-elle pas l'impasse sur...",
        ]

        lower = primary_response.lower() if primary_response else ""
        if primary_response and ("?" in primary_response or "pensez" in lower):
            pool = formules_sollicitation
        elif any(word in lower for word in ["toujours", "jamais", "certain", "évident"]):
            pool = formules_contradiction
        else:
            pool = formules_transition

        # Éviter la répétition immédiate
        if self._michel_last_phrase in pool and len(pool) > 1:
            pool = [p for p in pool if p != self._michel_last_phrase]
        choice = random.choice(pool)
        self._michel_last_phrase = choice
        return choice

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
        
        # Déclencher les réactions des autres agents si nécessaire (version parallèle)
        secondary_responses = await self.trigger_agent_reactions_parallel(
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

        # Simuler le temps de réflexion (réduit pour plus de réactivité)
        await asyncio.sleep(0.2)

        # Gestion spécifique Michel (modérateur) pour éviter la répétition
        if agent.interaction_style == InteractionStyle.MODERATOR and agent.name.lower().startswith("michel"):
            conversation_count = len([e for e in self.conversation_history if e.speaker_id == agent_id])
            response = self.get_michel_prompt(user_message, conversation_count)
            logger.info(f"🎭 Michel varie ses formules (conversation_count: {conversation_count})")
        else:
            # Générer une réponse contextuelle basée sur la personnalité
            # (En production, ceci appellerait le LLM)
            raw = await self.simulate_agent_response(agent, context, user_message)
            response = self._sanitize_generation(agent, raw, user_message)
        
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
        """Génère une vraie réponse d'agent via LLM optimisé avec sa personnalité"""
        
        try:
            # Importer l'optimiseur LLM
            from llm_optimizer import llm_optimizer
            
            # Construire le prompt avec la personnalité complète de l'agent
            first_name = agent.name.split()[0]
            system_prompt = f"""Tu es {agent.name}, {agent.role}.

PERSONNALITÉ:
{agent.personality_traits}

RÔLE:
{agent.system_prompt}

STYLE DE COMMUNICATION ({agent.interaction_style.value}):
{self._get_style_instructions(agent.interaction_style)}

CONTEXTE DE LA CONVERSATION:
{context}

AUTRES PARTICIPANTS:
{', '.join([a.name + ' (' + a.role + ')' for a in self.agents.values() if a.agent_id != agent.agent_id])}

 INSTRUCTIONS:
- Réponds TOUJOURS en français
- Commence ta phrase par "{first_name}:" (sans te présenter)
- Reste dans ton personnage et ton style
- Réponds de manière concise (2-4 phrases, parfois 1 seule quand c'est une interjection)
- Adapte ton ton selon ton rôle ({agent.role})
- Si tu es modérateur, dirige la conversation
- Si tu es expert, apporte des détails techniques
- Si tu es challenger, pose des questions critiques
- NE PARAPHRASE PAS le message précédent: ajoute au moins une idée NOUVELLE (exemple, précision, nuance).
- Si tu n'es pas d'accord, coupe brièvement la parole avec une courte interjection avant d'expliquer (ex: "Attends, pas d'accord sur...")
- Si tu es challenger (Sarah), adopte une posture affirmée de contradicteur constructif.
- Si tu es expert (Marcus), reste neutre, factuel, clarifie et précise, sans t'auto-interviewer.
"""

            # Messages pour l'optimiseur
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ]
            
            # Déterminer la complexité et le type de tâche
            complexity = {
                'num_agents': len(self.agents),
                'context_length': len(context),
                'interaction_depth': len(self.conversation_history)
            }
            
            # Type de tâche basé sur le style d'interaction
            task_type = 'multi_agent_orchestration'
            if agent.interaction_style == InteractionStyle.MODERATOR:
                task_type = 'debate_moderation'
            elif agent.interaction_style == InteractionStyle.EXPERT:
                task_type = 'technical_explanation'
            elif agent.interaction_style == InteractionStyle.CHALLENGER:
                task_type = 'complex_reasoning'
            
            # Utiliser l'optimiseur LLM avec cache et sélection intelligente
            result = await llm_optimizer.get_optimized_response(
                messages=messages,
                task_type=task_type,
                complexity=complexity,
                use_cache=True,
                cache_ttl=600  # Cache de 10 minutes pour les réponses d'agents
            )
            
            generated_response = result['response']
            logger.info(f"✅ Réponse LLM optimisée pour {agent.name} (modèle: {result['model']}, cache: {result['cached']})")
            
            return generated_response
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse LLM pour {agent.name}: {e}")
            # Fallback avec une réponse contextuelle
            return f"Je suis {agent.name}, {agent.role}. {self._get_fallback_response(agent, user_message)}"
    
    def _get_style_instructions(self, style: InteractionStyle) -> str:
        """Retourne les instructions de style pour chaque type d'interaction"""
        styles = {
            InteractionStyle.MODERATOR: """
                - Dirige la conversation avec autorité bienveillante
                - Distribue la parole équitablement
                - Reformule et synthétise les points clés
                - Pose des questions de relance
                - Maintiens un rythme dynamique""",
            InteractionStyle.CHALLENGER: """
                - Pose des questions critiques et pointues
                - Challenge les idées avec respect
                - Demande des preuves et exemples concrets
                - Identifie les failles dans l'argumentation
                - Pousse à la réflexion profonde""",
            InteractionStyle.EXPERT: """
                - Apporte une expertise technique approfondie
                - Cite des exemples et bonnes pratiques
                - Explique les concepts complexes simplement
                - Donne des conseils pratiques
                - Partage ton expérience du terrain""",
            InteractionStyle.SUPPORTIVE: """
                - Soutiens et encourage les idées
                - Complète avec des informations utiles
                - Valorise les points positifs
                - Aide à clarifier les concepts
                - Crée une atmosphère collaborative""",
            InteractionStyle.INTERVIEWER: """
                - Pose des questions ouvertes et engageantes
                - Creuse les motivations et expériences
                - Guide vers l'introspection
                - Cherche des exemples concrets
                - Évalue les compétences avec bienveillance"""
        }
        return styles.get(style, "Communique de manière professionnelle et claire")
    
    def _get_fallback_response(self, agent: AgentPersonality, user_message: str) -> str:
        """Génère une réponse de fallback contextuelle"""
        if agent.interaction_style == InteractionStyle.MODERATOR:
            return f"Excellente intervention concernant {user_message[:30]}... Continuons sur cette voie."
        elif agent.interaction_style == InteractionStyle.CHALLENGER:
            return f"J'aimerais approfondir ce point sur {user_message[:30]}..."
        elif agent.interaction_style == InteractionStyle.EXPERT:
            return f"D'un point de vue technique, {user_message[:30]}... mérite analyse."
        else:
            return "Je prends note de votre point. Continuons."
    
    async def trigger_agent_reactions_parallel(self, primary_agent_id: str, primary_response: str) -> List[Dict]:
        """Génération parallèle des réactions pour plus de rapidité"""

        reactions: List[Dict] = []

        # Vérifier si des réactions sont nécessaires
        should_react = await self.should_trigger_reactions_smart(primary_response)

        # Dynamiser: si le modérateur parle, forcer au moins une réaction
        primary_agent = self.agents.get(primary_agent_id)
        if not should_react and primary_agent and primary_agent.interaction_style == InteractionStyle.MODERATOR:
            logger.info("🎯 Forçage: au moins une réaction après l'intervention du modérateur")
            should_react = True

        if not should_react:
            logger.info("🤷 Aucune réaction déclenchée")
            return reactions

        # Sélectionner les agents réactifs
        reacting_agents = self.select_reacting_agents(primary_agent_id, primary_response)
        if not reacting_agents:
            # Fallback: privilégier challenger puis expert
            fallback_list = []
            challenger = self.find_agent_by_style(InteractionStyle.CHALLENGER)
            expert = self.find_agent_by_style(InteractionStyle.EXPERT)
            if challenger and challenger.agent_id != primary_agent_id:
                fallback_list.append(challenger.agent_id)
            if expert and expert.agent_id != primary_agent_id:
                fallback_list.append(expert.agent_id)
            if not fallback_list:
                fallback_list = [aid for aid in self.agents if aid != primary_agent_id][:1]
            reacting_agents = fallback_list
            if not reacting_agents:
                return reactions

        logger.info(
            f"🎭 {len(reacting_agents)} agents vont réagir: "
            f"{[self.agents[aid].name for aid in reacting_agents]}"
        )

        # Générer toutes les réactions EN PARALLÈLE (avec micro-jitter + priorité mention)
        start_parallel = datetime.now()
        tasks = []
        for idx, agent_id in enumerate(reacting_agents):
            agent = self.agents[agent_id]
            # Petites micro-pauses échelonnées pour désynchroniser légèrement les LLM
            async def _one(agent_local: AgentPersonality):
                await asyncio.sleep(0.05 * (idx + 1))
                return await self.generate_agent_reaction_with_retry(agent_local, primary_response)

            task = _one(agent)
            tasks.append(task)

        # Attendre toutes les réactions (max 3 secondes)
        try:
            reactions_results = await asyncio.wait_for(
                asyncio.gather(*tasks, return_exceptions=True),
                timeout=3.0,
            )
        except asyncio.TimeoutError:
            logger.warning("⚠️ Timeout sur génération des réactions")
            reactions_results = ["Timeout"] * len(tasks)

        # Traiter les résultats
        for i, reaction in enumerate(reactions_results):
            agent_id = reacting_agents[i]
            agent = self.agents[agent_id]

            if isinstance(reaction, Exception) or reaction == "Timeout" or not reaction:
                logger.warning(f"⚠️ Réaction échouée pour {agent.name}")
                reaction = f"{agent.name.split()[0]}: C'est un point intéressant..."
            else:
                # Anti-écho: si la réaction répète trop la réponse principale, la raccourcir
                if primary_response and reaction:
                    pr = primary_response.strip().lower()
                    rx = reaction.strip().lower()
                    if rx.startswith(pr[:80]):
                        reaction = f"{agent.name.split()[0]}: Je propose une nuance…"

            # Éviter de répéter exactement la dernière réaction de cet agent
            last_reac = self._last_reaction_by_agent.get(agent_id, "")
            if reaction.strip().lower() == last_reac.strip().lower():
                reaction = f"{agent.name.split()[0]}: Pour compléter, j'ajouterais un autre angle."

            reactions.append({
                "agent_id": agent_id,
                "agent_name": agent.name,
                "reaction": reaction,
                # Délais plus courts pour plus de réactivité et permettre des coupes de parole
                "delay_ms": 120 + (i * 300),
            })

            # Ajouter à l'historique
            reaction_entry = ConversationEntry(
                speaker_id=agent_id,
                speaker_name=agent.name,
                message=reaction,
                timestamp=datetime.now(),
                is_user=False,
            )
            self.conversation_history.append(reaction_entry)
            self._last_reaction_by_agent[agent_id] = reaction

        elapsed = (datetime.now() - start_parallel).total_seconds()
        logger.info(f"✅ {len(reactions)} réactions générées en parallèle en {elapsed:.1f}s")
        return reactions

    async def generate_agent_reaction_with_retry(self, agent: AgentPersonality, primary_response: str) -> str:
        """Génération de réaction avec retry automatique"""

        for attempt in range(2):
            try:
                return await self.generate_agent_reaction_smart(agent, primary_response)
            except Exception as e:
                logger.warning(f"Tentative {attempt+1} échouée pour {agent.name}: {e}")
                if attempt == 0:
                    await asyncio.sleep(0.1)

        # Fallback final
        return f"{agent.name.split()[0]}: Je prends note de ce point."
    
    async def should_trigger_reactions_smart(self, primary_response: str) -> bool:
        """Triggers intelligents pour débat naturel (priorité aux mentions explicites)."""

        # 1) Mentions directes → priorité absolue
        agent_mentions = self._detect_agent_mentions(primary_response)
        if agent_mentions:
            logger.info(f"🎯 Mention directe détectée: {agent_mentions}")
            return True

        # 2) Laisser s'installer: pas de réactions très tôt
        if len(self.conversation_history) < 3:
            return False

        # 3) Éviter l'emballement: deux derniers messages IA → pause
        recent_last_two = [e for e in self.conversation_history[-2:] if not e.is_user]
        if len(recent_last_two) == 2:
            logger.info("🔇 Pause: deux messages IA consécutifs")
            return False

        # Triggers basés sur le contenu (sélectifs)
        content_triggers = [
            self._contains_controversial_statement(primary_response),
            self._contains_direct_question(primary_response),
            self._user_needs_help(primary_response),
            self._topic_needs_expert_input(primary_response),
        ]

        # Triggers temporels (moins fréquents)
        time_triggers = [
            self._user_silent_too_long(),  # 45 secondes
            self._agent_monopolizes_conversation(),
        ]

        content_score = sum(1 for t in content_triggers if t)
        time_score = sum(1 for t in time_triggers if t)

        should_react = content_score >= 1 or time_score >= 1
        logger.info(
            f"🤔 Should trigger reactions? {should_react} (content: {content_score}, time: {time_score})"
        )
        return should_react

    def _contains_controversial_statement(self, text: str) -> bool:
        """Détecte les affirmations controversées qui méritent réaction"""
        if not text:
            return False
        controversial_indicators = [
            "jamais", "toujours", "impossible", "évident", "certain",
            "faux", "erreur", "problème majeur", "catastrophe", "révolution",
        ]
        lower = text.lower()
        return any(word in lower for word in controversial_indicators)

    def _contains_direct_question(self, text: str) -> bool:
        """Détecte les vraies questions (pas les rhétoriques)"""
        if not text:
            return False
        lower = text.lower()
        return ("?" in text) and any(
            word in lower for word in [
                "comment", "pourquoi", "quand", "où", "qui", "que pensez", "votre avis"
            ]
        )

    def _user_silent_too_long(self) -> bool:
        """Utilisateur silencieux depuis 45 secondes"""
        last_user_message = None
        for entry in reversed(self.conversation_history):
            if entry.is_user:
                last_user_message = entry
                break

        if last_user_message:
            silence_duration = (datetime.now() - last_user_message.timestamp).seconds
            return silence_duration > 45

        return False

    def _user_needs_help(self, text: str) -> bool:
        """Heuristique simple: l'utilisateur demande de l'aide/clarification"""
        if not text:
            return False
        lower = text.lower()
        return any(
            phrase in lower
            for phrase in [
                "je ne comprends pas", "peux-tu expliquer", "peux vous expliquer",
                "expliquer", "comment faire", "aide-moi", "besoin d'aide",
            ]
        )

    def _topic_needs_expert_input(self, text: str) -> bool:
        """Heuristique: mots-clés techniques → inviter l'expert"""
        if not text:
            return False
        lower = text.lower()
        keywords = [
            "technique", "techniquement", "architecture", "implémentation",
            "algorithme", "données", "sécurité", "performance",
        ]
        return any(k in lower for k in keywords)

    def _agent_monopolizes_conversation(self) -> bool:
        """Vérifie si le même agent parle trop d'affilée"""
        last_non_user = [e for e in reversed(self.conversation_history) if not e.is_user][:3]
        if len(last_non_user) < 3:
            return False
        names = {e.speaker_id for e in last_non_user}
        return len(names) == 1
    
    def _detect_agent_mentions(self, text: str) -> List[str]:
        """Détecte les mentions explicites d'agents dans le texte (prénom, variantes, deux-points)."""
        mentioned_agents = []
        text_lower = text.lower()
        
        for agent_id, agent in self.agents.items():
            # Chercher le prénom de l'agent
            first_name = agent.name.split()[0].lower()
            full_name = agent.name.lower()
            
            # Patterns de distribution de parole
            patterns = [
                f"{first_name},",  # "Sarah, votre avis ?"
                f"{first_name} ?",  # "Et vous Sarah ?"
                f"{first_name}:",  # "Sarah: ..." (au cas où)
                f"à {first_name}",  # "Donnons la parole à Sarah"
                f"écoutons {first_name}",  # "Écoutons Sarah"
                f"{first_name} que",  # "Sarah que pensez-vous"
                f"{first_name} qu",  # "Sarah qu'en dites-vous"
                f"passons à {first_name}",  # "Passons à Sarah"
                f"{full_name}",  # nom complet (sécurité)
            ]
            
            for pattern in patterns:
                if pattern in text_lower:
                    mentioned_agents.append(agent_id)
                    logger.info(f"🎯 Agent {agent.name} mentionné avec pattern: '{pattern}'")
                    break
        
        return mentioned_agents
    
    def select_reacting_agents(self, primary_agent_id: str, primary_response: str) -> List[str]:
        """Sélectionne les agents qui vont réagir.
        - Si mention explicite d'un agent, il est prioritaire
        - Si le modérateur pose une question à X, forcer X à réagir (si disponible)
        - Sinon, styles complémentaires
        """
        
        # Agents disponibles (excluant l'agent principal)
        available_agents = [aid for aid in self.agents.keys() if aid != primary_agent_id]
        
        if not available_agents:
            return []
        
        # Détecter les mentions directes
        mentioned_agents = self._detect_agent_mentions(primary_response)
        
        # Gestion intelligente des mentions
        if mentioned_agents:
            # Prendre les agents mentionnés qui ne sont pas l'agent principal
            mentioned_others = [aid for aid in mentioned_agents if aid != primary_agent_id]
            
            if mentioned_others:
                # Des autres agents sont mentionnés → ils réagissent
                selected = mentioned_others[:2]
                logger.info(f"✅ Autres agents mentionnés sélectionnés: {[self.agents[aid].name for aid in selected]}")
                return selected
            else:
                # Seul l'agent principal est mentionné → les autres réagissent naturellement
                selected = available_agents[:2]
                logger.info(f"✅ Agent principal mentionné, autres réagissent: {[self.agents[aid].name for aid in selected]}")
                return selected

        # Mention directe simple d'un agent précis (ex: "Sarah:", "Sarah,")
        # Si le modérateur est primaire et qu'un autre agent est détecté, forcer sa présence
        primary_agent = self.agents[primary_agent_id]
        if primary_agent.interaction_style == InteractionStyle.MODERATOR and mentioned_agents:
            target = [aid for aid in mentioned_agents if aid != primary_agent_id]
            if target:
                # forcer le premier mentionné
                forced = target[0]
                others = [aid for aid in available_agents if aid != forced]
                return [forced] + (others[:1] if others else [])
        
        # Sinon, sélection normale avec priorité aux styles complémentaires
        selected: List[str] = []
        primary_agent = self.agents[primary_agent_id]
        
        # Prioriser les agents avec des styles complémentaires
        for agent_id in available_agents:
            agent = self.agents[agent_id]
            if agent.interaction_style != primary_agent.interaction_style:
                selected.append(agent_id)
                if len(selected) >= 2:
                    break
        
        # Si pas assez d'agents complémentaires, compléter avec les autres
        if len(selected) < 2:
            remaining = [aid for aid in available_agents if aid not in selected]
            selected.extend(remaining[: 2 - len(selected)])
        
        # Heuristique: forcer la présence du challenger (Sarah) sur sujets controversés ou questions directes
        if (self._contains_controversial_statement(primary_response) or self._contains_direct_question(primary_response)):
            challenger = self.find_agent_by_style(InteractionStyle.CHALLENGER)
            if challenger and challenger.agent_id not in selected and challenger.agent_id != primary_agent_id:
                if len(selected) >= 2:
                    selected[-1] = challenger.agent_id
                else:
                    selected.append(challenger.agent_id)

        logger.info(f"✅ Sélection complémentaire: {[self.agents[aid].name for aid in selected]}")
        return selected
    
    async def generate_agent_reaction(self, agent: AgentPersonality, primary_response: str) -> str:
        """Génère une vraie réaction d'agent via LLM optimisé"""
        # Gestion spécifique Michel (modérateur) pour variété rapide sans LLM
        if agent.interaction_style == InteractionStyle.MODERATOR and agent.name.lower().startswith("michel"):
            conversation_count = len([e for e in self.conversation_history if e.speaker_id == agent.agent_id])
            michel_text = self.get_michel_prompt(primary_response, conversation_count)
            logger.info(f"🎭 Michel varie ses formules (conversation_count: {conversation_count})")
            return michel_text

        try:
            from llm_optimizer import llm_optimizer
            
            # Prompt pour une réaction courte et contextuelle
            system_prompt = f"""Tu es {agent.name}, {agent.role}.
Style: {agent.interaction_style.value}

Un autre participant vient de dire: "{primary_response[:200]}"

Génère une RÉACTION NATURELLE et DYNAMIQUE (1 à 2 phrases max) qui:
- Reste dans ton personnage
- Montre que tu écoutes activement
- Prépare une transition ou relance
- Peut commencer par une interjection si tu n'es pas d'accord (ex: "Attends,")
- Commence par ton prénom

Exemples selon ton style:
- Modérateur: "Michel: Excellent point ! Qui souhaite compléter ?"
- Expert: "Marcus: J'ajouterais un détail technique important..."
- Challenger: "Sarah: Permettez-moi de nuancer ce point..."
"""

            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "Génère ta réaction courte."}
            ]

            # Ajouter un court contexte récent pour la mémoire
            recent_lines = []
            for entry in self.conversation_history[-3:]:
                role_label = "Utilisateur" if entry.is_user else entry.speaker_name
                recent_lines.append(f"- {role_label}: {entry.message[:120]}")
            recent_context = "\n".join(recent_lines) if recent_lines else "(aucun)"
            system_prompt += f"\nCONTEXTE RÉCENT:\n{recent_context}\n"
            # Réinjecter le prompt mis à jour dans les messages
            messages[0]['content'] = system_prompt

            # Choisir un type de tâche pertinent pour forcer un modèle plus intelligent
            if agent.interaction_style == InteractionStyle.EXPERT:
                task_type = 'technical_explanation'
            elif agent.interaction_style == InteractionStyle.CHALLENGER:
                task_type = 'complex_reasoning'
            elif agent.interaction_style == InteractionStyle.MODERATOR:
                task_type = 'debate_moderation'
            else:
                task_type = 'multi_agent_orchestration'

            complexity = {
                'num_agents': len(self.agents),
                'context_length': len(primary_response) + len(recent_context),
                'interaction_depth': len(self.conversation_history)
            }

            result = await llm_optimizer.get_optimized_response(
                messages=messages,
                task_type=task_type,
                complexity=complexity,
                use_cache=True,
                cache_ttl=300
            )
            
            logger.debug(f"✅ Réaction optimisée pour {agent.name} (modèle: {result['model']}, cache: {result['cached']})")
            return self._sanitize_generation(agent, result['response'], primary_response)
            
        except Exception as e:
            logger.error(f"❌ Erreur réaction LLM {agent.name}: {e}")
            return f"{agent.name.split()[0]}: Je prends note de ce point."

    async def generate_agent_reaction_smart(self, agent: AgentPersonality, primary_response: str) -> str:
        """Génère des réactions naturelles et contradictoires"""

        conversation_count = len(
            [e for e in self.conversation_history if e.speaker_id == agent.agent_id]
        )

        if agent.interaction_style == InteractionStyle.MODERATOR:
            # Michel : Animation variée
            return self.get_michel_prompt(primary_response, conversation_count)

        elif agent.interaction_style == InteractionStyle.CHALLENGER:
            # Sarah : Journaliste qui challenge
            prompt = f"""Tu es Sarah Johnson, journaliste investigatrice expérimentée.

Quelqu'un vient de dire: "{primary_response[:200]}"

STYLE: Journaliste qui QUESTIONNE et CHALLENGE (posture affirmée, contradictrice mais constructive). Tu ne poses pas de questions à Michel (modérateur), tu interpelles l'EXPERT ou l'Utilisateur.

Génère une RÉACTION COURTE (1-2 phrases) qui:
- QUESTIONNE un point précis
- DEMANDE des PREUVES ou EXEMPLES  
- SOULÈVE une OBJECTION ou LIMITE
- PEUT COUPER brièvement la parole si nécessaire (ex: "Attends,")
- RESTE PROFESSIONNELLE mais INCISIVE
- Commence par "Sarah:"

IMPORTANT: Varie tes formules, ne répète jamais "Je suis Sarah Johnson"."""

        elif agent.interaction_style == InteractionStyle.EXPERT:
            # Marcus : Expert qui nuance
            prompt = f"""Tu es Marcus Thompson, expert technique reconnu.

Quelqu'un vient de dire: "{primary_response[:200]}"

STYLE: Expert qui NUANCE et PRÉCISE (apporte la complexité technique). Ne pose pas de questions à toi-même, ne questionne pas le modérateur; adresse-toi à l'Utilisateur ou réponds au Challenger.

Génère une RÉACTION COURTE (1-2 phrases) qui:
- NUANCE ou CORRIGE techniquement
- AJOUTE une PRÉCISION importante
- MENTIONNE une LIMITATION ou COMPLEXITÉ
- APPORTE l'EXPERTISE technique
- Commence par "Marcus:"

IMPORTANT: Varie tes formules, ne répète jamais "Je suis Marcus Thompson"."""

        else:
            # Prompt générique
            prompt = f"""Tu es {agent.name}, {agent.role}.
        
Réagis naturellement à: "{primary_response[:200]}"

Génère une réaction courte et naturelle qui commence par "{agent.name.split()[0]}:"
Varie tes formules, ne te présente pas à chaque fois."""

        # Ajouter un court contexte des 3 derniers messages pour la mémoire
        recent_lines = []
        for entry in self.conversation_history[-3:]:
            role_label = "Utilisateur" if entry.is_user else entry.speaker_name
            recent_lines.append(f"- {role_label}: {entry.message[:120]}")
        recent_context = "\n".join(recent_lines) if recent_lines else "(aucun)"
        prompt += f"\n\nCONTEXTE RÉCENT:\n{recent_context}\n"

        # Appel LLM optimisé
        try:
            from llm_optimizer import llm_optimizer

            messages = [
                {"role": "system", "content": prompt},
                {"role": "user", "content": "Génère ta réaction naturelle."},
            ]

            # Sélectionner un type de tâche plus pertinent
            if agent.interaction_style == InteractionStyle.EXPERT:
                task_type = 'technical_explanation'
            elif agent.interaction_style == InteractionStyle.CHALLENGER:
                task_type = 'complex_reasoning'
            else:
                task_type = 'multi_agent_orchestration'

            result = await llm_optimizer.get_optimized_response(
                messages=messages,
                task_type=task_type,
                complexity={'num_agents': len(self.agents), 'context_length': len(primary_response) + len(recent_context), 'interaction_depth': len(self.conversation_history)},
                use_cache=True,
                cache_ttl=300,
            )

            return self._sanitize_generation(agent, result['response'], primary_response)

        except Exception as e:
            logger.error(f"❌ Erreur LLM pour {agent.name}: {e}")
            return f"{agent.name.split()[0]}: C'est un point intéressant à creuser."
    
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

    def _sanitize_generation(self, agent: AgentPersonality, generated: str, reference_text: str) -> str:
        """Nettoie les sorties LLM: évite auto‑références et répétitions de la phrase source."""
        if not generated:
            return f"{agent.name.split()[0]}: ..."

        text = generated.strip()
        first_name = agent.name.split()[0]
        # 1) Forcer le préfixe unique "Prénom:"
        #    Supprimer toute auto-présentation type "Je suis ..." répétée
        lowers = text.lower()
        if lowers.startswith("je suis ") or lowers.startswith("moi c'est "):
            # Couper la partie présentation
            parts = text.split(". ", 1)
            text = parts[1] if len(parts) > 1 else text
            text = text.lstrip()

        # Supprimer un doublon de préfixe "Nom:" si présent
        for sep in [":", "-", "—"]:
            prefix = f"{agent.name}{sep}"
            if text.lower().startswith(prefix.lower()):
                text = text[len(prefix):].lstrip()
            prefix2 = f"{first_name}{sep}"
            if text.lower().startswith(prefix2.lower()):
                text = text[len(prefix2):].lstrip()

        # 2) Réduire l'écho: si la génération répète mot à mot la phrase de référence
        if reference_text:
            ref = reference_text.strip()
            # si le début de la réponse est quasi identique au ref, tronquer
            if text[:80].lower() == ref[:80].lower():
                text = "" if len(text) <= len(ref) else text[len(ref):]
                text = text.lstrip(' .:\-—')

        # 3) Enlever auto‑questions internes type "Marcus: Marcus pense que..." → garder le contenu
        if text.lower().startswith(f"{first_name.lower()} "):
            text = text.split(' ', 1)[1].lstrip()

        # 4) Finaliser avec préfixe propre
        clean = text.strip()
        if not clean:
            clean = "C'est un point intéressant."
        return f"{first_name}: {clean}"
    
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