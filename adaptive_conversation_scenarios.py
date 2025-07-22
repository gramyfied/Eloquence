#!/usr/bin/env python3
"""
Scénarios de Conversation Adaptatifs pour Tests Conversationnels
Définit les comportements, templates et règles pour différents contextes
"""

import json
import random
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import time

class ScenarioType(Enum):
    """Types de scénarios conversationnels"""
    PRESENTATION_CLIENT = "presentation_client"
    COMMERCIAL_DEMO = "commercial_demo"
    NEGOCIATION_PRIX = "negociation_prix"
    SUPPORT_TECHNIQUE = "support_technique"
    FORMATION_PRODUIT = "formation_produit"
    ENTRETIEN_VENTE = "entretien_vente"
    DEMO_PRODUIT = "demo_produit"
    RELATION_CLIENT = "relation_client"

class ConversationPhase(Enum):
    """Phases d'une conversation"""
    ACCUEIL = "accueil"
    IDENTIFICATION_BESOIN = "identification_besoin"
    PRESENTATION_SOLUTION = "presentation_solution"
    GESTION_OBJECTIONS = "gestion_objections"
    NEGOCIATION = "negociation"
    CONCLUSION = "conclusion"
    SUIVI = "suivi"

class UserProfile(Enum):
    """Profils d'utilisateurs pour les scénarios"""
    PROSPECT_CURIEUX = "prospect_curieux"
    CLIENT_EXIGEANT = "client_exigeant"
    DECISION_MAKER = "decision_maker"
    TECHNICIEN_SCEPTIQUE = "technicien_sceptique"
    COMMERCIAL_PRESSE = "commercial_presse"
    CLIENT_SATISFAIT = "client_satisfait"

@dataclass
class ConversationRule:
    """Règle de conversation pour un scénario"""
    condition: str  # Condition pour déclencher la règle
    action: str     # Action à exécuter
    priority: int   # Priorité de la règle (1 = haute priorité)
    description: str
    examples: List[str] = field(default_factory=list)

@dataclass
class ScenarioTemplate:
    """Template pour un type de scénario"""
    scenario_type: ScenarioType
    name: str
    description: str
    conversation_phases: List[ConversationPhase]
    user_profiles: List[UserProfile]
    conversation_rules: List[ConversationRule]
    expected_keywords: Dict[str, List[str]]  # Mots-clés attendus par phase
    success_criteria: Dict[str, Any]
    typical_duration: float  # Durée typique en minutes
    difficulty_level: int  # 1-5

class ConversationDynamics:
    """Gère la dynamique des conversations selon les scénarios"""
    
    def __init__(self):
        self.scenario_templates = self._initialize_scenario_templates()
        self.current_scenario: Optional[ScenarioTemplate] = None
        self.current_phase = ConversationPhase.ACCUEIL
        self.user_profile = UserProfile.PROSPECT_CURIEUX
        
        # État de la conversation
        self.conversation_context = {
            'mentioned_topics': [],
            'objections_raised': [],
            'positive_signals': [],
            'negotiation_points': [],
            'technical_questions': [],
            'price_discussed': False,
            'demo_requested': False,
            'follow_up_scheduled': False
        }
        
        # Métriques dynamiques
        self.phase_progression = []
        self.interaction_quality = 0.5
        self.user_engagement = 0.5
        
    def _initialize_scenario_templates(self) -> Dict[ScenarioType, ScenarioTemplate]:
        """Initialise les templates de scénarios"""
        
        templates = {}
        
        # SCÉNARIO 1: PRÉSENTATION CLIENT
        presentation_rules = [
            ConversationRule(
                condition="greeting_received",
                action="respond_professionally_introduce_company",
                priority=1,
                description="Répondre au salut et se présenter professionnellement",
                examples=[
                    "Bonjour, merci de me recevoir. Je suis Marie, votre assistante IA d'Eloquence.",
                    "Enchanté de faire votre connaissance. Permettez-moi de vous présenter notre solution."
                ]
            ),
            ConversationRule(
                condition="needs_identification_required",
                action="ask_discovery_questions",
                priority=2,
                description="Poser des questions de découverte pour identifier les besoins",
                examples=[
                    "Parlez-moi de vos défis actuels en communication.",
                    "Quel est votre objectif principal avec une solution d'amélioration de l'expression orale ?"
                ]
            ),
            ConversationRule(
                condition="solution_presentation_needed",
                action="present_tailored_solution",
                priority=2,
                description="Présenter la solution adaptée aux besoins identifiés",
                examples=[
                    "Basé sur ce que vous me dites, notre solution pourrait vous aider en...",
                    "Voici comment Eloquence répond spécifiquement à vos besoins..."
                ]
            ),
            ConversationRule(
                condition="objection_raised",
                action="address_objection_with_benefits",
                priority=1,
                description="Traiter les objections en mettant en avant les bénéfices",
                examples=[
                    "Je comprends votre préoccupation. Laissez-moi vous expliquer comment nous résolvons cela.",
                    "C'est effectivement un point important. Voici notre approche..."
                ]
            ),
            ConversationRule(
                condition="closing_opportunity",
                action="suggest_next_steps",
                priority=1,
                description="Proposer les prochaines étapes",
                examples=[
                    "Souhaiteriez-vous que nous programmions une démonstration personnalisée ?",
                    "Quelle serait la meilleure façon de continuer cette discussion ?"
                ]
            )
        ]
        
        templates[ScenarioType.PRESENTATION_CLIENT] = ScenarioTemplate(
            scenario_type=ScenarioType.PRESENTATION_CLIENT,
            name="Présentation Client Professionnel",
            description="Présentation formelle d'Eloquence à un client potentiel",
            conversation_phases=[
                ConversationPhase.ACCUEIL,
                ConversationPhase.IDENTIFICATION_BESOIN,
                ConversationPhase.PRESENTATION_SOLUTION,
                ConversationPhase.GESTION_OBJECTIONS,
                ConversationPhase.CONCLUSION
            ],
            user_profiles=[UserProfile.PROSPECT_CURIEUX, UserProfile.DECISION_MAKER],
            conversation_rules=presentation_rules,
            expected_keywords={
                'accueil': ['bonjour', 'présentation', 'eloquence', 'assistant', 'ia'],
                'identification_besoin': ['besoins', 'défis', 'objectifs', 'amélioration', 'communication'],
                'presentation_solution': ['solution', 'fonctionnalités', 'avantages', 'bénéfices'],
                'gestion_objections': ['cependant', 'mais', 'toutefois', 'préoccupation', 'problème'],
                'conclusion': ['prochaine étape', 'démonstration', 'contact', 'suivi', 'décision']
            },
            success_criteria={
                'min_phases_covered': 4,
                'min_keywords_mentioned': 8,
                'objections_handled_properly': True,
                'next_steps_defined': True
            },
            typical_duration=8.0,
            difficulty_level=3
        )
        
        # SCÉNARIO 2: DÉMONSTRATION COMMERCIALE
        demo_rules = [
            ConversationRule(
                condition="demo_start",
                action="introduce_demo_agenda",
                priority=1,
                description="Présenter l'agenda de la démonstration",
                examples=[
                    "Aujourd'hui, je vais vous montrer les fonctionnalités clés d'Eloquence.",
                    "Commençons par explorer ensemble les capacités de notre solution."
                ]
            ),
            ConversationRule(
                condition="feature_explanation_needed",
                action="explain_with_concrete_examples",
                priority=2,
                description="Expliquer les fonctionnalités avec des exemples concrets",
                examples=[
                    "Par exemple, imaginez que vous préparez une présentation importante...",
                    "Concrètement, voici comment ça fonctionnerait dans votre contexte..."
                ]
            ),
            ConversationRule(
                condition="technical_question_asked",
                action="provide_technical_details",
                priority=2,
                description="Fournir des détails techniques précis",
                examples=[
                    "Techniquement, nous utilisons des algorithmes d'IA avancés pour...",
                    "L'architecture de notre système permet..."
                ]
            ),
            ConversationRule(
                condition="roi_question",
                action="present_value_proposition",
                priority=1,
                description="Présenter la proposition de valeur et le ROI",
                examples=[
                    "En termes de retour sur investissement, nos clients observent...",
                    "La valeur se mesure principalement par..."
                ]
            )
        ]
        
        templates[ScenarioType.COMMERCIAL_DEMO] = ScenarioTemplate(
            scenario_type=ScenarioType.COMMERCIAL_DEMO,
            name="Démonstration Commerciale Interactive",
            description="Démonstration live des fonctionnalités d'Eloquence",
            conversation_phases=[
                ConversationPhase.ACCUEIL,
                ConversationPhase.PRESENTATION_SOLUTION,
                ConversationPhase.GESTION_OBJECTIONS,
                ConversationPhase.NEGOCIATION,
                ConversationPhase.CONCLUSION
            ],
            user_profiles=[UserProfile.TECHNICIEN_SCEPTIQUE, UserProfile.DECISION_MAKER],
            conversation_rules=demo_rules,
            expected_keywords={
                'accueil': ['démonstration', 'présentation', 'fonctionnalités'],
                'presentation_solution': ['exemple', 'utilisation', 'cas pratique', 'avantage'],
                'gestion_objections': ['performance', 'fiabilité', 'intégration', 'coût'],
                'negociation': ['prix', 'tarif', 'investissement', 'budget', 'roi'],
                'conclusion': ['prochaine étape', 'essai', 'pilote', 'déploiement']
            },
            success_criteria={
                'demo_completed': True,
                'technical_questions_answered': True,
                'value_proposition_clear': True,
                'next_meeting_scheduled': True
            },
            typical_duration=15.0,
            difficulty_level=4
        )
        
        # SCÉNARIO 3: NÉGOCIATION PRIX
        negociation_rules = [
            ConversationRule(
                condition="price_objection",
                action="justify_pricing_with_value",
                priority=1,
                description="Justifier le prix par la valeur apportée",
                examples=[
                    "Je comprends que le budget soit une considération importante. Regardons la valeur...",
                    "Le prix reflète la qualité et les résultats que vous obtiendrez..."
                ]
            ),
            ConversationRule(
                condition="competitor_mentioned",
                action="differentiate_from_competition",
                priority=1,
                description="Se différencier de la concurrence",
                examples=[
                    "Ce qui nous distingue de nos concurrents, c'est...",
                    "Contrairement aux autres solutions, Eloquence offre..."
                ]
            ),
            ConversationRule(
                condition="negotiation_request",
                action="explore_flexible_options",
                priority=2,
                description="Explorer des options flexibles",
                examples=[
                    "Nous pouvons étudier différentes formules selon vos besoins...",
                    "Il existe plusieurs façons d'aborder cet investissement..."
                ]
            )
        ]
        
        templates[ScenarioType.NEGOCIATION_PRIX] = ScenarioTemplate(
            scenario_type=ScenarioType.NEGOCIATION_PRIX,
            name="Négociation Tarifaire Stratégique",
            description="Négociation des conditions commerciales et tarifs",
            conversation_phases=[
                ConversationPhase.IDENTIFICATION_BESOIN,
                ConversationPhase.PRESENTATION_SOLUTION,
                ConversationPhase.NEGOCIATION,
                ConversationPhase.CONCLUSION
            ],
            user_profiles=[UserProfile.CLIENT_EXIGEANT, UserProfile.DECISION_MAKER],
            conversation_rules=negociation_rules,
            expected_keywords={
                'identification_besoin': ['budget', 'contraintes', 'priorités'],
                'presentation_solution': ['valeur', 'bénéfices', 'retour sur investissement'],
                'negociation': ['prix', 'remise', 'conditions', 'flexibilité', 'options'],
                'conclusion': ['accord', 'contrat', 'signature', 'engagement']
            },
            success_criteria={
                'price_justified': True,
                'value_demonstrated': True,
                'flexible_options_presented': True,
                'agreement_reached': True
            },
            typical_duration=12.0,
            difficulty_level=5
        )
        
        # SCÉNARIO 4: SUPPORT TECHNIQUE
        support_rules = [
            ConversationRule(
                condition="technical_issue_reported",
                action="gather_detailed_information",
                priority=1,
                description="Collecter des informations détaillées sur le problème",
                examples=[
                    "Pouvez-vous me décrire précisément le problème que vous rencontrez ?",
                    "À quel moment cette erreur se produit-elle ?"
                ]
            ),
            ConversationRule(
                condition="solution_provided",
                action="verify_problem_resolution",
                priority=1,
                description="Vérifier que la solution résout le problème",
                examples=[
                    "Cette solution résout-elle votre problème ?",
                    "Pouvez-vous confirmer que tout fonctionne maintenant ?"
                ]
            )
        ]
        
        templates[ScenarioType.SUPPORT_TECHNIQUE] = ScenarioTemplate(
            scenario_type=ScenarioType.SUPPORT_TECHNIQUE,
            name="Support Technique Spécialisé",
            description="Assistance technique et résolution de problèmes",
            conversation_phases=[
                ConversationPhase.ACCUEIL,
                ConversationPhase.IDENTIFICATION_BESOIN,
                ConversationPhase.PRESENTATION_SOLUTION,
                ConversationPhase.SUIVI
            ],
            user_profiles=[UserProfile.TECHNICIEN_SCEPTIQUE, UserProfile.CLIENT_EXIGEANT],
            conversation_rules=support_rules,
            expected_keywords={
                'accueil': ['problème', 'assistance', 'support', 'aide'],
                'identification_besoin': ['erreur', 'bug', 'dysfonctionnement', 'symptômes'],
                'presentation_solution': ['solution', 'correction', 'procédure', 'étapes'],
                'suivi': ['résolu', 'satisfaction', 'feedback', 'amélioration']
            },
            success_criteria={
                'problem_identified': True,
                'solution_provided': True,
                'customer_satisfied': True,
                'issue_resolved': True
            },
            typical_duration=10.0,
            difficulty_level=3
        )
        
        return templates
    
    def set_scenario(self, scenario_type: ScenarioType, user_profile: UserProfile = None):
        """Définit le scénario actuel"""
        
        if scenario_type in self.scenario_templates:
            self.current_scenario = self.scenario_templates[scenario_type]
            self.current_phase = self.current_scenario.conversation_phases[0]
            
            if user_profile and user_profile in self.current_scenario.user_profiles:
                self.user_profile = user_profile
            else:
                self.user_profile = self.current_scenario.user_profiles[0]
            
            # Réinitialiser le contexte
            self.conversation_context = {
                'mentioned_topics': [],
                'objections_raised': [],
                'positive_signals': [],
                'negotiation_points': [],
                'technical_questions': [],
                'price_discussed': False,
                'demo_requested': False,
                'follow_up_scheduled': False
            }
            
            print(f"Scénario configuré: {self.current_scenario.name}")
            print(f"Profil utilisateur: {self.user_profile.value}")
            print(f"Phase initiale: {self.current_phase.value}")
    
    def generate_contextual_user_message(self, ai_previous_response: str = None) -> Dict[str, Any]:
        """Génère un message utilisateur contextuel selon le scénario"""
        
        if not self.current_scenario:
            raise ValueError("Aucun scénario configuré")
        
        # Analyser la réponse IA précédente si disponible
        context_analysis = self._analyze_ai_response(ai_previous_response) if ai_previous_response else {}
        
        # Déterminer la phase de conversation appropriée
        new_phase = self._determine_conversation_phase(context_analysis)
        if new_phase != self.current_phase:
            self._transition_to_phase(new_phase)
        
        # Générer le message selon le profil utilisateur et la phase
        user_message = self._generate_phase_appropriate_message(context_analysis)
        
        # Mettre à jour le contexte de conversation
        self._update_conversation_context(user_message, context_analysis)
        
        return {
            'text': user_message,
            'conversation_phase': self.current_phase.value,
            'user_profile': self.user_profile.value,
            'scenario_type': self.current_scenario.scenario_type.value,
            'keywords_to_expect': self.current_scenario.expected_keywords.get(
                self.current_phase.value, []
            ),
            'context_metadata': {
                'interaction_quality': self.interaction_quality,
                'user_engagement': self.user_engagement,
                'phase_progression': len(self.phase_progression),
                'conversation_context': self.conversation_context.copy()
            }
        }
    
    def _analyze_ai_response(self, ai_response: str) -> Dict[str, Any]:
        """Analyse la réponse de l'IA pour adapter la suite de conversation"""
        
        analysis = {
            'response_length': len(ai_response.split()) if ai_response else 0,
            'mentions_price': False,
            'asks_questions': False,
            'provides_examples': False,
            'addresses_objections': False,
            'suggests_next_steps': False,
            'technical_content': False,
            'emotional_tone': 'neutral',
            'professionalism_level': 'medium'
        }
        
        if not ai_response:
            return analysis
        
        ai_lower = ai_response.lower()
        
        # Détection de mentions de prix
        price_keywords = ['prix', 'tarif', 'coût', 'budget', 'investissement', 'euro', '€']
        analysis['mentions_price'] = any(keyword in ai_lower for keyword in price_keywords)
        
        # Détection de questions
        analysis['asks_questions'] = '?' in ai_response
        
        # Détection d'exemples
        example_keywords = ['exemple', 'par exemple', 'concrètement', 'imaginez', 'cas pratique']
        analysis['provides_examples'] = any(keyword in ai_lower for keyword in example_keywords)
        
        # Détection de traitement d'objections
        objection_keywords = ['comprendre', 'cependant', 'effectivement', 'préoccupation']
        analysis['addresses_objections'] = any(keyword in ai_lower for keyword in objection_keywords)
        
        # Détection de prochaines étapes
        next_step_keywords = ['prochaine étape', 'suivante', 'program', 'planifi', 'contact', 'démonstration', 'suivi', 'rencontr']
        analysis['suggests_next_steps'] = any(keyword in ai_lower for keyword in next_step_keywords)
        
        # Détection de contenu technique
        tech_keywords = ['algorithme', 'ia', 'technologie', 'intégration', 'api', 'données']
        analysis['technical_content'] = any(keyword in ai_lower for keyword in tech_keywords)
        
        # Analyse du ton émotionnel (basique)
        positive_words = ['excellent', 'parfait', 'idéal', 'fantastique', 'merveilleux']
        negative_words = ['problème', 'difficile', 'impossible', 'malheureusement']
        
        if any(word in ai_lower for word in positive_words):
            analysis['emotional_tone'] = 'positive'
        elif any(word in ai_lower for word in negative_words):
            analysis['emotional_tone'] = 'negative'
        
        # Niveau de professionnalisme
        formal_indicators = ['permettez-moi', 'j\'ai l\'honneur', 'cordialement', 'respectueusement']
        if any(indicator in ai_lower for indicator in formal_indicators):
            analysis['professionalism_level'] = 'high'
        elif any(word in ai_lower for word in ['salut', 'coucou', 'ok', 'cool']):
            analysis['professionalism_level'] = 'low'
        
        return analysis
    
    def _determine_conversation_phase(self, context_analysis: Dict[str, Any]) -> ConversationPhase:
        """Détermine la phase de conversation appropriée"""
        
        current_phase_index = self.current_scenario.conversation_phases.index(self.current_phase)
        
        # Logique de progression de phase selon le contexte
        if context_analysis.get('suggests_next_steps', False):
            # L'IA suggère des prochaines étapes, on peut passer à la conclusion
            conclusion_phases = [ConversationPhase.CONCLUSION, ConversationPhase.SUIVI]
            for phase in conclusion_phases:
                if phase in self.current_scenario.conversation_phases:
                    return phase
        
        if context_analysis.get('mentions_price', False) and not self.conversation_context['price_discussed']:
            # Premier mention de prix, passer à la négociation si disponible
            if ConversationPhase.NEGOCIATION in self.current_scenario.conversation_phases:
                return ConversationPhase.NEGOCIATION
        
        if context_analysis.get('technical_content', False):
            # Contenu technique détecté, rester en présentation solution
            if ConversationPhase.PRESENTATION_SOLUTION in self.current_scenario.conversation_phases:
                return ConversationPhase.PRESENTATION_SOLUTION
        
        if context_analysis.get('addresses_objections', False):
            # L'IA traite des objections
            if ConversationPhase.GESTION_OBJECTIONS in self.current_scenario.conversation_phases:
                return ConversationPhase.GESTION_OBJECTIONS
        
        # Progression naturelle si aucune condition spécifique
        if current_phase_index < len(self.current_scenario.conversation_phases) - 1:
            # Avancer à la phase suivante selon certaines conditions
            if (len(self.phase_progression) >= 2 and 
                random.random() < 0.3):  # 30% de chance d'avancer naturellement
                return self.current_scenario.conversation_phases[current_phase_index + 1]
        
        return self.current_phase  # Rester dans la phase actuelle
    
    def _transition_to_phase(self, new_phase: ConversationPhase):
        """Effectue la transition vers une nouvelle phase"""
        
        old_phase = self.current_phase
        self.current_phase = new_phase
        
        # Enregistrer la transition
        self.phase_progression.append({
            'from_phase': old_phase.value,
            'to_phase': new_phase.value,
            'timestamp': time.time(),
            'trigger': 'context_analysis'
        })
        
        print(f"Transition de phase: {old_phase.value} -> {new_phase.value}")
    
    def _generate_phase_appropriate_message(self, context_analysis: Dict[str, Any]) -> str:
        """Génère un message approprié à la phase et au profil utilisateur"""
        
        # Messages par phase et profil utilisateur
        message_templates = {
            ConversationPhase.ACCUEIL: {
                UserProfile.PROSPECT_CURIEUX: [
                    "Bonjour ! J'ai entendu parler d'Eloquence et j'aimerais en savoir plus.",
                    "Salut, on m'a dit que votre solution pourrait m'intéresser.",
                    "Bonjour, je cherche des informations sur vos services."
                ],
                UserProfile.DECISION_MAKER: [
                    "Bonjour, je souhaite évaluer votre solution pour notre organisation.",
                    "Bonjour, nous étudions différentes options et Eloquence est dans notre short-list.",
                    "Bonjour, pouvez-vous me présenter votre proposition de valeur ?"
                ],
                UserProfile.CLIENT_EXIGEANT: [
                    "Bonjour, j'espère que vous pourrez répondre à toutes mes questions.",
                    "Bonjour, j'ai des attentes précises concernant cette solution.",
                    "Bonjour, je veux être sûr que c'est exactement ce dont j'ai besoin."
                ]
            },
            
            ConversationPhase.IDENTIFICATION_BESOIN: {
                UserProfile.PROSPECT_CURIEUX: [
                    "J'aimerais améliorer ma façon de m'exprimer en public.",
                    "Je cherche quelque chose pour être plus à l'aise à l'oral.",
                    "Comment votre solution peut-elle m'aider concrètement ?"
                ],
                UserProfile.DECISION_MAKER: [
                    "Nous avons besoin d'améliorer les compétences de communication de nos équipes.",
                    "Quel est votre différenciateur par rapport à la concurrence ?",
                    "Quels résultats pouvons-nous attendre de votre solution ?"
                ],
                UserProfile.TECHNICIEN_SCEPTIQUE: [
                    "Comment ça marche techniquement votre solution ?",
                    "Quelles sont les garanties de fiabilité ?",
                    "Est-ce que ça s'intègre facilement avec nos systèmes existants ?"
                ]
            },
            
            ConversationPhase.PRESENTATION_SOLUTION: {
                UserProfile.PROSPECT_CURIEUX: [
                    "C'est intéressant ! Pouvez-vous me donner un exemple concret ?",
                    "Comment ça se passe concrètement une session avec Eloquence ?",
                    "Combien de temps faut-il pour voir des résultats ?"
                ],
                UserProfile.DECISION_MAKER: [
                    "Quels sont les indicateurs de performance que vous mesurez ?",
                    "Quel est le retour sur investissement typique ?",
                    "Avez-vous des études de cas dans notre secteur ?"
                ],
                UserProfile.TECHNICIEN_SCEPTIQUE: [
                    "L'IA est-elle vraiment fiable pour évaluer la communication ?",
                    "Quelles données collectez-vous et comment les protégez-vous ?",
                    "Y a-t-il des limitations techniques que je devrais connaître ?"
                ]
            },
            
            ConversationPhase.GESTION_OBJECTIONS: {
                UserProfile.CLIENT_EXIGEANT: [
                    "Je ne suis pas convaincu que ça marche vraiment.",
                    "C'est plus cher que ce que j'avais prévu.",
                    "J'ai peur que ce soit trop compliqué à utiliser."
                ],
                UserProfile.TECHNICIEN_SCEPTIQUE: [
                    "L'IA ne peut pas remplacer un vrai formateur, non ?",
                    "Comment être sûr que l'évaluation est objective ?",
                    "Et si ça ne marche pas avec notre accent régional ?"
                ],
                UserProfile.DECISION_MAKER: [
                    "Le budget est serré cette année.",
                    "Il faut que je justifie cet investissement auprès de ma hiérarchie.",
                    "Vos concurrents proposent des prix plus attractifs."
                ]
            },
            
            ConversationPhase.NEGOCIATION: {
                UserProfile.CLIENT_EXIGEANT: [
                    "Il faut qu'on parle du prix, là.",
                    "Y a-t-il une possibilité de remise ?",
                    "Pouvez-vous faire un geste commercial ?"
                ],
                UserProfile.DECISION_MAKER: [
                    "Quelles options de financement proposez-vous ?",
                    "Peut-on commencer par un pilote plus petit ?",
                    "Quelles sont vos conditions de paiement ?"
                ],
                UserProfile.COMMERCIAL_PRESSE: [
                    "J'ai besoin d'une réponse aujourd'hui.",
                    "Mon budget est de X euros, pas plus.",
                    "La concurrence me propose 20% moins cher."
                ]
            },
            
            ConversationPhase.CONCLUSION: {
                UserProfile.PROSPECT_CURIEUX: [
                    "Ça me paraît intéressant, quelle est la suite ?",
                    "Comment on procède pour commencer ?",
                    "J'aimerais bien tester avant de m'engager."
                ],
                UserProfile.DECISION_MAKER: [
                    "Quelles sont les prochaines étapes du processus ?",
                    "Quand pourrions-nous commencer le déploiement ?",
                    "Pouvez-vous me préparer une proposition formelle ?"
                ],
                UserProfile.CLIENT_EXIGEANT: [
                    "Je veux être sûr des conditions avant de signer.",
                    "Il me faut toutes les garanties par écrit.",
                    "Quels sont exactement mes engagements ?"
                ]
            }
        }
        
        # Récupérer les templates pour la phase et le profil actuels
        phase_templates = message_templates.get(self.current_phase, {})
        user_templates = phase_templates.get(self.user_profile, [])
        
        if not user_templates:
            # Fallback vers d'autres profils si pas de template spécifique
            for profile in phase_templates:
                if phase_templates[profile]:
                    user_templates = phase_templates[profile]
                    break
        
        if not user_templates:
            # Fallback générique
            return f"Pouvez-vous m'en dire plus sur {self.current_scenario.scenario_type.value} ?"
        
        # Sélectionner un template aléatoire
        selected_template = random.choice(user_templates)
        
        # Ajouter des variations contextuelle selon l'analyse IA
        if context_analysis.get('mentions_price', False) and 'prix' not in selected_template.lower():
            if random.random() < 0.4:  # 40% de chance d'ajouter une mention prix
                price_additions = [
                    " Et concernant le prix ?",
                    " Quel est votre tarif ?",
                    " Parlons budget maintenant."
                ]
                selected_template += random.choice(price_additions)
        
        if context_analysis.get('technical_content', False) and self.user_profile == UserProfile.TECHNICIEN_SCEPTIQUE:
            if random.random() < 0.3:  # 30% de chance d'ajouter une question technique
                tech_additions = [
                    " Comment ça marche exactement ?",
                    " C'est sécurisé au moins ?",
                    " Ça consomme beaucoup de ressources ?"
                ]
                selected_template += random.choice(tech_additions)
        
        return selected_template
    
    def _update_conversation_context(self, user_message: str, context_analysis: Dict[str, Any]):
        """Met à jour le contexte de conversation"""
        
        user_lower = user_message.lower()
        
        # Identifier les topics mentionnés
        topic_keywords = {
            'price': ['prix', 'tarif', 'coût', 'budget'],
            'technical': ['technique', 'technologie', 'intégration', 'api'],
            'results': ['résultats', 'performance', 'efficacité', 'roi'],
            'demo': ['démonstration', 'demo', 'test', 'essai'],
            'support': ['support', 'aide', 'assistance', 'formation']
        }
        
        for topic, keywords in topic_keywords.items():
            if any(keyword in user_lower for keyword in keywords):
                if topic not in self.conversation_context['mentioned_topics']:
                    self.conversation_context['mentioned_topics'].append(topic)
        
        # Détecter les objections
        objection_indicators = ['mais', 'cependant', 'problème', 'préoccupation', 'inquiétude']
        if any(indicator in user_lower for indicator in objection_indicators):
            self.conversation_context['objections_raised'].append(user_message)
        
        # Détecter les signaux positifs
        positive_indicators = ['intéressant', 'bien', 'parfait', 'excellent', 'génial']
        if any(indicator in user_lower for indicator in positive_indicators):
            self.conversation_context['positive_signals'].append(user_message)
        
        # Mettre à jour les flags spécifiques
        if any(keyword in user_lower for keyword in ['prix', 'tarif', 'coût']):
            self.conversation_context['price_discussed'] = True
        
        if any(keyword in user_lower for keyword in ['démonstration', 'demo', 'test']):
            self.conversation_context['demo_requested'] = True
        
        # Calculer la qualité d'interaction (simplifié)
        self.interaction_quality = min(1.0, self.interaction_quality + 0.1)
        
        # Calculer l'engagement utilisateur
        engagement_indicators = len(self.conversation_context['mentioned_topics']) * 0.1
        engagement_indicators += len(self.conversation_context['positive_signals']) * 0.15
        engagement_indicators -= len(self.conversation_context['objections_raised']) * 0.05
        
        self.user_engagement = max(0.0, min(1.0, 0.5 + engagement_indicators))
    
    def get_scenario_metrics(self) -> Dict[str, Any]:
        """Retourne les métriques du scénario actuel"""
        
        if not self.current_scenario:
            return {'error': 'no_scenario_active'}
        
        # Calculer la progression
        total_phases = len(self.current_scenario.conversation_phases)
        completed_phases = len(set(transition['to_phase'] for transition in self.phase_progression))
        progression_percentage = completed_phases / total_phases if total_phases > 0 else 0
        
        # Vérifier les critères de succès
        success_criteria_met = self._evaluate_success_criteria()
        
        return {
            'scenario_name': self.current_scenario.name,
            'scenario_type': self.current_scenario.scenario_type.value,
            'current_phase': self.current_phase.value,
            'user_profile': self.user_profile.value,
            'progression_percentage': progression_percentage,
            'phases_completed': completed_phases,
            'total_phases': total_phases,
            'interaction_quality': self.interaction_quality,
            'user_engagement': self.user_engagement,
            'conversation_context': self.conversation_context.copy(),
            'phase_transitions': self.phase_progression.copy(),
            'success_criteria_met': success_criteria_met,
            'expected_duration': self.current_scenario.typical_duration,
            'difficulty_level': self.current_scenario.difficulty_level
        }
    
    def _evaluate_success_criteria(self) -> Dict[str, bool]:
        """Évalue les critères de succès du scénario"""
        
        if not self.current_scenario:
            return {}
        
        criteria_results = {}
        
        for criterion, expected_value in self.current_scenario.success_criteria.items():
            if criterion == 'min_phases_covered':
                phases_covered = len(set(t['to_phase'] for t in self.phase_progression))
                criteria_results[criterion] = phases_covered >= expected_value
            
            elif criterion == 'min_keywords_mentioned':
                topics_mentioned = len(self.conversation_context['mentioned_topics'])
                criteria_results[criterion] = topics_mentioned >= expected_value
            
            elif criterion == 'objections_handled_properly':
                # Simplifié: si des objections ont été soulevées et que la conversation continue positivement
                has_objections = len(self.conversation_context['objections_raised']) > 0
                has_positive_signals = len(self.conversation_context['positive_signals']) > 0
                criteria_results[criterion] = not has_objections or has_positive_signals
            
            elif criterion == 'next_steps_defined':
                # Si on a atteint la phase de conclusion
                criteria_results[criterion] = self.current_phase in [ConversationPhase.CONCLUSION, ConversationPhase.SUIVI]
            
            elif criterion == 'price_justified':
                criteria_results[criterion] = self.conversation_context['price_discussed']
            
            elif criterion == 'demo_completed':
                criteria_results[criterion] = self.conversation_context['demo_requested']
            
            else:
                # Pour d'autres critères, on assume qu'ils sont remplis
                criteria_results[criterion] = True
        
        return criteria_results

# Fonction utilitaire pour tester les scénarios
def test_scenario_dynamics():
    """Teste le système de dynamiques conversationnelles"""
    
    print("Test des Scénarios Adaptatifs")
    print("=" * 40)
    
    # Créer le gestionnaire de dynamiques
    dynamics = ConversationDynamics()
    
    # Tester différents scénarios
    scenarios_to_test = [
        (ScenarioType.PRESENTATION_CLIENT, UserProfile.PROSPECT_CURIEUX),
        (ScenarioType.COMMERCIAL_DEMO, UserProfile.TECHNICIEN_SCEPTIQUE),
        (ScenarioType.NEGOCIATION_PRIX, UserProfile.CLIENT_EXIGEANT)
    ]
    
    for scenario_type, user_profile in scenarios_to_test:
        print(f"\n--- Test: {scenario_type.value} avec {user_profile.value} ---")
        
        # Configurer le scénario
        dynamics.set_scenario(scenario_type, user_profile)
        
        # Simuler 3-4 échanges
        ai_response = None
        for i in range(4):
            user_message_data = dynamics.generate_contextual_user_message(ai_response)
            
            print(f"\nÉchange {i+1}:")
            print(f"Phase: {user_message_data['conversation_phase']}")
            print(f"Message: {user_message_data['text']}")
            print(f"Mots-clés attendus: {user_message_data['keywords_to_expect']}")
            
            # Simuler une réponse IA basique
            ai_responses = [
                "Merci pour votre question. Effectivement, notre solution peut vous aider.",
                "C'est une excellente remarque. Laissez-moi vous expliquer concrètement.",
                "Je comprends votre préoccupation concernant le prix. La valeur est là.",
                "Parfait ! Quelle serait la prochaine étape selon vous ?"
            ]
            ai_response = ai_responses[i % len(ai_responses)]
        
        # Métriques finales
        metrics = dynamics.get_scenario_metrics()
        print(f"\nMétriques finales:")
        print(f"Progression: {metrics['progression_percentage']:.1%}")
        print(f"Engagement: {metrics['user_engagement']:.1f}")
        print(f"Qualité: {metrics['interaction_quality']:.1f}")
        print(f"Topics mentionnés: {metrics['conversation_context']['mentioned_topics']}")

if __name__ == "__main__":
    test_scenario_dynamics()