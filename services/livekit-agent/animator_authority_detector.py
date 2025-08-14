"""
Détecteur d'autorité de l'animateur pour reconnaître ses directives
Ce module permet à l'animateur Michel Dubois de contrôler effectivement le débat
en reconnaissant ses questions générales et directives spécifiques.
"""
import re
import logging

logger = logging.getLogger(__name__)

class AnimatorAuthorityDetector:
    """Détecteur des directives et questions de l'animateur"""
    
    def __init__(self):
        # Patterns pour questions générales de l'animateur
        self.general_questions = [
            r"et vous[,\s]*que",
            r"qu['\s]*en pensez[- ]vous",
            r"votre (avis|réaction|point de vue)",
            r"que (répondez|dites)[- ]vous",
            r"comment voyez[- ]vous",
            r"votre position sur",
            r"passionnant[!\s]*et vous",
            r"intéressant[!\s]*et vous",
            r"excellent[!\s]*et vous",
            r"très bien[!\s]*et vous",
            r"parfait[!\s]*et vous",
            r"que répondez[- ]vous à cela",
            r"qu['\s]*en dites[- ]vous",
            r"votre réaction",
            r"comment réagissez[- ]vous",
            r"qu['\s]*est[- ]ce que vous en pensez"
        ]
        
        # Patterns pour directives directes (PRIORITÉ ABSOLUE)
        self.direct_assignments = [
            # Patterns avec noms + actions
            r"sarah[,\s]*(poursuivez|continuez|à vous|je vous en prie)",
            r"marcus[,\s]*(poursuivez|continuez|à vous|je vous en prie)",
            r"(sarah|marcus)[,\s]*votre tour",
            r"(sarah|marcus)[,\s]*prenez la parole",
            r"sarah[,\s]*développez",
            r"marcus[,\s]*développez",
            r"sarah[,\s]*expliquez",
            r"marcus[,\s]*expliquez",
            
            # PATTERNS CRITIQUES MANQUANTS - Sarah/Marcus + questions/avis
            r"sarah[,\s]*votre (avis|opinion|point de vue|réaction)",
            r"marcus[,\s]*votre (avis|opinion|point de vue|réaction)",
            r"sarah[,\s]*que pensez[- ]vous",
            r"marcus[,\s]*que pensez[- ]vous",
            r"sarah[,\s]*qu['\s]*en pensez[- ]vous",
            r"marcus[,\s]*qu['\s]*en pensez[- ]vous",
            r"sarah[,\s]*comment voyez[- ]vous",
            r"marcus[,\s]*comment voyez[- ]vous",
            r"sarah[,\s]*que (dites|répondez)[- ]vous",
            r"marcus[,\s]*que (dites|répondez)[- ]vous",
            
            # PATTERNS MANQUANTS CRITIQUES pour "qu'en dit"
            r"sarah[,\s]*qu['\s]*en (dit|dites)",
            r"marcus[,\s]*qu['\s]*en (dit|dites)",
            r"sarah[,\s]*que (dit|dites)",
            r"marcus[,\s]*que (dit|dites)",
            
            # PATTERNS CRITIQUES MANQUANTS pour "vous pouvez/voulez"
            r"sarah[,\s]*vous pouvez",
            r"marcus[,\s]*vous pouvez",
            r"sarah[,\s]*vous voulez",
            r"marcus[,\s]*vous voulez",
            r"sarah[,\s]*pouvez[- ]vous",
            r"marcus[,\s]*pouvez[- ]vous",
            r"sarah[,\s]*voulez[- ]vous",
            r"marcus[,\s]*voulez[- ]vous",
            r"sarah[,\s]*pourriez[- ]vous",
            r"marcus[,\s]*pourriez[- ]vous",
            
            # Patterns attribution directe de parole
            r"à vous (sarah|marcus)",
            r"donnons la parole à (sarah|marcus)",
            r"écoutons (sarah|marcus)",
            r"passons à (sarah|marcus)",
            r"(sarah|marcus)[,\s]*à vous",
            r"et vous (sarah|marcus)",
            
            # Patterns modérateur TV
            r"(sarah|marcus)[,\s]*(justement|franchement|sincèrement)",
            r"(sarah|marcus)[,\s]*alors",
            r"(sarah|marcus)[,\s]*donc",
            r"(sarah|marcus)[,\s]*maintenant"
        ]
        
        # Patterns pour modération
        self.moderation_phrases = [
            r"permettez[- ]moi de",
            r"revenons à",
            r"pour conclure",
            r"synthétisons",
            r"récapitulons",
            r"faisons le point",
            r"avant de continuer",
            r"pour avancer",
            r"creusons ce point",
            r"approfondissons"
        ]
    
    def detect_animator_directive(self, message: str, speaker: str) -> dict:
        """
        Détecte si l'animateur donne une directive
        
        Returns:
            dict: {
                'type': 'direct_assignment' | 'general_question' | 'moderation' | None,
                'target_agent': str | 'any_available',
                'priority': 'CRITICAL' | 'HIGH' | 'NORMAL',
                'message': str
            }
        """
        if speaker != "animateur_principal":
            return None
            
        message_lower = message.lower().strip()
        
        # 1. Directive directe à un agent spécifique
        for pattern in self.direct_assignments:
            match = re.search(pattern, message_lower)
            if match:
                target_agent = self._extract_target_agent(match.group())
                logger.info(f"🎯 DIRECTIVE DIRECTE ANIMATEUR détectée pour: {target_agent}")
                return {
                    'type': 'direct_assignment',
                    'target_agent': target_agent,
                    'priority': 'CRITICAL',
                    'message': message
                }
        
        # 2. Question générale de l'animateur
        for pattern in self.general_questions:
            if re.search(pattern, message_lower):
                logger.info(f"🎯 QUESTION GÉNÉRALE ANIMATEUR détectée")
                return {
                    'type': 'general_question',
                    'target_agent': 'any_available',
                    'priority': 'HIGH',
                    'message': message
                }
        
        # 3. Phrase de modération
        for pattern in self.moderation_phrases:
            if re.search(pattern, message_lower):
                logger.info(f"🎯 MODÉRATION ANIMATEUR détectée")
                return {
                    'type': 'moderation',
                    'target_agent': 'any_available',
                    'priority': 'NORMAL',
                    'message': message
                }
        
        return None
    
    def _extract_target_agent(self, matched_text: str) -> str:
        """Extrait le nom de l'agent cible"""
        if 'sarah' in matched_text.lower():
            return 'journaliste_contradicteur'
        elif 'marcus' in matched_text.lower():
            return 'expert_specialise'
        return 'any_available'

class AnimatorAuthorityManager:
    """Gestionnaire de l'autorité de l'animateur"""
    
    def __init__(self):
        self.detector = AnimatorAuthorityDetector()
        self.participation_counts = {}
    
    def process_animator_directive(self, directive: dict, available_agents: list) -> list:
        """
        Traite les directives de l'animateur avec priorité absolue
        
        Returns:
            list: Agents autorisés à répondre (généralement un seul)
        """
        if not directive:
            return available_agents
        
        directive_type = directive['type']
        target = directive['target_agent']
        
        if directive_type == 'direct_assignment':
            # L'animateur désigne un agent spécifique - PRIORITÉ ABSOLUE
            if target in available_agents:
                logger.info(f"🎯 DIRECTIVE ANIMATEUR: {target} DOIT répondre (priorité CRITIQUE)")
                return [target]
            else:
                logger.warning(f"⚠️ Agent {target} non disponible, sélection alternative")
                return self._select_alternative_agent(available_agents)
        
        elif directive_type == 'general_question':
            # Question générale - sélectionner l'agent le moins actif
            selected = self._select_least_active_agent(available_agents)
            logger.info(f"🎯 QUESTION GÉNÉRALE ANIMATEUR: {selected} sélectionné")
            return [selected]
        
        elif directive_type == 'moderation':
            # Phrase de modération - permettre à tous de répondre
            logger.info(f"🎯 MODÉRATION ANIMATEUR: tous agents disponibles")
            return available_agents
        
        return available_agents
    
    def _select_least_active_agent(self, available_agents: list) -> str:
        """Sélectionne l'agent le moins actif (EXCLUANT l'animateur)"""
        if not available_agents:
            return None
        
        # CORRECTION CRITIQUE: Exclure l'animateur des questions générales
        # L'animateur pose la question, les invités répondent
        non_animator_agents = [agent for agent in available_agents if agent != 'animateur_principal']
        
        if not non_animator_agents:
            # Fallback si seul l'animateur est disponible
            return available_agents[0]
        
        # Compter les participations récentes (sans l'animateur)
        min_count = float('inf')
        selected = non_animator_agents[0]
        
        for agent in non_animator_agents:
            count = self.participation_counts.get(agent, 0)
            if count < min_count:
                min_count = count
                selected = agent
        
        logger.info(f"🎯 Agent le moins actif sélectionné (hors animateur): {selected}")
        return selected
    
    def _select_alternative_agent(self, available_agents: list) -> list:
        """Sélectionne un agent alternatif si le target n'est pas disponible"""
        if not available_agents:
            return []
        return [available_agents[0]]
    
    def update_participation(self, agent: str):
        """Met à jour le compteur de participation"""
        self.participation_counts[agent] = self.participation_counts.get(agent, 0) + 1
        
        # Garder seulement les 10 dernières interventions
        if self.participation_counts[agent] > 10:
            self.participation_counts[agent] = 5