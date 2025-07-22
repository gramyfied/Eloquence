#!/usr/bin/env python3
"""
Conversation Quality Analyzer - Analyse qualité réponses Marie en temps réel

Ce module analyse la qualité des réponses de Marie en temps réel, vérifie leur cohérence
avec sa personnalité de directrice commerciale exigeante, détecte les dérives conversationnelles
et déclenche des corrections automatiques pour maintenir l'authenticité et la pertinence
de ses interactions.

Fonctionnalités principales :
- Analyse sémantique et contextuelle des réponses Marie
- Vérification cohérence personnalité et mode conversationnel
- Détection dérives comportementales et incohérences
- Scoring qualité multidimensionnel temps réel
- Déclenchement auto-corrections via prompts adaptatifs
- Métriques qualité conversationnelle détaillées
- Recommandations optimisation personnalité Marie

Dimensions d'analyse :
- Pertinence contextuelle par phase conversation
- Cohérence traits personnalité Marie
- Adéquation registre linguistique professionnel
- Progression logique argumentation commerciale
- Authenticité réactions émotionnelles Marie
- Efficacité persuasion et impact commercial
"""

import re
import logging
import asyncio
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum
import json
import statistics
from collections import deque, defaultdict
import nltk
from textblob import TextBlob

# Pour analyse sémantique avancée
try:
    from sentence_transformers import SentenceTransformer
    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False
    
class QualityDimension(Enum):
    """Dimensions d'analyse qualité"""
    CONTEXTUAL_RELEVANCE = "contextual_relevance"
    PERSONALITY_COHERENCE = "personality_coherence"
    PROFESSIONAL_REGISTER = "professional_register"
    COMMERCIAL_IMPACT = "commercial_impact"
    EMOTIONAL_AUTHENTICITY = "emotional_authenticity"
    LOGICAL_PROGRESSION = "logical_progression"
    LANGUAGE_QUALITY = "language_quality"
    ENGAGEMENT_LEVEL = "engagement_level"

class QualityConcern(Enum):
    """Types de préoccupations qualité"""
    PERSONALITY_DRIFT = "personality_drift"
    CONTEXT_MISMATCH = "context_mismatch"
    UNPROFESSIONAL_TONE = "unprofessional_tone"
    WEAK_COMMERCIAL_IMPACT = "weak_commercial_impact"
    INCOHERENT_LOGIC = "incoherent_logic"
    LANGUAGE_ERROR = "language_error"
    LOW_ENGAGEMENT = "low_engagement"
    REPETITIVE_RESPONSE = "repetitive_response"

@dataclass
class QualityIssue:
    """Problème qualité détecté"""
    concern_type: QualityConcern
    severity: float  # 0.0-1.0
    description: str
    detected_content: str
    suggested_correction: str
    confidence_score: float
    context_details: Dict[str, Any]

@dataclass
class QualityScore:
    """Score qualité multidimensionnel"""
    overall_score: float
    dimension_scores: Dict[QualityDimension, float]
    issues_detected: List[QualityIssue]
    analysis_confidence: float
    improvement_suggestions: List[str]
    timestamp: datetime
    marie_context: Dict[str, Any]

@dataclass
class PersonalityProfile:
    """Profil personnalité Marie pour référence"""
    expected_traits: Set[str] = field(default_factory=lambda: {
        'exigeante', 'directe', 'professionnelle', 'orientée_résultats',
        'impatiente', 'analytique', 'persuasive', 'autoritaire'
    })
    expected_vocabulary: Set[str] = field(default_factory=lambda: {
        'performance', 'résultats', 'efficacité', 'objectifs', 'ROI',
        'solutions', 'optimisation', 'stratégie', 'rentabilité', 'impact'
    })
    expected_phrases: Set[str] = field(default_factory=lambda: {
        'concrètement', 'en termes de résultats', 'quelle est la valeur ajoutée',
        'soyons précis', 'quels sont vos objectifs', 'parlons chiffres'
    })
    prohibited_traits: Set[str] = field(default_factory=lambda: {
        'hésitante', 'permissive', 'décontractée', 'familière', 'passive'
    })

class ConversationQualityAnalyzer:
    """
    Analyseur qualité temps réel pour réponses Marie
    
    Responsabilités :
    - Analyse multidimensionnelle qualité réponses Marie
    - Vérification cohérence personnalité et contexte
    - Détection dérives conversationnelles temps réel
    - Scoring qualité avec confidence et détails
    - Déclenchement corrections automatiques
    - Métriques performance conversation continue
    - Optimisation prompts Marie adaptatifs
    """
    
    def __init__(self, personality_intensity: float = 0.8, quality_threshold: float = 0.7):
        """
        Initialise l'analyseur qualité
        
        Args:
            personality_intensity: Intensité vérification personnalité 0.0-1.0
            quality_threshold: Seuil qualité pour déclencher corrections 0.0-1.0
        """
        self.personality_intensity = personality_intensity
        self.quality_threshold = quality_threshold
        
        # Profil personnalité Marie de référence
        self.marie_personality = PersonalityProfile()
        
        # Historique analyses
        self.analysis_history = deque(maxlen=100)
        self.quality_trends = defaultdict(list)
        
        # Cache patterns linguistiques
        self.language_patterns = self._initialize_language_patterns()
        
        # Modèle sémantique si disponible
        self.semantic_model = None
        if SENTENCE_TRANSFORMERS_AVAILABLE:
            try:
                self.semantic_model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
            except Exception as e:
                logging.warning(f"Impossible de charger modèle sémantique: {e}")
        
        # Statistiques analyse
        self.analysis_stats = {
            'total_analyses': 0,
            'issues_detected': 0,
            'corrections_triggered': 0,
            'average_quality': 0.0,
            'quality_improvement_rate': 0.0
        }
        
        self.logger = logging.getLogger(__name__)
        self.logger.info(f"ConversationQualityAnalyzer initialisé - Seuil: {quality_threshold}")
    
    def _initialize_language_patterns(self) -> Dict[str, Any]:
        """
        Initialise les patterns linguistiques pour analyse
        
        Returns:
            Dict[str, Any]: Patterns organisés par catégorie
        """
        return {
            'professional_indicators': [
                r'\b(performance|résultats|efficacité|objectifs|ROI|solutions)\b',
                r'\b(optimisation|stratégie|rentabilité|impact|valeur)\b',
                r'\b(concrètement|précisément|spécifiquement)\b'
            ],
            'commercial_power_words': [
                r'\b(investissement|retour|bénéfice|avantage|opportunité)\b',
                r'\b(décision|choix|option|solution|proposition)\b',
                r'\b(urgent|important|critique|essentiel)\b'
            ],
            'marie_authority_patterns': [
                r'\b(je recommande|je suggère|il faut|vous devez)\b',
                r'\b(clairement|évidemment|naturellement)\b',
                r'\b(soyons|parlons|regardons)\b'
            ],
            'unprofessional_indicators': [
                r'\b(salut|coucou|cool|super|génial)\b',
                r'\b(peut-être|euh|bon|enfin|voilà)\b',
                r'[.]{3,}|[!]{2,}|[?]{2,}'  # Ponctuation excessive
            ],
            'weak_confidence_patterns': [
                r'\b(je pense|je crois|probablement|peut-être)\b',
                r'\b(si ça vous va|si vous voulez|comme vous préférez)\b',
                r'\b(désolée|excusez-moi|pardon)\b'
            ],
            'repetitive_starters': [
                r'^(Alors|Donc|Bon|En fait|Effectivement)',
                r'^(C\'est|Il faut|Vous devez|Je pense)'
            ]
        }
    
    async def analyze_marie_response(self, marie_response: str, conversation_context: Dict[str, Any],
                                   user_message: str = "", marie_state: Dict[str, Any] = None) -> QualityScore:
        """
        Analyse complète qualité réponse Marie
        
        Args:
            marie_response: Réponse Marie à analyser
            conversation_context: Contexte conversation actuel
            user_message: Message utilisateur précédent
            marie_state: État actuel Marie (satisfaction, mode, etc.)
            
        Returns:
            QualityScore: Score qualité multidimensionnel
        """
        marie_state = marie_state or {}
        
        # Analyses par dimension
        dimension_scores = {}
        all_issues = []
        
        # 1. Pertinence contextuelle
        context_score, context_issues = self._analyze_contextual_relevance(
            marie_response, conversation_context, user_message
        )
        dimension_scores[QualityDimension.CONTEXTUAL_RELEVANCE] = context_score
        all_issues.extend(context_issues)
        
        # 2. Cohérence personnalité
        personality_score, personality_issues = self._analyze_personality_coherence(
            marie_response, marie_state
        )
        dimension_scores[QualityDimension.PERSONALITY_COHERENCE] = personality_score
        all_issues.extend(personality_issues)
        
        # 3. Registre professionnel
        professional_score, professional_issues = self._analyze_professional_register(
            marie_response
        )
        dimension_scores[QualityDimension.PROFESSIONAL_REGISTER] = professional_score
        all_issues.extend(professional_issues)
        
        # 4. Impact commercial
        commercial_score, commercial_issues = self._analyze_commercial_impact(
            marie_response, conversation_context
        )
        dimension_scores[QualityDimension.COMMERCIAL_IMPACT] = commercial_score
        all_issues.extend(commercial_issues)
        
        # 5. Authenticité émotionnelle
        emotional_score, emotional_issues = self._analyze_emotional_authenticity(
            marie_response, marie_state
        )
        dimension_scores[QualityDimension.EMOTIONAL_AUTHENTICITY] = emotional_score
        all_issues.extend(emotional_issues)
        
        # 6. Progression logique
        logical_score, logical_issues = self._analyze_logical_progression(
            marie_response, conversation_context
        )
        dimension_scores[QualityDimension.LOGICAL_PROGRESSION] = logical_score
        all_issues.extend(logical_issues)
        
        # 7. Qualité linguistique
        language_score, language_issues = self._analyze_language_quality(
            marie_response
        )
        dimension_scores[QualityDimension.LANGUAGE_QUALITY] = language_score
        all_issues.extend(language_issues)
        
        # 8. Niveau engagement
        engagement_score, engagement_issues = self._analyze_engagement_level(
            marie_response, conversation_context
        )
        dimension_scores[QualityDimension.ENGAGEMENT_LEVEL] = engagement_score
        all_issues.extend(engagement_issues)
        
        # Score global pondéré
        weights = {
            QualityDimension.CONTEXTUAL_RELEVANCE: 0.20,
            QualityDimension.PERSONALITY_COHERENCE: 0.20,
            QualityDimension.PROFESSIONAL_REGISTER: 0.15,
            QualityDimension.COMMERCIAL_IMPACT: 0.15,
            QualityDimension.EMOTIONAL_AUTHENTICITY: 0.10,
            QualityDimension.LOGICAL_PROGRESSION: 0.10,
            QualityDimension.LANGUAGE_QUALITY: 0.05,
            QualityDimension.ENGAGEMENT_LEVEL: 0.05
        }
        
        overall_score = sum(
            dimension_scores[dim] * weight 
            for dim, weight in weights.items()
        )
        
        # Confidence analyse basée sur nombre d'indicateurs
        analysis_confidence = min(1.0, 0.6 + 0.1 * len(marie_response.split()))
        
        # Suggestions amélioration
        improvement_suggestions = self._generate_improvement_suggestions(
            all_issues, dimension_scores, marie_state
        )
        
        # Score qualité final
        quality_score = QualityScore(
            overall_score=overall_score,
            dimension_scores=dimension_scores,
            issues_detected=all_issues,
            analysis_confidence=analysis_confidence,
            improvement_suggestions=improvement_suggestions,
            timestamp=datetime.now(),
            marie_context=marie_state.copy()
        )
        
        # Mise à jour historique et stats
        self._update_analysis_history(quality_score)
        
        self.logger.info(f"Analyse qualité Marie - Score global: {overall_score:.2f}, "
                        f"Problèmes: {len(all_issues)}")
        
        return quality_score
    
    def _analyze_contextual_relevance(self, marie_response: str, context: Dict[str, Any],
                                    user_message: str) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse pertinence contextuelle de la réponse
        
        Args:
            marie_response: Réponse à analyser
            context: Contexte conversation
            user_message: Message utilisateur
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes détectés
        """
        score = 0.8  # Score base
        issues = []
        
        # Vérification réponse aux questions directes
        if user_message and '?' in user_message:
            # Recherche indicateurs de réponse
            response_indicators = [
                r'\b(oui|non|effectivement|exactement|bien sûr)\b',
                r'\b(voici|voilà|c\'est|il s\'agit)\b',
                r'\b(pour répondre|concernant|à propos)\b'
            ]
            
            has_response_indicator = any(
                re.search(pattern, marie_response.lower())
                for pattern in response_indicators
            )
            
            if not has_response_indicator:
                score -= 0.2
                issues.append(QualityIssue(
                    concern_type=QualityConcern.CONTEXT_MISMATCH,
                    severity=0.4,
                    description="Réponse ne semble pas adresser la question utilisateur",
                    detected_content=marie_response[:100] + "...",
                    suggested_correction="Commencer par une réponse directe puis développer",
                    confidence_score=0.7,
                    context_details={'user_question': user_message}
                ))
        
        # Vérification cohérence phase conversation
        conversation_phase = context.get('current_phase', 'discovery')
        
        phase_keywords = {
            'introduction': ['présentation', 'équipe', 'entreprise', 'activité'],
            'discovery': ['besoins', 'problèmes', 'objectifs', 'situation'],
            'presentation': ['solution', 'fonctionnalités', 'avantages', 'bénéfices'],
            'objection': ['comprends', 'effectivement', 'cependant', 'toutefois'],
            'negotiation': ['prix', 'conditions', 'accord', 'arrangement'],
            'closing': ['prochaines étapes', 'démarrage', 'signature', 'validation']
        }
        
        expected_keywords = phase_keywords.get(conversation_phase, [])
        found_keywords = sum(
            1 for keyword in expected_keywords
            if keyword in marie_response.lower()
        )
        
        if expected_keywords and found_keywords == 0:
            score -= 0.15
            issues.append(QualityIssue(
                concern_type=QualityConcern.CONTEXT_MISMATCH,
                severity=0.3,
                description=f"Réponse pas adaptée à la phase {conversation_phase}",
                detected_content="Vocabulaire inadéquat pour la phase",
                suggested_correction=f"Utiliser vocabulaire lié à {conversation_phase}",
                confidence_score=0.6,
                context_details={'expected_phase': conversation_phase}
            ))
        
        return max(0.0, score), issues
    
    def _analyze_personality_coherence(self, marie_response: str, 
                                     marie_state: Dict[str, Any]) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse cohérence avec personnalité Marie
        
        Args:
            marie_response: Réponse à analyser
            marie_state: État Marie actuel
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.7  # Score base
        issues = []
        
        response_lower = marie_response.lower()
        
        # Vérification vocabulaire attendu
        expected_vocab_found = sum(
            1 for word in self.marie_personality.expected_vocabulary
            if word in response_lower
        )
        vocab_ratio = expected_vocab_found / max(1, len(self.marie_personality.expected_vocabulary))
        score += 0.2 * vocab_ratio
        
        # Vérification phrases caractéristiques
        expected_phrases_found = sum(
            1 for phrase in self.marie_personality.expected_phrases
            if phrase in response_lower
        )
        if expected_phrases_found > 0:
            score += 0.1
        
        # Détection traits interdits
        prohibited_found = [
            trait for trait in self.marie_personality.prohibited_traits
            if trait in response_lower
        ]
        
        if prohibited_found:
            score -= 0.3 * len(prohibited_found)
            issues.append(QualityIssue(
                concern_type=QualityConcern.PERSONALITY_DRIFT,
                severity=0.6,
                description=f"Traits incompatibles détectés: {prohibited_found}",
                detected_content=", ".join(prohibited_found),
                suggested_correction="Adopter un ton plus directif et professionnel",
                confidence_score=0.8,
                context_details={'prohibited_traits': prohibited_found}
            ))
        
        # Vérification cohérence mode Marie
        current_mode = marie_state.get('current_mode', 'initial_evaluation')
        satisfaction = marie_state.get('satisfaction_level', 0.5)
        patience = marie_state.get('patience_level', 1.0)
        
        # Mode exigeant mais réponse trop permissive
        if current_mode in ['objection_challenger', 'firm_negotiation'] and patience < 0.4:
            permissive_indicators = ['peut-être', 'si vous voulez', 'comme vous préférez']
            if any(indicator in response_lower for indicator in permissive_indicators):
                score -= 0.2
                issues.append(QualityIssue(
                    concern_type=QualityConcern.PERSONALITY_DRIFT,
                    severity=0.5,
                    description="Réponse trop permissive pour mode Marie exigeant",
                    detected_content="Langage indécis détecté",
                    suggested_correction="Adopter position plus ferme et directive",
                    confidence_score=0.7,
                    context_details={'marie_mode': current_mode, 'patience': patience}
                ))
        
        return max(0.0, score), issues
    
    def _analyze_professional_register(self, marie_response: str) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse registre professionnel
        
        Args:
            marie_response: Réponse à analyser
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.8  # Score base
        issues = []
        
        # Détection indicateurs professionnels positifs
        professional_matches = sum(
            len(re.findall(pattern, marie_response.lower()))
            for pattern in self.language_patterns['professional_indicators']
        )
        score += min(0.15, 0.05 * professional_matches)
        
        # Détection indicateurs non professionnels
        unprofessional_matches = []
        for pattern in self.language_patterns['unprofessional_indicators']:
            matches = re.findall(pattern, marie_response.lower())
            unprofessional_matches.extend(matches)
        
        if unprofessional_matches:
            score -= 0.1 * len(unprofessional_matches)
            issues.append(QualityIssue(
                concern_type=QualityConcern.UNPROFESSIONAL_TONE,
                severity=0.4,
                description="Langage peu professionnel détecté",
                detected_content=", ".join(unprofessional_matches),
                suggested_correction="Utiliser vocabulaire plus formel et professionnel",
                confidence_score=0.8,
                context_details={'unprofessional_terms': unprofessional_matches}
            ))
        
        # Vérification structure phrases
        sentences = marie_response.split('.')
        avg_sentence_length = statistics.mean([len(s.split()) for s in sentences if s.strip()])
        
        if avg_sentence_length < 4:  # Phrases trop courtes
            score -= 0.1
            issues.append(QualityIssue(
                concern_type=QualityConcern.LANGUAGE_ERROR,
                severity=0.2,
                description="Phrases trop courtes pour registre professionnel",
                detected_content=f"Longueur moyenne: {avg_sentence_length:.1f} mots",
                suggested_correction="Développer les explications avec phrases plus étoffées",
                confidence_score=0.6,
                context_details={'average_length': avg_sentence_length}
            ))
        
        return max(0.0, score), issues
    
    def _analyze_commercial_impact(self, marie_response: str, 
                                 context: Dict[str, Any]) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse impact commercial de la réponse
        
        Args:
            marie_response: Réponse à analyser
            context: Contexte conversation
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.6  # Score base
        issues = []
        
        # Détection mots puissants commerciaux
        commercial_power_found = sum(
            len(re.findall(pattern, marie_response.lower()))
            for pattern in self.language_patterns['commercial_power_words']
        )
        score += min(0.25, 0.08 * commercial_power_found)
        
        # Vérification présence appel à l'action
        call_to_action_patterns = [
            r'\b(décidons|avançons|planifions|organisons)\b',
            r'\b(quand|comment|où) (pouvons|allons|devons)\b',
            r'\b(prochaine étape|étape suivante|maintenant)\b'
        ]
        
        has_call_to_action = any(
            re.search(pattern, marie_response.lower())
            for pattern in call_to_action_patterns
        )
        
        if has_call_to_action:
            score += 0.15
        else:
            # Manque d'orientation action en phase avancée
            phase = context.get('current_phase', '')
            if phase in ['presentation', 'negotiation', 'closing']:
                score -= 0.2
                issues.append(QualityIssue(
                    concern_type=QualityConcern.WEAK_COMMERCIAL_IMPACT,
                    severity=0.4,
                    description="Manque d'appel à l'action en phase commerciale",
                    detected_content="Aucune orientation vers prochaine étape",
                    suggested_correction="Ajouter proposition d'action concrète",
                    confidence_score=0.7,
                    context_details={'conversation_phase': phase}
                ))
        
        # Détection valeur/bénéfices mentionnés
        value_indicators = [
            r'\b(économie|gain|économiser|réduire les coûts)\b',
            r'\b(améliorer|optimiser|efficacité|performance)\b',
            r'\b(retour sur investissement|ROI|rentabilité)\b'
        ]
        
        value_mentions = sum(
            len(re.findall(pattern, marie_response.lower()))
            for pattern in value_indicators
        )
        
        if value_mentions == 0 and context.get('current_phase') in ['presentation', 'objection']:
            score -= 0.15
            issues.append(QualityIssue(
                concern_type=QualityConcern.WEAK_COMMERCIAL_IMPACT,
                severity=0.3,
                description="Manque de mise en valeur bénéfices/ROI",
                detected_content="Aucune mention valeur client",
                suggested_correction="Intégrer bénéfices concrets et mesurables",
                confidence_score=0.6,
                context_details={'phase': context.get('current_phase')}
            ))
        
        return max(0.0, score), issues
    
    def _analyze_emotional_authenticity(self, marie_response: str,
                                      marie_state: Dict[str, Any]) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse authenticité émotionnelle
        
        Args:
            marie_response: Réponse à analyser
            marie_state: État émotionnel Marie
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.7  # Score base
        issues = []
        
        satisfaction = marie_state.get('satisfaction_level', 0.5)
        patience = marie_state.get('patience_level', 1.0)
        
        # Vérification cohérence ton/satisfaction
        positive_tone_indicators = [
            r'\b(excellent|parfait|très bien|exactement)\b',
            r'\b(je suis ravie|c\'est formidable)\b'
        ]
        
        negative_tone_indicators = [
            r'\b(problème|inquiet|préoccup|difficile)\b',
            r'\b(malheureusement|cependant|toutefois)\b'
        ]
        
        has_positive_tone = any(
            re.search(pattern, marie_response.lower())
            for pattern in positive_tone_indicators
        )
        
        has_negative_tone = any(
            re.search(pattern, marie_response.lower())
            for pattern in negative_tone_indicators
        )
        
        # Incohérence satisfaction élevée mais ton négatif
        if satisfaction > 0.7 and has_negative_tone and not has_positive_tone:
            score -= 0.3
            issues.append(QualityIssue(
                concern_type=QualityConcern.PERSONALITY_DRIFT,
                severity=0.5,
                description="Ton négatif incohérent avec satisfaction élevée",
                detected_content="Satisfaction-ton mismatch",
                suggested_correction="Ajuster ton pour refléter satisfaction positive",
                confidence_score=0.8,
                context_details={'satisfaction': satisfaction, 'has_negative_tone': True}
            ))
        
        # Incohérence satisfaction faible mais ton trop positif
        if satisfaction < 0.3 and has_positive_tone and not has_negative_tone:
            score -= 0.2
            issues.append(QualityIssue(
                concern_type=QualityConcern.PERSONALITY_DRIFT,
                severity=0.4,
                description="Ton trop positif pour satisfaction faible",
                detected_content="Enthousiasme inapproprié",
                suggested_correction="Modérer enthousiasme, montrer exigence",
                confidence_score=0.7,
                context_details={'satisfaction': satisfaction, 'has_positive_tone': True}
            ))
        
        # Vérification impatience/patience
        if patience < 0.3:
            urgency_indicators = [
                r'\b(rapidement|vite|urgent|pressé)\b',
                r'\b(allons|avançons|directement)\b'
            ]
            
            has_urgency = any(
                re.search(pattern, marie_response.lower())
                for pattern in urgency_indicators
            )
            
            if not has_urgency:
                score -= 0.2
                issues.append(QualityIssue(
                    concern_type=QualityConcern.PERSONALITY_DRIFT,
                    severity=0.4,
                    description="Manque d'urgence malgré impatience Marie",
                    detected_content="Pas d'indicateurs d'impatience",
                    suggested_correction="Intégrer signaux d'urgence et d'impatience",
                    confidence_score=0.7,
                    context_details={'patience_level': patience}
                ))
        
        return max(0.0, score), issues
    
    def _analyze_logical_progression(self, marie_response: str,
                                   context: Dict[str, Any]) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse progression logique
        
        Args:
            marie_response: Réponse à analyser
            context: Contexte conversation
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.8  # Score base
        issues = []
        
        # Vérification connecteurs logiques
        logical_connectors = [
            r'\b(donc|par conséquent|ainsi|c\'est pourquoi)\b',
            r'\b(d\'abord|ensuite|enfin|premièrement)\b',
            r'\b(en effet|effectivement|cependant|néanmoins)\b'
        ]
        
        connector_count = sum(
            len(re.findall(pattern, marie_response.lower()))
            for pattern in logical_connectors
        )
        
        sentence_count = len([s for s in marie_response.split('.') if s.strip()])
        
        if sentence_count > 2 and connector_count == 0:
            score -= 0.15
            issues.append(QualityIssue(
                concern_type=QualityConcern.INCOHERENT_LOGIC,
                severity=0.3,
                description="Manque de connecteurs logiques dans réponse longue",
                detected_content=f"{sentence_count} phrases sans connecteurs",
                suggested_correction="Ajouter connecteurs pour structurer le propos",
                confidence_score=0.6,
                context_details={'sentence_count': sentence_count}
            ))
        
        # Vérification cohérence début/fin
        if len(marie_response.split()) > 15:
            # Analyse très basique de cohérence thématique
            first_third = marie_response[:len(marie_response)//3].lower()
            last_third = marie_response[2*len(marie_response)//3:].lower()
            
            # Mots-clés principaux début vs fin
            first_keywords = set(re.findall(r'\b\w{4,}\b', first_third))
            last_keywords = set(re.findall(r'\b\w{4,}\b', last_third))
            
            keyword_overlap = len(first_keywords.intersection(last_keywords))
            if keyword_overlap == 0 and len(first_keywords) > 2 and len(last_keywords) > 2:
                score -= 0.1
                issues.append(QualityIssue(
                    concern_type=QualityConcern.INCOHERENT_LOGIC,
                    severity=0.2,
                    description="Possible manque de cohérence thématique",
                    detected_content="Début et fin sans mots-clés communs",
                    suggested_correction="S'assurer que la conclusion reprend le thème initial",
                    confidence_score=0.4,
                    context_details={'first_keywords_count': len(first_keywords)}
                ))
        
        return max(0.0, score), issues
    
    def _analyze_language_quality(self, marie_response: str) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse qualité linguistique
        
        Args:
            marie_response: Réponse à analyser
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.8  # Score base
        issues = []
        
        # Vérification répétitions
        words = marie_response.lower().split()
        word_freq = {}
        for word in words:
            if len(word) > 3:  # Ignorer mots courts
                word_freq[word] = word_freq.get(word, 0) + 1
        
        repeated_words = [(word, count) for word, count in word_freq.items() if count > 2]
        
        if repeated_words:
            score -= 0.1 * len(repeated_words)
            issues.append(QualityIssue(
                concern_type=QualityConcern.REPETITIVE_RESPONSE,
                severity=0.3,
                description=f"Répétitions détectées: {repeated_words}",
                detected_content=", ".join([f"{w}({c})" for w, c in repeated_words]),
                suggested_correction="Varier le vocabulaire et reformuler",
                confidence_score=0.8,
                context_details={'repeated_words': repeated_words}
            ))
        
        # Vérification ponctuation excessive
        excessive_punct = re.findall(r'[.!?]{2,}', marie_response)
        if excessive_punct:
            score -= 0.1
            issues.append(QualityIssue(
                concern_type=QualityConcern.LANGUAGE_ERROR,
                severity=0.2,
                description="Ponctuation excessive détectée",
                detected_content=", ".join(excessive_punct),
                suggested_correction="Utiliser ponctuation standard",
                confidence_score=0.9,
                context_details={'excessive_punctuation': excessive_punct}
            ))
        
        # Analyse sentiment si TextBlob disponible
        try:
            blob = TextBlob(marie_response)
            if blob.sentiment.polarity < -0.5:  # Très négatif
                score -= 0.05
        except:
            pass  # Ignore si TextBlob non disponible
        
        return max(0.0, score), issues
    
    def _analyze_engagement_level(self, marie_response: str,
                                context: Dict[str, Any]) -> Tuple[float, List[QualityIssue]]:
        """
        Analyse niveau d'engagement
        
        Args:
            marie_response: Réponse à analyser
            context: Contexte conversation
            
        Returns:
            Tuple[float, List[QualityIssue]]: Score et problèmes
        """
        score = 0.7  # Score base
        issues = []
        
        # Longueur appropriée selon contexte
        word_count = len(marie_response.split())
        
        expected_length_ranges = {
            'introduction': (15, 40),
            'discovery': (20, 50),
            'presentation': (30, 80),
            'objection': (25, 60),
            'negotiation': (20, 45),
            'closing': (15, 35)
        }
        
        phase = context.get('current_phase', 'discovery')
        min_words, max_words = expected_length_ranges.get(phase, (15, 50))
        
        if word_count < min_words:
            score -= 0.2
            issues.append(QualityIssue(
                concern_type=QualityConcern.LOW_ENGAGEMENT,
                severity=0.3,
                description=f"Réponse trop courte pour phase {phase}",
                detected_content=f"{word_count} mots (min: {min_words})",
                suggested_correction="Développer davantage la réponse",
                confidence_score=0.7,
                context_details={'word_count': word_count, 'phase': phase}
            ))
        elif word_count > max_words:
            score -= 0.1
            issues.append(QualityIssue(
                concern_type=QualityConcern.LOW_ENGAGEMENT,
                severity=0.2,
                description=f"Réponse trop longue pour phase {phase}",
                detected_content=f"{word_count} mots (max: {max_words})",
                suggested_correction="Condenser le message pour plus d'impact",
                confidence_score=0.6,
                context_details={'word_count': word_count, 'phase': phase}
            ))
        
        # Vérification questions engageantes
        question_count = marie_response.count('?')
        if question_count > 0:
            score += 0.1 * min(question_count, 2)  # Bonus jusqu'à 2 questions
        
        return max(0.0, score), issues
    
    def _generate_improvement_suggestions(self, issues: List[QualityIssue],
                                        dimension_scores: Dict[QualityDimension, float],
                                        marie_state: Dict[str, Any]) -> List[str]:
        """
        Génère suggestions d'amélioration
        
        Args:
            issues: Problèmes détectés
            dimension_scores: Scores par dimension
            marie_state: État Marie
            
        Returns:
            List[str]: Suggestions d'amélioration
        """
        suggestions = []
        
        # Suggestions basées sur problèmes critiques
        critical_issues = [issue for issue in issues if issue.severity > 0.5]
        for issue in critical_issues:
            suggestions.append(issue.suggested_correction)
        
        # Suggestions basées sur scores faibles
        weak_dimensions = [
            dim for dim, score in dimension_scores.items()
            if score < 0.6
        ]
        
        dimension_suggestions = {
            QualityDimension.CONTEXTUAL_RELEVANCE: "Mieux répondre aux questions directes utilisateur",
            QualityDimension.PERSONALITY_COHERENCE: "Renforcer traits directifs et exigeants de Marie",
            QualityDimension.PROFESSIONAL_REGISTER: "Adopter vocabulaire plus formel et professionnel",
            QualityDimension.COMMERCIAL_IMPACT: "Intégrer davantage d'appels à l'action et de valeur",
            QualityDimension.EMOTIONAL_AUTHENTICITY: "Aligner ton émotionnel avec état satisfaction Marie",
            QualityDimension.LOGICAL_PROGRESSION: "Structurer réponse avec connecteurs logiques",
            QualityDimension.LANGUAGE_QUALITY: "Éviter répétitions et améliorer fluidité",
            QualityDimension.ENGAGEMENT_LEVEL: "Ajuster longueur réponse selon phase conversation"
        }
        
        for dim in weak_dimensions:
            if dim in dimension_suggestions:
                suggestions.append(dimension_suggestions[dim])
        
        # Suggestions contextuelles Marie
        satisfaction = marie_state.get('satisfaction_level', 0.5)
        patience = marie_state.get('patience_level', 1.0)
        
        if satisfaction < 0.4:
            suggestions.append("Marie peu satisfaite : adopter approche plus directive et questionnement challengeant")
        
        if patience < 0.3:
            suggestions.append("Marie impatiente : accélérer conversation et aller à l'essentiel")
        
        # Déduplication et limitation
        unique_suggestions = list(dict.fromkeys(suggestions))  # Supprime doublons
        return unique_suggestions[:5]  # Max 5 suggestions
    
    def _update_analysis_history(self, quality_score: QualityScore):
        """
        Met à jour historique analyses
        
        Args:
            quality_score: Score qualité à archiver
        """
        self.analysis_history.append(quality_score)
        
        # Mise à jour tendances par dimension
        for dim, score in quality_score.dimension_scores.items():
            self.quality_trends[dim].append({
                'timestamp': quality_score.timestamp,
                'score': score
            })
            
            # Garder seulement 50 derniers points
            if len(self.quality_trends[dim]) > 50:
                self.quality_trends[dim].pop(0)
        
        # Mise à jour statistiques
        self.analysis_stats['total_analyses'] += 1
        self.analysis_stats['issues_detected'] += len(quality_score.issues_detected)
        
        # Moyenne glissante qualité
        total = self.analysis_stats['total_analyses']
        old_avg = self.analysis_stats['average_quality']
        new_score = quality_score.overall_score
        self.analysis_stats['average_quality'] = (old_avg * (total - 1) + new_score) / total
        
        # Taux amélioration (comparaison 10 dernières analyses)
        if len(self.analysis_history) >= 10:
            recent_scores = [analysis.overall_score for analysis in list(self.analysis_history)[-10:]]
            older_scores = [analysis.overall_score for analysis in list(self.analysis_history)[-20:-10]]
            
            if older_scores:
                recent_avg = statistics.mean(recent_scores)
                older_avg = statistics.mean(older_scores)
                improvement_rate = (recent_avg - older_avg) / older_avg if older_avg > 0 else 0
                self.analysis_stats['quality_improvement_rate'] = improvement_rate
    
    def should_trigger_correction(self, quality_score: QualityScore) -> bool:
        """
        Détermine si une correction doit être déclenchée
        
        Args:
            quality_score: Score qualité évalué
            
        Returns:
            bool: True si correction nécessaire
        """
        # Correction si score global sous seuil
        if quality_score.overall_score < self.quality_threshold:
            return True
        
        # Correction si problèmes critiques
        critical_issues = [
            issue for issue in quality_score.issues_detected 
            if issue.severity > 0.6
        ]
        if len(critical_issues) >= 2:
            return True
        
        # Correction si dégradation tendance
        if len(self.analysis_history) >= 3:
            last_scores = [analysis.overall_score for analysis in list(self.analysis_history)[-3:]]
            if all(last_scores[i] > last_scores[i+1] for i in range(len(last_scores)-1)):
                return True  # Dégradation continue
        
        return False
    
    def generate_correction_prompt(self, quality_score: QualityScore,
                                 original_prompt: str, marie_response: str) -> str:
        """
        Génère prompt correction pour améliorer réponse Marie
        
        Args:
            quality_score: Analyse qualité
            original_prompt: Prompt original
            marie_response: Réponse défaillante
            
        Returns:
            str: Prompt correction optimisé
        """
        correction_elements = []
        
        # Instruction base
        correction_elements.append(
            "CORRECTION REQUISE: La réponse précédente ne respecte pas suffisamment "
            "la personnalité et les standards de Marie."
        )
        
        # Problèmes spécifiques détectés
        if quality_score.issues_detected:
            issues_desc = []
            for issue in quality_score.issues_detected[:3]:  # Top 3 problèmes
                issues_desc.append(f"- {issue.description}: {issue.suggested_correction}")
            
            correction_elements.append(
                "PROBLÈMES DÉTECTÉS:\n" + "\n".join(issues_desc)
            )
        
        # Amélioration suggérée personnalité
        personality_score = quality_score.dimension_scores.get(QualityDimension.PERSONALITY_COHERENCE, 1.0)
        if personality_score < 0.6:
            correction_elements.append(
                "RENFORCEMENT PERSONNALITÉ: Marie doit être plus directive, exigeante "
                "et orientée résultats. Utiliser vocabulaire professionnel et ton autoritaire."
            )
        
        # Amélioration impact commercial
        commercial_score = quality_score.dimension_scores.get(QualityDimension.COMMERCIAL_IMPACT, 1.0)
        if commercial_score < 0.6:
            correction_elements.append(
                "RENFORCEMENT COMMERCIAL: Intégrer davantage de valeur client, "
                "bénéfices mesurables et appels à l'action concrets."
            )
        
        # Instruction génération corrigée
        correction_elements.append(
            f"GÉNÉRATION CORRIGÉE: Reprendre la réponse en corrigeant ces aspects "
            f"tout en conservant la cohérence avec le contexte conversation."
        )
        
        # Assemblage prompt final
        correction_prompt = original_prompt + "\n\n" + "\n\n".join(correction_elements)
        
        return correction_prompt
    
    def get_analysis_analytics(self) -> Dict[str, Any]:
        """
        Obtient analytics complets des analyses
        
        Returns:
            Dict[str, Any]: Métriques et tendances
        """
        analytics = {
            'analysis_statistics': self.analysis_stats.copy(),
            'quality_trends': {},
            'recent_quality_summary': {},
            'improvement_recommendations': []
        }
        
        # Tendances par dimension
        for dim, trend_data in self.quality_trends.items():
            if trend_data:
                scores = [point['score'] for point in trend_data]
                analytics['quality_trends'][dim.value] = {
                    'current_score': scores[-1] if scores else 0,
                    'average_score': statistics.mean(scores),
                    'trend_direction': 'improving' if len(scores) > 1 and scores[-1] > scores[0] else 'stable',
                    'volatility': statistics.stdev(scores) if len(scores) > 1 else 0
                }
        
        # Résumé récent
        if self.analysis_history:
            recent_analyses = list(self.analysis_history)[-5:]
            recent_scores = [analysis.overall_score for analysis in recent_analyses]
            recent_issues = sum(len(analysis.issues_detected) for analysis in recent_analyses)
            
            analytics['recent_quality_summary'] = {
                'average_score': statistics.mean(recent_scores),
                'best_score': max(recent_scores),
                'worst_score': min(recent_scores),
                'total_issues': recent_issues,
                'analyses_count': len(recent_analyses)
            }
        
        # Recommandations amélioration globales
        if self.analysis_history:
            # Identifier dimensions faibles récurrentes
            weak_dimensions = defaultdict(int)
            for analysis in list(self.analysis_history)[-10:]:
                for dim, score in analysis.dimension_scores.items():
                    if score < 0.6:
                        weak_dimensions[dim] += 1
            
            # Top recommandations
            top_weak = sorted(weak_dimensions.items(), key=lambda x: x[1], reverse=True)[:3]
            for dim, count in top_weak:
                analytics['improvement_recommendations'].append(
                    f"Améliorer {dim.value}: problème récurrent ({count}/10 analyses)"
                )
        
        return analytics
    
    def export_quality_report(self, filepath: Optional[str] = None) -> str:
        """
        Exporte rapport qualité complet
        
        Args:
            filepath: Chemin fichier optionnel
            
        Returns:
            str: Chemin fichier généré
        """
        if not filepath:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = f"marie_quality_analysis_report_{timestamp}.json"
        
        report = {
            'quality_analysis_session': {
                'report_timestamp': datetime.now().isoformat(),
                'total_analyses_performed': self.analysis_stats['total_analyses'],
                'quality_threshold_configured': self.quality_threshold,
                'personality_intensity': self.personality_intensity
            },
            'analysis_statistics': self.analysis_stats,
            'quality_analytics': self.get_analysis_analytics(),
            'recent_analyses': [
                {
                    'timestamp': analysis.timestamp.isoformat(),
                    'overall_score': analysis.overall_score,
                    'dimension_scores': {dim.value: score for dim, score in analysis.dimension_scores.items()},
                    'issues_count': len(analysis.issues_detected),
                    'confidence': analysis.analysis_confidence
                }
                for analysis in list(self.analysis_history)[-20:]  # 20 dernières
            ]
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Rapport qualité exporté: {filepath}")
        return filepath