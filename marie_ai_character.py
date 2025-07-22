#!/usr/bin/env python3
"""
Marie AI Character - Personnalité de Directrice Commerciale Exigeante
Définit les caractéristiques comportementales et conversationnelles de Marie
"""

import random
import time
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from enum import Enum

class MariePersonalityTrait(Enum):
    """Traits de personnalité de Marie"""
    EXIGEANTE = "exigeante"
    PROFESSIONNELLE = "professionnelle"
    DIRECTE = "directe"
    ORIENTEE_RESULTATS = "orientee_resultats"
    ANALYTIQUE = "analytique"
    IMPATIENTE = "impatiente"
    PRAGMATIQUE = "pragmatique"

class MarieConversationMode(Enum):
    """Modes conversationnels de Marie"""
    EVALUATION_INITIALE = "evaluation_initiale"
    QUESTIONNEMENT_APPROFONDI = "questionnement_approfondi"
    OBJECTION_CHALLENGER = "objection_challenger"
    NEGOCIATION_FERME = "negociation_ferme"
    VALIDATION_FINALE = "validation_finale"
    CLÔTURE_DECISION = "cloture_decision"

@dataclass
class MarieResponsePattern:
    """Modèle de réponse de Marie"""
    mode: MarieConversationMode
    traits_actifs: List[MariePersonalityTrait]
    templates: List[str]
    questions_types: List[str]
    objections_possibles: List[str]
    seuil_satisfaction: float

class MarieAICharacter:
    """Personnalité IA de Marie - Directrice Commerciale Exigeante"""
    
    def __init__(self):
        self.nom = "Marie"
        self.role = "Directrice Commerciale"
        self.company = "TechCorp Solutions"
        self.experience_years = 15
        
        # État conversationnel
        self.current_mode = MarieConversationMode.EVALUATION_INITIALE
        self.patience_level = 0.8  # Démarre patiente, baisse avec le temps
        self.satisfaction_level = 0.5  # Neutre au début
        self.interest_level = 0.3  # Faible au début, doit être conquise
        
        # Compteurs comportementaux
        self.questions_asked = 0
        self.objections_raised = 0
        self.conversation_turn = 0
        self.total_conversation_time = 0.0
        
        # Patterns de réponse par mode
        self.response_patterns = self._initialize_response_patterns()
        
        # Historique conversationnel pour adaptation
        self.conversation_history = []
        self.key_topics_mentioned = set()
        self.pain_points_identified = []
        
    def _initialize_response_patterns(self) -> Dict[MarieConversationMode, MarieResponsePattern]:
        """Initialise les patterns de réponse pour chaque mode"""
        
        return {
            MarieConversationMode.EVALUATION_INITIALE: MarieResponsePattern(
                mode=MarieConversationMode.EVALUATION_INITIALE,
                traits_actifs=[MariePersonalityTrait.PROFESSIONNELLE, MariePersonalityTrait.ANALYTIQUE],
                templates=[
                    "Je vous écoute. Présentez-moi votre solution en quelques mots.",
                    "D'accord, mais soyez précis. Mon temps est limité.",
                    "Bien. Expliquez-moi concrètement comment votre produit résout mes problèmes.",
                    "Interessant. Donnez-moi des chiffres et des exemples concrets.",
                    "Je vois. Mais qu'est-ce qui vous différencie vraiment de la concurrence ?"
                ],
                questions_types=[
                    "quel est le ROI exact ?",
                    "combien de temps pour la mise en œuvre ?",
                    "quelles garanties offrez-vous ?",
                    "qui sont vos références dans mon secteur ?"
                ],
                objections_possibles=[
                    "C'est plus cher que prévu",
                    "Timeline trop longue pour nous",
                    "J'ai des doutes sur la fiabilité"
                ],
                seuil_satisfaction=0.4
            ),
            
            MarieConversationMode.QUESTIONNEMENT_APPROFONDI: MarieResponsePattern(
                mode=MarieConversationMode.QUESTIONNEMENT_APPROFONDI,
                traits_actifs=[MariePersonalityTrait.EXIGEANTE, MariePersonalityTrait.ANALYTIQUE],
                templates=[
                    "Rentrons dans les détails. Comment gérez-vous [point_specifique] ?",
                    "Je ne suis pas convaincue. Prouvez-moi que [affirmation] est vraie.",
                    "Vos concurrents disent la même chose. Qu'avez-vous de différent ?",
                    "Les chiffres que vous donnez me semblent optimistes. D'où viennent-ils ?",
                    "Et si [scenario_probleme] arrive ? Comment réagissez-vous ?"
                ],
                questions_types=[
                    "quel est votre SLA réel ?",
                    "comment mesurez-vous le succès ?",
                    "qui dans votre équipe gère notre dossier ?",
                    "quelle est votre politique en cas de problème ?"
                ],
                objections_possibles=[
                    "Vos références ne sont pas dans mon secteur",
                    "Je doute de vos capacités de support",
                    "Votre équipe semble trop junior"
                ],
                seuil_satisfaction=0.6
            ),
            
            MarieConversationMode.OBJECTION_CHALLENGER: MarieResponsePattern(
                mode=MarieConversationMode.OBJECTION_CHALLENGER,
                traits_actifs=[MariePersonalityTrait.DIRECTE, MariePersonalityTrait.IMPATIENTE],
                templates=[
                    "Attendez. J'ai un problème avec ce que vous venez de dire.",
                    "Non, ce n'est pas acceptable. Nous avons besoin de [exigence_specifique].",
                    "Votre concurrent propose mieux à moins cher. Justifiez votre prix.",
                    "Je ne peux pas présenter ça à mon board. Il faut revoir votre approche.",
                    "Sincèrement, je suis déçue. J'attendais plus de votre solution."
                ],
                questions_types=[
                    "comment justifiez-vous ce surcoût ?",
                    "pouvez-vous faire un geste commercial ?",
                    "que se passe-t-il si ça ne marche pas ?",
                    "pourquoi devrais-je vous faire confiance ?"
                ],
                objections_possibles=[
                    "Budget insuffisant pour cette solution",
                    "Risque trop élevé pour notre organisation",
                    "Timing incompatible avec nos priorités"
                ],
                seuil_satisfaction=0.3
            ),
            
            MarieConversationMode.NEGOCIATION_FERME: MarieResponsePattern(
                mode=MarieConversationMode.NEGOCIATION_FERME,
                traits_actifs=[MariePersonalityTrait.PRAGMATIQUE, MariePersonalityTrait.ORIENTEE_RESULTATS],
                templates=[
                    "Bon, parlons business. Quel est votre dernier prix ?",
                    "Je peux aller jusqu'à [montant]. C'est à prendre ou à laisser.",
                    "Vos conditions ne sont pas acceptables. Voici ce que je propose.",
                    "Il faut qu'on trouve un terrain d'entente. Que pouvez-vous faire ?",
                    "D'accord, mais j'ai des conditions non négociables."
                ],
                questions_types=[
                    "quelle est votre marge de manœuvre ?",
                    "pouvez-vous échelonner les paiements ?",
                    "que comprend exactement cette offre ?",
                    "quand puis-je avoir le contrat ?"
                ],
                objections_possibles=[
                    "Prix encore trop élevé malgré l'effort",
                    "Délais de livraison inacceptables",
                    "Conditions contractuelles trop rigides"
                ],
                seuil_satisfaction=0.7
            ),
            
            MarieConversationMode.VALIDATION_FINALE: MarieResponsePattern(
                mode=MarieConversationMode.VALIDATION_FINALE,
                traits_actifs=[MariePersonalityTrait.PROFESSIONNELLE, MariePersonalityTrait.ANALYTIQUE],
                templates=[
                    "Bien. Récapitulons ce qu'on a convenu.",
                    "Votre proposition me semble acceptable. Quelques points à clarifier.",
                    "Je pense qu'on peut avancer. Envoyez-moi le détail par écrit.",
                    "C'est plus raisonnable. Je vais présenter ça à mon équipe.",
                    "OK, vous m'avez convaincue sur l'essentiel."
                ],
                questions_types=[
                    "quand puis-je avoir la proposition formelle ?",
                    "qui signe le contrat côté fournisseur ?",
                    "quelle est la prochaine étape ?",
                    "quand pouvons-nous démarrer ?"
                ],
                objections_possibles=[
                    "Il me faut l'aval de ma direction",
                    "Quelques détails à ajuster encore",
                    "Timeline de démarrage à confirmer"
                ],
                seuil_satisfaction=0.8
            ),
            
            MarieConversationMode.CLÔTURE_DECISION: MarieResponsePattern(
                mode=MarieConversationMode.CLÔTURE_DECISION,
                traits_actifs=[MariePersonalityTrait.ORIENTEE_RESULTATS, MariePersonalityTrait.DIRECTE],
                templates=[
                    "Parfait. Nous avons un accord. Préparez les documents.",
                    "C'est décidé. Nous travaillons ensemble. Merci pour cette présentation.",
                    "Excellent travail. Vous avez su répondre à mes attentes.",
                    "Malheureusement, nous n'irons pas plus loin. Merci pour votre temps.",
                    "Je vais y réfléchir et vous recontacterai la semaine prochaine."
                ],
                questions_types=[
                    "quand livrez-vous ?",
                    "qui est mon interlocuteur principal ?",
                    "comment suit-on l'avancement ?",
                    "quand faisons-nous le point ?"
                ],
                objections_possibles=[
                    "Décision finale reportée",
                    "Choix d'un autre fournisseur",
                    "Validation d'un projet simplifié"
                ],
                seuil_satisfaction=0.9
            )
        }
    
    def analyze_user_input(self, user_input: str, conversation_context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyse l'input utilisateur et détermine la réaction de Marie"""
        
        # Mettre à jour les compteurs
        self.conversation_turn += 1
        self.total_conversation_time = conversation_context.get('total_time', 0)
        
        # Analyser le contenu
        analysis = {
            'input_length': len(user_input.split()),
            'contains_numbers': any(char.isdigit() for char in user_input),
            'mentions_price': any(word in user_input.lower() for word in ['prix', 'coût', 'tarif', 'euro', '€']),
            'mentions_timeline': any(word in user_input.lower() for word in ['délai', 'temps', 'durée', 'planning']),
            'mentions_roi': any(word in user_input.lower() for word in ['roi', 'retour', 'investissement', 'rentabilité']),
            'mentions_guarantee': any(word in user_input.lower() for word in ['garantie', 'assurance', 'sécurité']),
            'confidence_level': self._estimate_confidence_level(user_input),
            'technical_depth': self._estimate_technical_depth(user_input)
        }
        
        # Déterminer l'évolution des niveaux de Marie
        self._update_marie_levels(analysis, user_input)
        
        # Ajouter à l'historique
        self.conversation_history.append({
            'turn': self.conversation_turn,
            'user_input': user_input,
            'analysis': analysis,
            'marie_state': {
                'mode': self.current_mode.value,
                'patience': self.patience_level,
                'satisfaction': self.satisfaction_level,
                'interest': self.interest_level
            }
        })
        
        return analysis
    
    def generate_marie_response(self, user_input: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Génère une réponse contextuelle de Marie"""
        
        current_pattern = self.response_patterns[self.current_mode]
        
        # Choisir un template en fonction du contexte
        response_template = self._select_response_template(current_pattern, analysis)
        
        # Personnaliser la réponse
        marie_response = self._personalize_response(response_template, user_input, analysis)
        
        # Générer une question ou objection si nécessaire
        follow_up = self._generate_follow_up(current_pattern, analysis)
        
        # Mettre à jour le mode conversationnel
        new_mode = self._determine_next_mode(analysis)
        if new_mode != self.current_mode:
            self.current_mode = new_mode
        
        return {
            'response': marie_response,
            'follow_up_question': follow_up.get('question', ''),
            'follow_up_type': follow_up.get('type', 'none'),
            'conversation_mode': self.current_mode.value,
            'marie_satisfaction': self.satisfaction_level,
            'marie_interest': self.interest_level,
            'marie_patience': self.patience_level,
            'traits_actifs': [trait.value for trait in current_pattern.traits_actifs],
            'response_metadata': {
                'response_length': len(marie_response.split()),
                'includes_objection': follow_up.get('type') == 'objection',
                'includes_question': follow_up.get('type') == 'question',
                'conversation_progression': self._evaluate_conversation_progression()
            }
        }
    
    def _estimate_confidence_level(self, user_input: str) -> float:
        """Estime le niveau de confiance de l'utilisateur"""
        
        confidence_indicators = {
            'high': ['certain', 'sûr', 'garanti', 'définitivement', 'absolument', 'parfaitement'],
            'medium': ['probablement', 'vraisemblablement', 'généralement', 'souvent'],
            'low': ['peut-être', 'possiblement', 'éventuellement', 'j\'espère', 'on va voir']
        }
        
        text_lower = user_input.lower()
        
        high_count = sum(1 for word in confidence_indicators['high'] if word in text_lower)
        medium_count = sum(1 for word in confidence_indicators['medium'] if word in text_lower)
        low_count = sum(1 for word in confidence_indicators['low'] if word in text_lower)
        
        if high_count > 0:
            return 0.8 + (high_count * 0.05)
        elif medium_count > 0:
            return 0.6 + (medium_count * 0.05)
        elif low_count > 0:
            return 0.3 - (low_count * 0.05)
        else:
            return 0.5  # Neutre
    
    def _estimate_technical_depth(self, user_input: str) -> float:
        """Estime la profondeur technique du discours"""
        
        technical_terms = [
            'api', 'intégration', 'architecture', 'scalabilité', 'performance', 
            'sécurité', 'encryption', 'protocol', 'infrastructure', 'cloud',
            'analytics', 'dashboard', 'metrics', 'monitoring', 'compliance'
        ]
        
        text_lower = user_input.lower()
        technical_count = sum(1 for term in technical_terms if term in text_lower)
        
        # Normaliser sur la longueur du texte
        word_count = len(user_input.split())
        if word_count > 0:
            return min(1.0, technical_count / word_count * 5)
        return 0.0
    
    def _update_marie_levels(self, analysis: Dict[str, Any], user_input: str):
        """Met à jour les niveaux de patience, satisfaction et intérêt de Marie"""
        
        # Patience diminue avec le temps et les réponses vagues
        time_factor = min(0.1, self.total_conversation_time / 300)  # Max -0.1 après 5 minutes
        vague_penalty = 0.05 if analysis['input_length'] < 5 else 0
        self.patience_level = max(0.1, self.patience_level - time_factor - vague_penalty)
        
        # Satisfaction augmente avec des réponses précises et des données
        precision_bonus = 0.1 if analysis['contains_numbers'] else 0
        content_bonus = 0.05 if analysis['input_length'] > 10 else 0
        relevant_bonus = 0.1 if (analysis['mentions_price'] or analysis['mentions_roi']) else 0
        
        self.satisfaction_level = min(1.0, self.satisfaction_level + precision_bonus + content_bonus + relevant_bonus)
        
        # Intérêt augmente avec la profondeur technique et la confiance
        tech_bonus = analysis['technical_depth'] * 0.15
        confidence_bonus = analysis['confidence_level'] * 0.1
        
        self.interest_level = min(1.0, self.interest_level + tech_bonus + confidence_bonus)
        
        # Malus si Marie n'est pas satisfaite depuis trop longtemps
        if self.satisfaction_level < 0.4 and self.conversation_turn > 3:
            self.interest_level = max(0.1, self.interest_level - 0.05)
    
    def _select_response_template(self, pattern: MarieResponsePattern, analysis: Dict[str, Any]) -> str:
        """Sélectionne le template de réponse approprié"""
        
        # Logique de sélection basée sur l'analyse et l'état de Marie
        if self.satisfaction_level < 0.4:
            # Marie est insatisfaite, réponse plus directe
            templates = [t for t in pattern.templates if any(word in t.lower() for word in ['non', 'problème', 'attendez'])]
        elif self.interest_level > 0.7:
            # Marie est intéressée, réponse plus engageante
            templates = [t for t in pattern.templates if any(word in t.lower() for word in ['bien', 'interessant', 'parfait'])]
        else:
            templates = pattern.templates
        
        return random.choice(templates if templates else pattern.templates)
    
    def _personalize_response(self, template: str, user_input: str, analysis: Dict[str, Any]) -> str:
        """Personnalise la réponse avec des éléments contextuels"""
        
        response = template
        
        # Remplacer les placeholders dynamiques
        if '[point_specifique]' in response:
            specific_points = ['la sécurité', 'la performance', 'le support', 'la formation']
            response = response.replace('[point_specifique]', random.choice(specific_points))
        
        if '[affirmation]' in response:
            response = response.replace('[affirmation]', 'votre solution est la meilleure')
        
        if '[scenario_probleme]' in response:
            problems = ['le serveur tombe en panne', 'vous changez de stratégie', 'nous avons un pic de charge']
            response = response.replace('[scenario_probleme]', random.choice(problems))
        
        if '[exigence_specifique]' in response:
            requirements = ['une garantie 99.9%', 'un support 24/7', 'une formation complète']
            response = response.replace('[exigence_specifique]', random.choice(requirements))
        
        if '[montant]' in response:
            budget_ranges = ['50 000€', '75 000€', '100 000€']
            response = response.replace('[montant]', random.choice(budget_ranges))
        
        return response
    
    def _generate_follow_up(self, pattern: MarieResponsePattern, analysis: Dict[str, Any]) -> Dict[str, str]:
        """Génère une question de suivi ou objection"""
        
        # Probabilité de question basée sur le mode et l'état de Marie
        question_probability = 0.6 if self.interest_level > 0.5 else 0.3
        objection_probability = 0.4 if self.satisfaction_level < 0.4 else 0.1
        
        if random.random() < objection_probability:
            objection = random.choice(pattern.objections_possibles)
            return {'type': 'objection', 'question': objection}
        elif random.random() < question_probability:
            question = random.choice(pattern.questions_types)
            return {'type': 'question', 'question': question}
        else:
            return {'type': 'none', 'question': ''}
    
    def _determine_next_mode(self, analysis: Dict[str, Any]) -> MarieConversationMode:
        """Détermine le prochain mode conversationnel"""
        
        current_satisfaction = self.satisfaction_level
        current_interest = self.interest_level
        
        # Progression basée sur satisfaction et intérêt
        if self.current_mode == MarieConversationMode.EVALUATION_INITIALE:
            if current_interest > 0.5:
                return MarieConversationMode.QUESTIONNEMENT_APPROFONDI
            elif current_satisfaction < 0.3:
                return MarieConversationMode.OBJECTION_CHALLENGER
                
        elif self.current_mode == MarieConversationMode.QUESTIONNEMENT_APPROFONDI:
            if current_satisfaction > 0.7:
                return MarieConversationMode.NEGOCIATION_FERME
            elif current_satisfaction < 0.4:
                return MarieConversationMode.OBJECTION_CHALLENGER
                
        elif self.current_mode == MarieConversationMode.OBJECTION_CHALLENGER:
            if current_satisfaction > 0.6:
                return MarieConversationMode.QUESTIONNEMENT_APPROFONDI
            elif self.conversation_turn > 6:
                return MarieConversationMode.CLÔTURE_DECISION
                
        elif self.current_mode == MarieConversationMode.NEGOCIATION_FERME:
            if current_satisfaction > 0.8:
                return MarieConversationMode.VALIDATION_FINALE
            elif current_satisfaction < 0.5:
                return MarieConversationMode.OBJECTION_CHALLENGER
                
        elif self.current_mode == MarieConversationMode.VALIDATION_FINALE:
            if current_satisfaction > 0.85 or self.conversation_turn > 8:
                return MarieConversationMode.CLÔTURE_DECISION
        
        return self.current_mode
    
    def _evaluate_conversation_progression(self) -> str:
        """Évalue la progression de la conversation"""
        
        if self.satisfaction_level > 0.8 and self.interest_level > 0.7:
            return "excellente"
        elif self.satisfaction_level > 0.6 and self.interest_level > 0.5:
            return "bonne"
        elif self.satisfaction_level > 0.4:
            return "acceptable"
        else:
            return "problématique"
    
    def get_marie_state_summary(self) -> Dict[str, Any]:
        """Retourne un résumé de l'état actuel de Marie"""
        
        return {
            'marie_profile': {
                'nom': self.nom,
                'role': self.role,
                'company': self.company,
                'experience_years': self.experience_years
            },
            'conversation_state': {
                'mode_actuel': self.current_mode.value,
                'tour_conversation': self.conversation_turn,
                'temps_total': self.total_conversation_time,
                'patience_level': round(self.patience_level, 2),
                'satisfaction_level': round(self.satisfaction_level, 2),
                'interest_level': round(self.interest_level, 2)
            },
            'behavioral_counters': {
                'questions_posees': self.questions_asked,
                'objections_soulevees': self.objections_raised,
                'sujets_cles_mentionnes': len(self.key_topics_mentioned),
                'points_douleur_identifies': len(self.pain_points_identified)
            },
            'conversation_quality': {
                'progression': self._evaluate_conversation_progression(),
                'traits_dominants': [trait.value for trait in self.response_patterns[self.current_mode].traits_actifs],
                'prochaine_etape_probable': self._determine_next_mode({}).value
            }
        }
    
    def reset_conversation(self):
        """Remet à zéro l'état conversationnel pour une nouvelle conversation"""
        
        self.current_mode = MarieConversationMode.EVALUATION_INITIALE
        self.patience_level = 0.8
        self.satisfaction_level = 0.5
        self.interest_level = 0.3
        
        self.questions_asked = 0
        self.objections_raised = 0
        self.conversation_turn = 0
        self.total_conversation_time = 0.0
        
        self.conversation_history = []
        self.key_topics_mentioned = set()
        self.pain_points_identified = []

# Instance globale de Marie pour utilisation dans le système
marie_character = MarieAICharacter()

if __name__ == "__main__":
    # Test des fonctionnalités de Marie
    print("Test de la personnalité Marie AI Character")
    print("=" * 50)
    
    marie = MarieAICharacter()
    
    # Simuler quelques échanges
    test_inputs = [
        "Bonjour Marie, je viens vous présenter notre solution CRM innovante.",
        "Notre produit offre un ROI de 300% en 6 mois avec une garantie de performance.",
        "Nous avons déjà équipé 500+ entreprises similaires à la vôtre.",
        "Le prix est de 75 000€ pour la première année, tout inclus."
    ]
    
    for i, user_input in enumerate(test_inputs, 1):
        print(f"\n--- Échange {i} ---")
        print(f"Utilisateur: {user_input}")
        
        # Analyser l'input
        analysis = marie.analyze_user_input(user_input, {'total_time': i * 30})
        
        # Générer la réponse de Marie
        response_data = marie.generate_marie_response(user_input, analysis)
        
        print(f"Marie: {response_data['response']}")
        if response_data['follow_up_question']:
            print(f"Marie (suivi): {response_data['follow_up_question']}")
        
        print(f"Mode: {response_data['conversation_mode']}")
        print(f"Satisfaction: {response_data['marie_satisfaction']:.2f}")
        print(f"Intérêt: {response_data['marie_interest']:.2f}")
    
    # Afficher le résumé final
    print("\n--- Résumé Final ---")
    summary = marie.get_marie_state_summary()
    print(f"Progression: {summary['conversation_quality']['progression']}")
    print(f"Mode final: {summary['conversation_state']['mode_actuel']}")
    print(f"Échanges: {summary['conversation_state']['tour_conversation']}")