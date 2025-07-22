#!/usr/bin/env python3
"""
User Message Generator - Génération contextuelle de messages utilisateur réalistes

Ce module génère des messages utilisateur adaptatifs et contextuels pour simuler
une conversation réelle avec Marie. Il analyse l'état de Marie (satisfaction, patience,
mode conversationnel) et génère des réponses utilisateur appropriées pour maintenir
une progression conversationnelle naturelle et engageante.

Fonctionnalités principales :
- Banque templates messages par phase conversationnelle
- Analyse contextuelle état Marie pour adaptation
- Génération variée avec niveaux réalisme configurables
- Progression logique conversation commerciale
- Gestion objections et réponses appropriées
- Simulation comportements utilisateur authentiques
- Intégration métadonnées pour analyse qualité

Contextes supportés :
- Présentation produit / service
- Négociation commerciale  
- Réunion client / prospect
- Entretien démonstration
- Session questions-réponses
"""

import random
import re
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json

class ConversationPhase(Enum):
    """Phases de progression conversationnelle"""
    INTRODUCTION = "introduction"
    DISCOVERY = "discovery" 
    PRESENTATION = "presentation"
    OBJECTION_HANDLING = "objection_handling"
    NEGOTIATION = "negotiation"
    CLOSING = "closing"
    FOLLOW_UP = "follow_up"

class UserPersonality(Enum):
    """Types de personnalité utilisateur simulée"""
    INTERESTED_PROSPECT = "interested_prospect"
    SKEPTICAL_BUYER = "skeptical_buyer"
    ANALYTICAL_DECISION_MAKER = "analytical_decision_maker"
    BUDGET_CONSCIOUS = "budget_conscious"
    TIME_PRESSED_EXECUTIVE = "time_pressed_executive"
    TECHNICAL_EVALUATOR = "technical_evaluator"

class MessageCategory(Enum):
    """Catégories de messages utilisateur"""
    QUESTION = "question"
    RESPONSE = "response"
    OBJECTION = "objection"
    AGREEMENT = "agreement"
    REQUEST_INFO = "request_info"
    CLARIFICATION = "clarification"
    CONCERN = "concern"
    ENTHUSIASM = "enthusiasm"

@dataclass
class UserContext:
    """Contexte utilisateur pour génération messages"""
    personality: UserPersonality = UserPersonality.INTERESTED_PROSPECT
    engagement_level: float = 0.7  # 0.0 à 1.0
    technical_depth: float = 0.5  # Niveau technique souhaité
    budget_sensitivity: float = 0.5  # Sensibilité prix
    time_pressure: float = 0.3  # Pression temporelle
    decision_authority: float = 0.8  # Pouvoir décision
    previous_experience: str = "novice"  # novice, experienced, expert
    industry_context: str = "technology"
    company_size: str = "medium"

@dataclass
class MessageTemplate:
    """Template de message utilisateur"""
    template: str
    category: MessageCategory
    phase: ConversationPhase
    personality_match: List[UserPersonality]
    marie_satisfaction_range: Tuple[float, float] = (0.0, 1.0)
    marie_patience_range: Tuple[float, float] = (0.0, 1.0)
    engagement_threshold: float = 0.3
    technical_level: str = "basic"  # basic, intermediate, advanced
    placeholders: Dict[str, List[str]] = field(default_factory=dict)

@dataclass
class GeneratedMessage:
    """Message généré avec métadonnées"""
    content: str
    category: MessageCategory
    phase: ConversationPhase
    confidence_score: float
    context_match_score: float
    realism_score: float
    generation_timestamp: datetime
    marie_state_snapshot: Dict[str, Any]
    user_context_used: UserContext
    template_source: Optional[str] = None

class UserMessageGenerator:
    """
    Générateur de messages utilisateur contextuels et adaptatifs
    
    Responsabilités :
    - Analyse état Marie pour adaptation contextuelle
    - Génération messages variés par phase conversationnelle
    - Simulation personnalités utilisateur diversifiées
    - Progression logique et naturelle de conversation
    - Maintien cohérence comportementale utilisateur
    - Optimisation engagement et réalisme interaction
    """
    
    def __init__(self, realism_level: float = 0.7, user_context: Optional[UserContext] = None):
        """
        Initialise le générateur de messages utilisateur
        
        Args:
            realism_level: Niveau réalisme 0.0-1.0 (plus élevé = plus naturel)
            user_context: Contexte utilisateur personnalisé
        """
        self.realism_level = realism_level
        self.user_context = user_context or UserContext()
        self.conversation_history = []
        self.current_phase = ConversationPhase.INTRODUCTION
        self.phase_progression = []
        self.message_count = 0
        self.last_marie_state = {}
        
        # Banque templates messages
        self.message_templates = self._initialize_message_templates()
        
        # Cache génération pour éviter répétitions
        self.recent_messages = []
        self.used_templates = set()
        
        # Métriques génération
        self.generation_stats = {
            'total_generated': 0,
            'by_category': {cat: 0 for cat in MessageCategory},
            'by_phase': {phase: 0 for phase in ConversationPhase},
            'average_confidence': 0.0,
            'average_realism': 0.0
        }
        
        self.logger = logging.getLogger(__name__)
        self.logger.info(f"UserMessageGenerator initialisé - Réalisme: {realism_level}")
    
    def _initialize_message_templates(self) -> List[MessageTemplate]:
        """
        Initialise la banque complète de templates de messages
        
        Returns:
            List[MessageTemplate]: Templates organisés par contexte
        """
        templates = []
        
        # === PHASE INTRODUCTION ===
        templates.extend([
            MessageTemplate(
                template="Bonjour {marie_name}, merci de prendre le temps de me recevoir. Je suis {user_role} chez {company_name} et je m'intéresse à {product_area}.",
                category=MessageCategory.RESPONSE,
                phase=ConversationPhase.INTRODUCTION,
                personality_match=[UserPersonality.INTERESTED_PROSPECT, UserPersonality.ANALYTICAL_DECISION_MAKER],
                placeholders={
                    'marie_name': ['Marie', 'Madame Dubois', 'Madame la Directrice'],
                    'user_role': ['responsable des achats', 'directeur technique', 'chef de projet', 'consultant'],
                    'company_name': ['TechCorp', 'InnovatePlus', 'BusinessFlow', 'DataVision'],
                    'product_area': ['vos solutions', 'votre offre', 'votre plateforme', 'vos services']
                }
            ),
            MessageTemplate(
                template="Salut Marie ! J'ai entendu parler de votre boîte par {reference_source}. Ça m'intéresse vraiment de voir ce que vous pouvez nous proposer.",
                category=MessageCategory.RESPONSE,
                phase=ConversationPhase.INTRODUCTION,
                personality_match=[UserPersonality.TIME_PRESSED_EXECUTIVE],
                placeholders={
                    'reference_source': ['un collègue', 'LinkedIn', 'un article', 'une recommandation']
                }
            ),
            MessageTemplate(
                template="Bonjour. Avant de commencer, j'aimerais préciser que nous évaluons plusieurs solutions en parallèle. Qu'est-ce qui vous différencie vraiment de la concurrence ?",
                category=MessageCategory.QUESTION,
                phase=ConversationPhase.INTRODUCTION,
                personality_match=[UserPersonality.SKEPTICAL_BUYER, UserPersonality.ANALYTICAL_DECISION_MAKER],
                engagement_threshold=0.6
            )
        ])
        
        # === PHASE DISCOVERY ===
        templates.extend([
            MessageTemplate(
                template="Actuellement, nous utilisons {current_solution} mais nous avons des problèmes de {pain_point}. Comment votre solution adresse-t-elle ces enjeux ?",
                category=MessageCategory.QUESTION,
                phase=ConversationPhase.DISCOVERY,
                personality_match=[UserPersonality.TECHNICAL_EVALUATOR, UserPersonality.ANALYTICAL_DECISION_MAKER],
                placeholders={
                    'current_solution': ['un système interne', 'une solution legacy', 'des outils dispersés', 'un concurrent'],
                    'pain_point': ['performance', 'maintenance', 'coûts', 'intégration', 'évolutivité']
                }
            ),
            MessageTemplate(
                template="C'est intéressant. Pouvez-vous me donner des exemples concrets de clients similaires à nous qui ont eu des résultats mesurables ?",
                category=MessageCategory.REQUEST_INFO,
                phase=ConversationPhase.DISCOVERY,
                personality_match=[UserPersonality.SKEPTICAL_BUYER, UserPersonality.BUDGET_CONSCIOUS],
                marie_satisfaction_range=(0.3, 0.8)
            ),
            MessageTemplate(
                template="OK, je vois. Mais concrètement, quel serait le ROI estimé pour une entreprise comme la nôtre ? J'ai besoin de chiffres précis pour justifier l'investissement.",
                category=MessageCategory.REQUEST_INFO,
                phase=ConversationPhase.DISCOVERY,
                personality_match=[UserPersonality.BUDGET_CONSCIOUS, UserPersonality.ANALYTICAL_DECISION_MAKER],
                technical_level="intermediate"
            )
        ])
        
        # === PHASE PRESENTATION ===
        templates.extend([
            MessageTemplate(
                template="Cette fonctionnalité {feature_name} m'intéresse particulièrement. Comment elle s'intègre avec nos systèmes existants comme {existing_system} ?",
                category=MessageCategory.QUESTION,
                phase=ConversationPhase.PRESENTATION,
                personality_match=[UserPersonality.TECHNICAL_EVALUATOR],
                placeholders={
                    'feature_name': ['d\'automatisation', 'de reporting', 'd\'intégration', 'de sécurité'],
                    'existing_system': ['notre CRM', 'notre ERP', 'nos bases de données', 'notre infrastructure']
                },
                technical_level="advanced"
            ),
            MessageTemplate(
                template="Hmm, c'est pas mal. Par contre, qu'est-ce qui se passe si on a besoin de {scaling_concern} ? Votre solution peut-elle s'adapter ?",
                category=MessageCategory.CONCERN,
                phase=ConversationPhase.PRESENTATION,
                personality_match=[UserPersonality.ANALYTICAL_DECISION_MAKER, UserPersonality.TECHNICAL_EVALUATOR],
                placeholders={
                    'scaling_concern': ['monter en charge rapidement', 'ajouter de nouveaux utilisateurs', 'gérer plus de données', 'étendre à d\'autres départements']
                }
            ),
            MessageTemplate(
                template="Très bien ! Ça répond exactement à nos besoins. J'aimerais voir une démonstration avec nos propres données. C'est possible ?",
                category=MessageCategory.ENTHUSIASM,
                phase=ConversationPhase.PRESENTATION,
                personality_match=[UserPersonality.INTERESTED_PROSPECT],
                marie_satisfaction_range=(0.6, 1.0)
            )
        ])
        
        # === PHASE OBJECTION_HANDLING ===
        templates.extend([
            MessageTemplate(
                template="Je comprends les avantages, mais franchement {price_amount} c'est au-dessus de notre budget prévu. On avait tablé sur {budget_range}.",
                category=MessageCategory.OBJECTION,
                phase=ConversationPhase.OBJECTION_HANDLING,
                personality_match=[UserPersonality.BUDGET_CONSCIOUS],
                placeholders={
                    'price_amount': ['ce prix', 'cette tarification', 'ce montant'],
                    'budget_range': ['quelque chose de plus abordable', 'la moitié de ça', 'un budget plus serré']
                }
            ),
            MessageTemplate(
                template="L'offre est intéressante mais j'ai des doutes sur {concern_area}. Vous avez des garanties ou des références pour me rassurer ?",
                category=MessageCategory.CONCERN,
                phase=ConversationPhase.OBJECTION_HANDLING,
                personality_match=[UserPersonality.SKEPTICAL_BUYER, UserPersonality.ANALYTICAL_DECISION_MAKER],
                placeholders={
                    'concern_area': ['la fiabilité', 'le support technique', 'la pérennité de votre entreprise', 'la migration des données']
                }
            ),
            MessageTemplate(
                template="OK, vous me rassurez sur ce point. Mais il faut que j'en discute avec {decision_maker}. Ils vont sûrement avoir des questions sur {technical_aspect}.",
                category=MessageCategory.RESPONSE,
                phase=ConversationPhase.OBJECTION_HANDLING,
                personality_match=[UserPersonality.ANALYTICAL_DECISION_MAKER],
                marie_satisfaction_range=(0.4, 0.7),
                placeholders={
                    'decision_maker': ['mon équipe', 'la direction', 'le comité de direction', 'mon manager'],
                    'technical_aspect': ['la sécurité', 'l\'architecture', 'la maintenance', 'les performances']
                }
            )
        ])
        
        # === PHASE NEGOTIATION ===
        templates.extend([
            MessageTemplate(
                template="Écoutez Marie, votre solution nous intéresse vraiment. Mais pour qu'on puisse signer, il faudrait qu'on trouve un arrangement sur {negotiation_point}.",
                category=MessageCategory.REQUEST_INFO,
                phase=ConversationPhase.NEGOTIATION,
                personality_match=[UserPersonality.BUDGET_CONSCIOUS, UserPersonality.TIME_PRESSED_EXECUTIVE],
                placeholders={
                    'negotiation_point': ['le prix', 'les conditions de paiement', 'le planning de déploiement', 'le support inclus']
                }
            ),
            MessageTemplate(
                template="C'est un bon compromis. Si on peut formaliser ça avec {contract_condition}, je pense qu'on peut avancer rapidement.",
                category=MessageCategory.AGREEMENT,
                phase=ConversationPhase.NEGOTIATION,
                personality_match=[UserPersonality.INTERESTED_PROSPECT, UserPersonality.TIME_PRESSED_EXECUTIVE],
                marie_satisfaction_range=(0.5, 1.0),
                placeholders={
                    'contract_condition': ['une période d\'essai', 'des jalons de paiement', 'des garanties de performance', 'une clause de révision']
                }
            )
        ])
        
        # === PHASE CLOSING ===
        templates.extend([
            MessageTemplate(
                template="Perfect ! Je suis convaincu. Quelles sont les prochaines étapes pour démarrer ? J'aimerais qu'on avance vite sur ce projet.",
                category=MessageCategory.ENTHUSIASM,
                phase=ConversationPhase.CLOSING,
                personality_match=[UserPersonality.INTERESTED_PROSPECT, UserPersonality.TIME_PRESSED_EXECUTIVE],
                marie_satisfaction_range=(0.7, 1.0)
            ),
            MessageTemplate(
                template="OK, ça me va. Je vais présenter votre proposition en interne et on vous recontacte sous {timeline} avec notre décision finale.",
                category=MessageCategory.RESPONSE,
                phase=ConversationPhase.CLOSING,
                personality_match=[UserPersonality.ANALYTICAL_DECISION_MAKER],
                placeholders={
                    'timeline': ['48h', 'une semaine', 'quelques jours', 'la semaine prochaine']
                }
            ),
            MessageTemplate(
                template="Merci Marie pour cette présentation. C'était très éclairant. Je vais avoir besoin de {final_requirement} avant de prendre ma décision.",
                category=MessageCategory.REQUEST_INFO,
                phase=ConversationPhase.CLOSING,
                personality_match=[UserPersonality.SKEPTICAL_BUYER, UserPersonality.ANALYTICAL_DECISION_MAKER],
                placeholders={
                    'final_requirement': ['références client', 'un devis détaillé', 'une démonstration technique', 'l\'avis de mes équipes']
                }
            )
        ])
        
        # === MESSAGES ADAPTATIFS SELON ÉTAT MARIE ===
        templates.extend([
            # Marie impatiente
            MessageTemplate(
                template="Je sens que vous êtes pressée. On peut peut-être accélérer et aller directement aux points essentiels ?",
                category=MessageCategory.CLARIFICATION,
                phase=ConversationPhase.DISCOVERY,
                personality_match=[UserPersonality.TIME_PRESSED_EXECUTIVE],
                marie_patience_range=(0.0, 0.3)
            ),
            # Marie très satisfaite
            MessageTemplate(
                template="Excellent ! Votre enthousiasme me confirme qu'on est sur la bonne voie. Comment on concrétise ça ?",
                category=MessageCategory.ENTHUSIASM,
                phase=ConversationPhase.PRESENTATION,
                personality_match=[UserPersonality.INTERESTED_PROSPECT],
                marie_satisfaction_range=(0.8, 1.0)
            ),
            # Marie peu satisfaite
            MessageTemplate(
                template="J'ai l'impression qu'on n'est pas complètement alignés. Qu'est-ce qui vous pose problème dans ma demande ?",
                category=MessageCategory.CLARIFICATION,
                phase=ConversationPhase.DISCOVERY,
                personality_match=[UserPersonality.ANALYTICAL_DECISION_MAKER],
                marie_satisfaction_range=(0.0, 0.3)
            )
        ])
        
        return templates
    
    def generate_message(self, marie_state: Dict[str, Any], 
                        force_category: Optional[MessageCategory] = None,
                        force_phase: Optional[ConversationPhase] = None) -> GeneratedMessage:
        """
        Génère un message utilisateur adapté au contexte Marie
        
        Args:
            marie_state: État actuel de Marie (satisfaction, patience, mode, etc.)
            force_category: Catégorie forcée (optionnel)
            force_phase: Phase forcée (optionnel)
            
        Returns:
            GeneratedMessage: Message contextualisé avec métadonnées
        """
        self.last_marie_state = marie_state.copy()
        
        # Mise à jour phase conversationnelle automatique
        if not force_phase:
            self._update_conversation_phase(marie_state)
        
        # Sélection templates candidats
        candidate_templates = self._filter_templates(
            marie_state, force_category, force_phase or self.current_phase
        )
        
        if not candidate_templates:
            # Fallback si pas de templates appropriés
            return self._generate_fallback_message(marie_state)
        
        # Sélection template optimal
        selected_template = self._select_optimal_template(candidate_templates, marie_state)
        
        # Génération contenu final
        message_content = self._generate_content_from_template(selected_template, marie_state)
        
        # Calcul scores qualité
        confidence_score = self._calculate_confidence_score(selected_template, marie_state)
        context_match_score = self._calculate_context_match_score(selected_template, marie_state)
        realism_score = self._calculate_realism_score(message_content, marie_state)
        
        # Création message final
        generated_message = GeneratedMessage(
            content=message_content,
            category=selected_template.category,
            phase=self.current_phase,
            confidence_score=confidence_score,
            context_match_score=context_match_score,
            realism_score=realism_score,
            generation_timestamp=datetime.now(),
            marie_state_snapshot=marie_state.copy(),
            user_context_used=self.user_context,
            template_source=selected_template.template[:50] + "..."
        )
        
        # Mise à jour historique et stats
        self._update_generation_history(generated_message, selected_template)
        
        self.logger.info(f"Message généré - Phase: {self.current_phase.value}, "
                        f"Catégorie: {selected_template.category.value}, "
                        f"Confiance: {confidence_score:.2f}")
        
        return generated_message
    
    def _update_conversation_phase(self, marie_state: Dict[str, Any]):
        """
        Met à jour automatiquement la phase conversationnelle
        
        Args:
            marie_state: État Marie pour déterminer progression
        """
        # Progression basée sur nombre de messages et état Marie
        marie_mode = marie_state.get('current_mode', 'initial_evaluation')
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        exchange_count = len(self.conversation_history)
        
        # Logique progression phases
        if exchange_count <= 2:
            new_phase = ConversationPhase.INTRODUCTION
        elif marie_mode in ['initial_evaluation', 'questioning']:
            new_phase = ConversationPhase.DISCOVERY
        elif marie_mode in ['presentation', 'demonstration'] or exchange_count >= 4:
            new_phase = ConversationPhase.PRESENTATION
        elif marie_mode == 'objection_challenger' or marie_satisfaction < 0.4:
            new_phase = ConversationPhase.OBJECTION_HANDLING
        elif marie_mode in ['negotiation', 'firm_negotiation']:
            new_phase = ConversationPhase.NEGOTIATION
        elif marie_mode in ['final_validation', 'decision_closing']:
            new_phase = ConversationPhase.CLOSING
        else:
            # Garder phase actuelle si indéterminée
            new_phase = self.current_phase
        
        # Éviter retours en arrière inappropriés
        phase_order = [
            ConversationPhase.INTRODUCTION,
            ConversationPhase.DISCOVERY,
            ConversationPhase.PRESENTATION,
            ConversationPhase.OBJECTION_HANDLING,
            ConversationPhase.NEGOTIATION,
            ConversationPhase.CLOSING
        ]
        
        current_index = phase_order.index(self.current_phase) if self.current_phase in phase_order else 0
        new_index = phase_order.index(new_phase) if new_phase in phase_order else current_index
        
        # Autoriser seulement progression ou objection_handling depuis n'importe où
        if new_index >= current_index or new_phase == ConversationPhase.OBJECTION_HANDLING:
            if self.current_phase != new_phase:
                self.phase_progression.append({
                    'from_phase': self.current_phase.value,
                    'to_phase': new_phase.value,
                    'trigger': marie_mode,
                    'timestamp': datetime.now().isoformat()
                })
                self.current_phase = new_phase
    
    def _filter_templates(self, marie_state: Dict[str, Any], 
                         force_category: Optional[MessageCategory],
                         target_phase: ConversationPhase) -> List[MessageTemplate]:
        """
        Filtre les templates selon contexte et contraintes
        
        Args:
            marie_state: État Marie actuel
            force_category: Catégorie forcée
            target_phase: Phase cible
            
        Returns:
            List[MessageTemplate]: Templates candidats
        """
        candidates = []
        
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        marie_patience = marie_state.get('patience_level', 1.0)
        
        for template in self.message_templates:
            # Filtrage phase
            if template.phase != target_phase:
                continue
            
            # Filtrage catégorie forcée
            if force_category and template.category != force_category:
                continue
            
            # Filtrage personnalité utilisateur
            if self.user_context.personality not in template.personality_match:
                continue
            
            # Filtrage état Marie
            sat_min, sat_max = template.marie_satisfaction_range
            if not (sat_min <= marie_satisfaction <= sat_max):
                continue
            
            pat_min, pat_max = template.marie_patience_range
            if not (pat_min <= marie_patience <= pat_max):
                continue
            
            # Filtrage engagement utilisateur
            if self.user_context.engagement_level < template.engagement_threshold:
                continue
            
            # Filtrage niveau technique
            user_tech_level = self.user_context.technical_depth
            if template.technical_level == "advanced" and user_tech_level < 0.7:
                continue
            elif template.technical_level == "intermediate" and user_tech_level < 0.4:
                continue
            
            # Éviter répétitions récentes
            template_id = id(template)
            if template_id in self.used_templates and len(self.used_templates) < len(self.message_templates) * 0.8:
                continue
            
            candidates.append(template)
        
        return candidates
    
    def _select_optimal_template(self, candidates: List[MessageTemplate], 
                               marie_state: Dict[str, Any]) -> MessageTemplate:
        """
        Sélectionne le template optimal parmi les candidats
        
        Args:
            candidates: Templates candidats
            marie_state: État Marie pour optimisation
            
        Returns:
            MessageTemplate: Template sélectionné
        """
        if len(candidates) == 1:
            return candidates[0]
        
        # Calcul score pour chaque candidat
        scored_candidates = []
        
        for template in candidates:
            score = 0.0
            
            # Score match personnalité (30%)
            if self.user_context.personality in template.personality_match:
                score += 0.3
            
            # Score pertinence état Marie (40%)
            marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
            marie_patience = marie_state.get('patience_level', 1.0)
            
            sat_min, sat_max = template.marie_satisfaction_range
            sat_match = 1.0 - abs(marie_satisfaction - (sat_min + sat_max) / 2) / 0.5
            score += 0.2 * max(0, sat_match)
            
            pat_min, pat_max = template.marie_patience_range
            pat_match = 1.0 - abs(marie_patience - (pat_min + pat_max) / 2) / 0.5
            score += 0.2 * max(0, pat_match)
            
            # Score variété (éviter répétitions) (20%)
            template_id = id(template)
            if template_id not in self.used_templates:
                score += 0.2
            
            # Score réalisme (10%)
            if template.category in [MessageCategory.QUESTION, MessageCategory.RESPONSE]:
                score += 0.1 * self.realism_level
            
            scored_candidates.append((template, score))
        
        # Sélection avec randomness proportionnelle au réalisme
        if self.realism_level > 0.8:
            # Haute fidélité : sélection optimale
            return max(scored_candidates, key=lambda x: x[1])[0]
        else:
            # Réalisme modéré : sélection pondérée
            weights = [score for _, score in scored_candidates]
            return random.choices(candidates, weights=weights)[0]
    
    def _generate_content_from_template(self, template: MessageTemplate, 
                                      marie_state: Dict[str, Any]) -> str:
        """
        Génère le contenu final à partir du template
        
        Args:
            template: Template sélectionné
            marie_state: État Marie pour contextualisation
            
        Returns:
            str: Contenu message final
        """
        content = template.template
        
        # Remplacement placeholders
        for placeholder, options in template.placeholders.items():
            if f"{{{placeholder}}}" in content:
                selected_option = random.choice(options)
                content = content.replace(f"{{{placeholder}}}", selected_option)
        
        # Ajustements stylistiques selon réalisme
        if self.realism_level > 0.7:
            content = self._add_realistic_variations(content, marie_state)
        
        # Ajustements selon état Marie
        content = self._adjust_for_marie_state(content, marie_state)
        
        return content.strip()
    
    def _add_realistic_variations(self, content: str, marie_state: Dict[str, Any]) -> str:
        """
        Ajoute des variations réalistes au contenu
        
        Args:
            content: Contenu de base
            marie_state: État Marie
            
        Returns:
            str: Contenu avec variations naturelles
        """
        # Ajout hésitations naturelles selon engagement
        if self.user_context.engagement_level < 0.5:
            hesitations = ["euh...", "bon...", "enfin...", "disons que..."]
            if random.random() < 0.3:
                content = random.choice(hesitations) + " " + content
        
        # Ajout connecteurs selon personnalité
        if self.user_context.personality == UserPersonality.ANALYTICAL_DECISION_MAKER:
            analytical_starters = ["Concrètement,", "En fait,", "Si je comprends bien,", "Autrement dit,"]
            if random.random() < 0.4:
                content = random.choice(analytical_starters) + " " + content.lower()
        
        # Ajout urgence si time pressure élevée
        if self.user_context.time_pressure > 0.7:
            urgency_additions = [" Il faut qu'on avance vite sur ça.", " On est un peu pressés par le temps.", " C'est urgent côté planning."]
            if random.random() < 0.3:
                content += random.choice(urgency_additions)
        
        return content
    
    def _adjust_for_marie_state(self, content: str, marie_state: Dict[str, Any]) -> str:
        """
        Ajuste le contenu selon l'état spécifique de Marie
        
        Args:
            content: Contenu base
            marie_state: État Marie actuel
            
        Returns:
            str: Contenu ajusté
        """
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        marie_patience = marie_state.get('patience_level', 1.0)
        
        # Réaction à la satisfaction Marie
        if marie_satisfaction > 0.8:
            # Marie très satisfaite : renforcer positivement
            positive_reinforcements = [
                " Ça me rassure beaucoup.",
                " C'est exactement ce qu'on cherchait.",
                " Perfect, on est sur la même longueur d'onde."
            ]
            if random.random() < 0.4:
                content += random.choice(positive_reinforcements)
        
        elif marie_satisfaction < 0.3:
            # Marie peu satisfaite : montrer compréhension
            understanding_signals = [
                " Je sens qu'il y a peut-être un malentendu ?",
                " Est-ce que j'ai raté quelque chose ?",
                " On peut reprendre si c'est pas clair."
            ]
            if random.random() < 0.3:
                content += random.choice(understanding_signals)
        
        # Réaction à la patience Marie
        if marie_patience < 0.3:
            # Marie impatiente : accélérer/focaliser
            pace_adjustments = [
                " Je vais être direct :",
                " Pour aller à l'essentiel :",
                " Rapidement :"
            ]
            if random.random() < 0.5:
                content = random.choice(pace_adjustments) + " " + content.lower()
        
        return content
    
    def _calculate_confidence_score(self, template: MessageTemplate, 
                                  marie_state: Dict[str, Any]) -> float:
        """
        Calcule score confiance génération
        
        Args:
            template: Template utilisé
            marie_state: État Marie
            
        Returns:
            float: Score confiance 0.0-1.0
        """
        score = 0.5  # Base
        
        # Bonus match personnalité parfait
        if self.user_context.personality in template.personality_match:
            score += 0.2
        
        # Bonus phase appropriée
        if template.phase == self.current_phase:
            score += 0.15
        
        # Bonus état Marie dans range optimal
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        sat_min, sat_max = template.marie_satisfaction_range
        if sat_min <= marie_satisfaction <= sat_max:
            score += 0.15
        
        return min(1.0, score)
    
    def _calculate_context_match_score(self, template: MessageTemplate, 
                                     marie_state: Dict[str, Any]) -> float:
        """
        Calcule score match contextuel
        
        Args:
            template: Template utilisé
            marie_state: État Marie
            
        Returns:
            float: Score match contextuel 0.0-1.0
        """
        score = 0.0
        
        # Match phase conversationnelle (40%)
        if template.phase == self.current_phase:
            score += 0.4
        
        # Match état émotionnel Marie (30%)
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        marie_patience = marie_state.get('patience_level', 1.0)
        
        sat_min, sat_max = template.marie_satisfaction_range
        sat_score = 1.0 - abs(marie_satisfaction - (sat_min + sat_max) / 2) / 0.5
        score += 0.15 * max(0, sat_score)
        
        pat_min, pat_max = template.marie_patience_range
        pat_score = 1.0 - abs(marie_patience - (pat_min + pat_max) / 2) / 0.5
        score += 0.15 * max(0, pat_score)
        
        # Match profil utilisateur (30%)
        if self.user_context.personality in template.personality_match:
            score += 0.3
        
        return min(1.0, score)
    
    def _calculate_realism_score(self, content: str, marie_state: Dict[str, Any]) -> float:
        """
        Calcule score réalisme du message généré
        
        Args:
            content: Contenu généré
            marie_state: État Marie
            
        Returns:
            float: Score réalisme 0.0-1.0
        """
        score = self.realism_level  # Base niveau réalisme configuré
        
        # Bonus longueur appropriée (ni trop court ni trop long)
        content_length = len(content.split())
        if 5 <= content_length <= 25:
            score += 0.1
        
        # Bonus variabilité linguistique
        if any(word in content.lower() for word in ["euh", "bon", "enfin", "disons"]):
            score += 0.05
        
        # Bonus adaptation état Marie
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        if marie_satisfaction > 0.7 and any(word in content.lower() for word in ["excellent", "perfect", "exactement"]):
            score += 0.1
        elif marie_satisfaction < 0.3 and any(word in content.lower() for word in ["problème", "doute", "inquiet"]):
            score += 0.1
        
        return min(1.0, score)
    
    def _generate_fallback_message(self, marie_state: Dict[str, Any]) -> GeneratedMessage:
        """
        Génère un message de fallback si aucun template approprié
        
        Args:
            marie_state: État Marie
            
        Returns:
            GeneratedMessage: Message fallback générique
        """
        fallback_messages = [
            "Pouvez-vous m'en dire plus sur ce point ?",
            "C'est intéressant. Comment ça fonctionne concrètement ?",
            "OK, je vois. Et ensuite ?",
            "Hmm, j'aimerais mieux comprendre cet aspect.",
            "D'accord. Qu'est-ce que vous me conseillez ?"
        ]
        
        content = random.choice(fallback_messages)
        
        return GeneratedMessage(
            content=content,
            category=MessageCategory.QUESTION,
            phase=self.current_phase,
            confidence_score=0.3,  # Score faible pour fallback
            context_match_score=0.2,
            realism_score=0.4,
            generation_timestamp=datetime.now(),
            marie_state_snapshot=marie_state.copy(),
            user_context_used=self.user_context,
            template_source="fallback_generator"
        )
    
    def _update_generation_history(self, message: GeneratedMessage, template: MessageTemplate):
        """
        Met à jour historique et statistiques génération
        
        Args:
            message: Message généré
            template: Template utilisé
        """
        # Historique conversation
        self.conversation_history.append({
            'message': message.content,
            'timestamp': message.generation_timestamp.isoformat(),
            'category': message.category.value,
            'phase': message.phase.value,
            'confidence': message.confidence_score
        })
        
        # Cache messages récents (éviter répétitions)
        self.recent_messages.append(message.content)
        if len(self.recent_messages) > 10:
            self.recent_messages.pop(0)
        
        # Templates utilisés
        self.used_templates.add(id(template))
        if len(self.used_templates) > len(self.message_templates) * 0.8:
            self.used_templates.clear()  # Reset périodique
        
        # Statistiques
        self.generation_stats['total_generated'] += 1
        self.generation_stats['by_category'][message.category] += 1
        self.generation_stats['by_phase'][message.phase] += 1
        
        # Moyennes glissantes
        total = self.generation_stats['total_generated']
        self.generation_stats['average_confidence'] = (
            (self.generation_stats['average_confidence'] * (total - 1) + message.confidence_score) / total
        )
        self.generation_stats['average_realism'] = (
            (self.generation_stats['average_realism'] * (total - 1) + message.realism_score) / total
        )
        
        self.message_count += 1
    
    def get_generation_analytics(self) -> Dict[str, Any]:
        """
        Obtient les analytics de génération
        
        Returns:
            Dict[str, Any]: Statistiques détaillées
        """
        return {
            'user_context': {
                'personality': self.user_context.personality.value,
                'engagement_level': self.user_context.engagement_level,
                'technical_depth': self.user_context.technical_depth,
                'realism_configured': self.realism_level
            },
            'conversation_progression': {
                'current_phase': self.current_phase.value,
                'phase_history': self.phase_progression,
                'message_count': self.message_count,
                'conversation_duration': len(self.conversation_history)
            },
            'generation_performance': self.generation_stats,
            'template_utilization': {
                'templates_available': len(self.message_templates),
                'templates_used': len(self.used_templates),
                'utilization_rate': len(self.used_templates) / len(self.message_templates)
            },
            'last_marie_state': self.last_marie_state
        }
    
    def reset_conversation(self):
        """Remet à zéro la conversation pour nouveau cycle"""
        self.conversation_history = []
        self.current_phase = ConversationPhase.INTRODUCTION
        self.phase_progression = []
        self.message_count = 0
        self.recent_messages = []
        self.used_templates.clear()
        self.last_marie_state = {}
        
        self.logger.info("Conversation réinitialisée")
    
    def update_user_context(self, new_context: UserContext):
        """
        Met à jour le contexte utilisateur
        
        Args:
            new_context: Nouveau contexte utilisateur
        """
        self.user_context = new_context
        self.logger.info(f"Contexte utilisateur mis à jour - Personnalité: {new_context.personality.value}")
    
    def export_conversation_log(self, filepath: Optional[str] = None) -> str:
        """
        Exporte le log complet de conversation
        
        Args:
            filepath: Chemin fichier optionnel
            
        Returns:
            str: Chemin fichier généré
        """
        if not filepath:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = f"user_message_generation_log_{timestamp}.json"
        
        export_data = {
            'session_info': {
                'generation_timestamp': datetime.now().isoformat(),
                'realism_level': self.realism_level,
                'user_context': {
                    'personality': self.user_context.personality.value,
                    'engagement_level': self.user_context.engagement_level,
                    'technical_depth': self.user_context.technical_depth
                }
            },
            'conversation_log': self.conversation_history,
            'phase_progression': self.phase_progression,
            'generation_analytics': self.get_generation_analytics()
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Log conversation exporté: {filepath}")
        return filepath