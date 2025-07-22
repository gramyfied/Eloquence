#!/usr/bin/env python3
"""
Real Conversation Manager - Gestionnaire de Conversation Réelle avec Marie
Orchestre le pipeline complet TTS→VOSK→Mistral→TTS en mode réel
"""

import asyncio
import time
import json
import logging
import tempfile
import random
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, asdict
from pathlib import Path

# Imports des composants existants
from marie_ai_character import MarieAICharacter, marie_character
from service_wrappers import RealTTSService, RealVoskService, RealMistralService
from interactive_conversation_tester import ConversationMetricsCollector
from conversation_engine import AutoRepairSystem

logger = logging.getLogger(__name__)

@dataclass
class RealConversationConfig:
    """Configuration pour conversation réelle"""
    max_exchanges: int = 10
    max_conversation_time: float = 600.0  # 10 minutes max
    max_exchange_time: float = 45.0  # 45 secondes par échange
    enable_auto_repair: bool = True
    enable_real_time_monitoring: bool = True
    save_conversation_audio: bool = True
    marie_personality_intensity: float = 0.8  # 0.0 = douce, 1.0 = très exigeante
    user_simulation_realism: float = 0.9  # Niveau de réalisme de la simulation

@dataclass
class RealExchangeResult:
    """Résultat d'un échange en mode réel"""
    exchange_number: int
    user_message_text: str
    user_audio_generated: bool
    user_audio_duration: float
    vosk_transcription: str
    vosk_confidence: float
    marie_response_text: str
    marie_audio_generated: bool
    marie_audio_duration: float
    total_exchange_time: float
    pipeline_times: Dict[str, float]
    marie_state: Dict[str, Any]
    quality_scores: Dict[str, float]
    issues_detected: List[str]
    repairs_applied: List[str]
    success: bool

class UserMessageGenerator:
    """Générateur de messages utilisateur contextuels et réalistes"""
    
    def __init__(self, realism_level: float = 0.9):
        self.realism_level = realism_level
        self.conversation_context = []
        self.user_profile = {
            'role': 'commercial',
            'experience_level': 'senior',
            'company': 'Solutions Innovantes SARL',
            'product_category': 'logiciel CRM',
            'budget_range': '50k-100k',
            'decision_timeline': '3_months'
        }
        
        # Banque de messages par phase de conversation
        self.message_templates = {
            'opening': [
                "Bonjour Marie, je viens vous présenter notre nouvelle solution CRM qui révolutionne la gestion client.",
                "Marie, merci de me recevoir. Notre produit a déjà transformé la performance de plus de 500 entreprises.",
                "Bonjour, je suis ravi de vous rencontrer. Nous avons développé une solution qui peut augmenter votre chiffre d'affaires de 30%."
            ],
            'presentation': [
                "Notre solution offre un ROI garanti de {roi}% en {timeline} mois avec un support 24/7 inclus.",
                "Nous proposons une intégration complète en {timeline} semaines avec formation de vos équipes.",
                "Le système gère automatiquement {features} avec des analytics en temps réel et tableaux de bord personnalisés."
            ],
            'objection_handling': [
                "Je comprends votre préoccupation. Laissez-moi vous expliquer comment nos {references} entreprises clientes ont surmonté ce défi.",
                "C'est une excellente question. Notre équipe technique a spécialement conçu une solution pour ce type de contrainte.",
                "Justement, c'est exactement pour cette raison que nous proposons {solution_specifique} avec garantie de résultats."
            ],
            'negotiation': [
                "Sur le budget, nous pouvons proposer un échelonnement sur {nb_mois} mois avec {avantage_commercial}.",
                "Pour respecter votre timeline, nous pouvons commencer par le module prioritaire et déployer le reste progressivement.",
                "Je peux vous proposer une remise de {pourcentage}% si nous signons aujourd'hui avec un engagement sur {duree}."
            ],
            'closing': [
                "Parfait, alors nous sommes d'accord sur l'essentiel. Quand pouvons-nous planifier le démarrage ?",
                "Excellent, je prépare le contrat avec les conditions que nous avons discutées. Un délai de 48h vous convient ?",
                "Merci Marie, c'est un plaisir de travailler avec vous. Notre équipe prendra contact dès demain pour la mise en route."
            ]
        }
        
    def generate_contextual_message(self, marie_last_response: str, conversation_phase: str, marie_state: Dict) -> str:
        """Génère un message utilisateur contextuel basé sur la réponse de Marie"""
        
        # Analyser la réponse de Marie pour adapter le message
        marie_satisfaction = marie_state.get('satisfaction_level', 0.5)
        marie_mode = marie_state.get('mode_actuel', 'evaluation_initiale')
        
        # Sélectionner la phase appropriée
        if conversation_phase == 'opening' or not self.conversation_context:
            phase = 'opening'
        elif 'objection' in marie_mode or marie_satisfaction < 0.4:
            phase = 'objection_handling'
        elif 'negociation' in marie_mode or 'validation' in marie_mode:
            phase = 'negotiation'
        elif marie_satisfaction > 0.8:
            phase = 'closing'
        else:
            phase = 'presentation'
        
        # Choisir un template et le personnaliser
        template = self._select_template(phase, marie_last_response)
        message = self._personalize_template(template, marie_state)
        
        # Ajouter du réalisme avec variations
        message = self._add_realism_variations(message, phase)
        
        self.conversation_context.append({
            'phase': phase,
            'message': message,
            'marie_satisfaction': marie_satisfaction,
            'timestamp': time.time()
        })
        
        return message
    
    def _select_template(self, phase: str, marie_response: str) -> str:
        """Sélectionne le template le plus approprié"""
        
        templates = self.message_templates.get(phase, self.message_templates['presentation'])
        
        # Logique de sélection basée sur la réponse de Marie
        if 'prix' in marie_response.lower() or 'coût' in marie_response.lower():
            # Privilégier les templates qui parlent de budget/prix
            price_templates = [t for t in templates if any(word in t for word in ['{pourcentage}', 'budget', 'échelonnement'])]
            templates = price_templates if price_templates else templates
        
        elif 'référence' in marie_response.lower() or 'exemple' in marie_response.lower():
            # Privilégier les templates avec références
            ref_templates = [t for t in templates if 'références' in t or 'entreprises' in t]
            templates = ref_templates if ref_templates else templates
        
        return random.choice(templates)
    
    def _personalize_template(self, template: str, marie_state: Dict) -> str:
        """Personnalise le template avec des valeurs contextuelles"""
        
        replacements = {
            '{roi}': str(random.choice([150, 200, 250, 300])),
            '{timeline}': str(random.choice([3, 6, 9, 12])),
            '{features}': random.choice(['leads qualifiés', 'opportunités commerciales', 'campagnes marketing']),
            '{references}': str(random.choice([250, 350, 500, 750])),
            '{solution_specifique}': random.choice(['module de sécurité renforcée', 'API d\'intégration personnalisée', 'support dédié']),
            '{nb_mois}': str(random.choice([12, 18, 24, 36])),
            '{avantage_commercial}': random.choice(['formation gratuite', 'support étendu', 'modules bonus']),
            '{pourcentage}': str(random.choice([10, 15, 20, 25])),
            '{duree}': random.choice(['2 ans', '3 ans', '5 ans'])
        }
        
        for placeholder, value in replacements.items():
            template = template.replace(placeholder, value)
        
        return template
    
    def _add_realism_variations(self, message: str, phase: str) -> str:
        """Ajoute des variations réalistes au message"""
        
        # Variations selon le niveau de réalisme
        if self.realism_level > 0.8:
            # Ajouter des hésitations, reformulations
            connectors = [
                "En fait, ",
                "D'ailleurs, ",
                "Permettez-moi de préciser que ",
                "Ce qui est important c'est que "
            ]
            
            if random.random() < 0.3:  # 30% de chance d'ajouter un connecteur
                message = random.choice(connectors) + message.lower()
        
        if self.realism_level > 0.7:
            # Ajouter des éléments de langage commercial
            endings = [
                " N'est-ce pas exactement ce que vous cherchez ?",
                " Qu'en pensez-vous ?",
                " Cela répond-il à vos attentes ?",
                " Avez-vous des questions là-dessus ?"
            ]
            
            if random.random() < 0.4 and phase != 'closing':  # 40% de chance sauf pour la clôture
                message += random.choice(endings)
        
        return message

class RealConversationManager:
    """Gestionnaire principal des conversations réelles avec Marie"""
    
    def __init__(self, config: RealConversationConfig = None):
        self.config = config or RealConversationConfig()
        
        # Initialiser les composants
        self.marie = marie_character
        self.user_generator = UserMessageGenerator(self.config.user_simulation_realism)
        self.metrics_collector = ConversationMetricsCollector()
        self.auto_repair = AutoRepairSystem()
        
        # Services réels
        self.tts_service = RealTTSService(base_url="http://localhost:5002")
        self.vosk_service = RealVoskService(base_url="http://localhost:2700")
        self.mistral_service = RealMistralService(api_key=None, model="mistral-nemo-instruct-2407")
        
        # État de la conversation
        self.conversation_active = True
        self.current_exchange = 0
        self.conversation_start_time = None
        self.exchange_results: List[RealExchangeResult] = []
        
        # Configuration Marie avec intensité personnalisée
        self._configure_marie_intensity()
        
    def _configure_marie_intensity(self):
        """Configure l'intensité de la personnalité de Marie"""
        
        intensity = self.config.marie_personality_intensity
        
        # Ajuster les seuils de Marie selon l'intensité
        if intensity >= 0.8:  # Très exigeante
            self.marie.patience_level = 0.6
            self.marie.satisfaction_level = 0.3
        elif intensity >= 0.6:  # Moyennement exigeante
            self.marie.patience_level = 0.7
            self.marie.satisfaction_level = 0.4
        else:  # Plus accommodante
            self.marie.patience_level = 0.8
            self.marie.satisfaction_level = 0.5
    
    async def start_real_conversation(self) -> Dict[str, Any]:
        """Lance une conversation réelle complète avec Marie"""
        
        logger.info("=== DÉBUT CONVERSATION RÉELLE AVEC MARIE ===")
        self.conversation_start_time = time.time()
        
        try:
            # Validation des services
            await self._validate_services()
            
            # Réinitialiser Marie pour une nouvelle conversation
            self.marie.reset_conversation()
            self._configure_marie_intensity()
            
            # Boucle principale de conversation
            marie_last_response = ""
            
            while (self.conversation_active and 
                   self.current_exchange < self.config.max_exchanges and
                   time.time() - self.conversation_start_time < self.config.max_conversation_time):
                
                try:
                    # Exécuter un échange complet
                    exchange_result = await self._execute_real_exchange(marie_last_response)
                    
                    # Enregistrer le résultat
                    self.exchange_results.append(exchange_result)
                    
                    # Auto-réparation si nécessaire
                    if exchange_result.issues_detected and self.config.enable_auto_repair:
                        await self._handle_exchange_issues(exchange_result)
                    
                    # Préparer pour le prochain échange
                    marie_last_response = exchange_result.marie_response_text
                    self.current_exchange += 1
                    
                    # Vérifier si la conversation doit continuer
                    self.conversation_active = self._should_continue_conversation(exchange_result)
                    
                    # Log de progression
                    logger.info(f"Échange {exchange_result.exchange_number} terminé - "
                              f"Marie satisfaction: {exchange_result.marie_state.get('satisfaction_level', 0):.2f}, "
                              f"Temps: {exchange_result.total_exchange_time:.1f}s")
                
                except Exception as e:
                    logger.error(f"Erreur dans l'échange {self.current_exchange + 1}: {e}")
                    
                    if self.config.enable_auto_repair:
                        repair_success = await self._emergency_repair(str(e))
                        if not repair_success:
                            break
                    else:
                        break
            
            # Générer le rapport final
            final_report = await self._generate_conversation_report()
            
            conversation_duration = time.time() - self.conversation_start_time
            logger.info(f"=== CONVERSATION TERMINÉE ===")
            logger.info(f"Échanges: {len(self.exchange_results)}, Durée: {conversation_duration:.1f}s")
            logger.info(f"Marie satisfaction finale: {self.marie.satisfaction_level:.2f}")
            
            return final_report
        
        except Exception as e:
            logger.error(f"Erreur critique dans la conversation: {e}")
            return await self._generate_error_report(str(e))
    
    async def _execute_real_exchange(self, marie_last_response: str) -> RealExchangeResult:
        """Exécute un échange complet en mode réel"""
        
        exchange_start = time.time()
        exchange_number = self.current_exchange + 1
        pipeline_times = {}
        issues_detected = []
        
        logger.info(f"\n--- ÉCHANGE RÉEL {exchange_number} ---")
        
        try:
            # Étape 1: Générer le message utilisateur contextuel
            step1_start = time.time()
            conversation_phase = self._determine_conversation_phase()
            marie_state = self.marie.get_marie_state_summary()
            
            user_message = self.user_generator.generate_contextual_message(
                marie_last_response, conversation_phase, marie_state['conversation_state']
            )
            pipeline_times['user_generation'] = time.time() - step1_start
            
            logger.info(f"Utilisateur: {user_message}")
            
            # Étape 2: Synthèse TTS du message utilisateur
            step2_start = time.time()
            try:
                user_tts_result = await self.tts_service.synthesize_speech(user_message, voice="onyx")
                user_audio_data = user_tts_result['audio_data']
                user_audio_duration = user_tts_result['audio_duration']
                user_audio_generated = True
                pipeline_times['user_tts'] = time.time() - step2_start
                
                logger.info(f"TTS Utilisateur: {len(user_audio_data)} bytes, {user_audio_duration:.1f}s")
            except Exception as e:
                pipeline_times['user_tts'] = time.time() - step2_start
                issues_detected.append(f"user_tts_error: {str(e)}")
                user_audio_data = b""
                user_audio_duration = 0.0
                user_audio_generated = False
            
            # Étape 3: Transcription VOSK
            step3_start = time.time()
            try:
                vosk_result = await self.vosk_service.transcribe_audio(
                    user_audio_data,
                    {'scenario_type': 'real_conversation', 'user_message': user_message}
                )
                vosk_transcription = vosk_result['text']
                vosk_confidence = vosk_result['confidence']
                pipeline_times['vosk_transcription'] = time.time() - step3_start
                
                logger.info(f"VOSK: '{vosk_transcription}' (conf={vosk_confidence:.2f})")
            except Exception as e:
                pipeline_times['vosk_transcription'] = time.time() - step3_start
                issues_detected.append(f"vosk_error: {str(e)}")
                vosk_transcription = user_message  # Fallback au texte original
                vosk_confidence = 0.5
            
            # Étape 4: Analyse par Marie et génération de réponse
            step4_start = time.time()
            try:
                # Marie analyse l'input
                marie_analysis = self.marie.analyze_user_input(
                    vosk_transcription, 
                    {'total_time': time.time() - self.conversation_start_time}
                )
                
                # Marie génère sa réponse
                marie_response_data = self.marie.generate_marie_response(vosk_transcription, marie_analysis)
                marie_response_text = marie_response_data['response']
                
                # Ajouter question de suivi si pertinent
                if marie_response_data['follow_up_question']:
                    marie_response_text += " " + marie_response_data['follow_up_question']
                
                pipeline_times['marie_processing'] = time.time() - step4_start
                logger.info(f"Marie: {marie_response_text}")
            except Exception as e:
                pipeline_times['marie_processing'] = time.time() - step4_start
                issues_detected.append(f"marie_error: {str(e)}")
                marie_response_text = "Je vous prie de m'excuser, pouvez-vous répéter ?"
                marie_response_data = {'marie_satisfaction': 0.3, 'marie_interest': 0.3}
            
            # Étape 5: Appel Mistral pour enrichir la réponse de Marie
            step5_start = time.time()
            try:
                mistral_result = await self.mistral_service.generate_response(
                    f"L'utilisateur dit: '{vosk_transcription}'. En tant que Marie, directrice commerciale exigeante, répondez: {marie_response_text}",
                    "real_conversation_marie",
                    {
                        'marie_mode': marie_response_data.get('conversation_mode', 'evaluation_initiale'),
                        'marie_satisfaction': marie_response_data.get('marie_satisfaction', 0.5),
                        'conversation_turn': exchange_number
                    }
                )
                
                # Utiliser la réponse Mistral si elle est de qualité
                mistral_response = mistral_result['response']
                if len(mistral_response) > 10 and mistral_result.get('quality_metrics', {}).get('overall_quality', 0) > 0.6:
                    marie_response_text = mistral_response
                
                pipeline_times['mistral_enhancement'] = time.time() - step5_start
                logger.info(f"Marie (Mistral): {marie_response_text}")
            except Exception as e:
                pipeline_times['mistral_enhancement'] = time.time() - step5_start
                issues_detected.append(f"mistral_error: {str(e)}")
                # Garder la réponse de Marie sans enrichissement Mistral
            
            # Étape 6: Synthèse TTS de la réponse de Marie
            step6_start = time.time()
            try:
                marie_tts_result = await self.tts_service.synthesize_speech(marie_response_text, voice="nova")
                marie_audio_data = marie_tts_result['audio_data']
                marie_audio_duration = marie_tts_result['audio_duration']
                marie_audio_generated = True
                pipeline_times['marie_tts'] = time.time() - step6_start
                
                logger.info(f"TTS Marie: {len(marie_audio_data)} bytes, {marie_audio_duration:.1f}s")
            except Exception as e:
                pipeline_times['marie_tts'] = time.time() - step6_start
                issues_detected.append(f"marie_tts_error: {str(e)}")
                marie_audio_data = b""
                marie_audio_duration = 0.0
                marie_audio_generated = False
            
            # Étape 7: Collecter les métriques
            total_exchange_time = time.time() - exchange_start
            
            # Calculer les scores de qualité
            quality_scores = self._calculate_quality_scores(
                user_message, vosk_transcription, vosk_confidence,
                marie_response_text, marie_response_data, total_exchange_time
            )
            
            # Sauvegarder les audios si configuré
            if self.config.save_conversation_audio:
                await self._save_exchange_audio(exchange_number, user_audio_data, marie_audio_data)
            
            # Créer le résultat de l'échange
            exchange_result = RealExchangeResult(
                exchange_number=exchange_number,
                user_message_text=user_message,
                user_audio_generated=user_audio_generated,
                user_audio_duration=user_audio_duration,
                vosk_transcription=vosk_transcription,
                vosk_confidence=vosk_confidence,
                marie_response_text=marie_response_text,
                marie_audio_generated=marie_audio_generated,
                marie_audio_duration=marie_audio_duration,
                total_exchange_time=total_exchange_time,
                pipeline_times=pipeline_times,
                marie_state=self.marie.get_marie_state_summary(),
                quality_scores=quality_scores,
                issues_detected=issues_detected,
                repairs_applied=[],
                success=len(issues_detected) < 3  # Succès si moins de 3 problèmes
            )
            
            return exchange_result
        
        except Exception as e:
            # Créer un résultat d'échec
            total_time = time.time() - exchange_start
            
            return RealExchangeResult(
                exchange_number=exchange_number,
                user_message_text=user_message if 'user_message' in locals() else "",
                user_audio_generated=False,
                user_audio_duration=0.0,
                vosk_transcription="",
                vosk_confidence=0.0,
                marie_response_text="",
                marie_audio_generated=False,
                marie_audio_duration=0.0,
                total_exchange_time=total_time,
                pipeline_times=pipeline_times,
                marie_state=self.marie.get_marie_state_summary(),
                quality_scores={},
                issues_detected=[f"critical_error: {str(e)}"],
                repairs_applied=[],
                success=False
            )
    
    def _determine_conversation_phase(self) -> str:
        """Détermine la phase actuelle de la conversation"""
        
        if self.current_exchange == 0:
            return "opening"
        elif self.current_exchange < 3:
            return "presentation"
        elif self.marie.satisfaction_level < 0.4:
            return "objection_handling"
        elif self.marie.satisfaction_level > 0.7:
            return "closing"
        else:
            return "negotiation"
    
    def _calculate_quality_scores(self, user_msg: str, transcription: str, vosk_conf: float,
                                 marie_response: str, marie_data: Dict, exchange_time: float) -> Dict[str, float]:
        """Calcule les scores de qualité de l'échange"""
        
        # Score de transcription
        transcription_score = vosk_conf
        
        # Score de pertinence de Marie
        marie_relevance = len(set(user_msg.lower().split()) & set(marie_response.lower().split())) / max(len(user_msg.split()), 1)
        
        # Score de performance temporelle
        time_score = max(0.0, 1.0 - (exchange_time - 20.0) / 30.0)  # Idéal 20s, dégradé après 50s
        
        # Score global de conversation
        conversation_score = (self.marie.satisfaction_level + self.marie.interest_level) / 2.0
        
        return {
            'transcription_quality': transcription_score,
            'marie_relevance': marie_relevance,
            'time_performance': time_score,
            'conversation_progression': conversation_score,
            'overall_exchange_quality': (transcription_score + marie_relevance + time_score + conversation_score) / 4.0
        }
    
    async def _save_exchange_audio(self, exchange_num: int, user_audio: bytes, marie_audio: bytes):
        """Sauvegarde les fichiers audio de l'échange"""
        
        try:
            audio_dir = Path("conversation_audio")
            audio_dir.mkdir(exist_ok=True)
            
            timestamp = int(time.time())
            
            if user_audio:
                user_path = audio_dir / f"user_exchange_{exchange_num}_{timestamp}.wav"
                with open(user_path, 'wb') as f:
                    f.write(user_audio)
            
            if marie_audio:
                marie_path = audio_dir / f"marie_exchange_{exchange_num}_{timestamp}.wav"
                with open(marie_path, 'wb') as f:
                    f.write(marie_audio)
        
        except Exception as e:
            logger.warning(f"Impossible de sauvegarder l'audio: {e}")
    
    async def _validate_services(self):
        """Valide que tous les services sont opérationnels"""
        
        logger.info("Validation des services pour conversation réelle...")
        
        # Test TTS
        try:
            await self.tts_service.synthesize_speech("Test de validation")
            logger.info("✓ Service TTS opérationnel")
        except Exception as e:
            raise RuntimeError(f"Service TTS non opérationnel: {e}")
        
        # Test VOSK
        try:
            vosk_healthy = await self.vosk_service._check_health()
            if vosk_healthy:
                logger.info("✓ Service VOSK opérationnel")
            else:
                raise RuntimeError("Service VOSK non sain")
        except Exception as e:
            raise RuntimeError(f"Service VOSK non opérationnel: {e}")
        
        # Test Mistral
        try:
            await self.mistral_service.generate_response(
                "Test de validation", 
                "test", 
                {'conversation_phase': 'validation'}
            )
            logger.info("✓ Service Mistral opérationnel")
        except Exception as e:
            raise RuntimeError(f"Service Mistral non opérationnel: {e}")
        
        logger.info("Tous les services sont validés pour la conversation réelle")
    
    async def _handle_exchange_issues(self, exchange_result: RealExchangeResult):
        """Gère les problèmes détectés dans un échange"""
        
        for issue in exchange_result.issues_detected:
            logger.warning(f"Traitement du problème: {issue}")
            
            repair_result = self.auto_repair.repair_issue(
                issue,
                self.marie.current_mode.value,
                {
                    'exchange_number': exchange_result.exchange_number,
                    'marie_state': exchange_result.marie_state
                }
            )
            
            if repair_result['success']:
                exchange_result.repairs_applied.append(repair_result['strategy_used'])
                logger.info(f"Réparation réussie: {repair_result['strategy_used']}")
            else:
                logger.error(f"Échec réparation pour: {issue}")
    
    async def _emergency_repair(self, error: str) -> bool:
        """Tentative de réparation d'urgence"""
        
        logger.error(f"Réparation d'urgence pour: {error}")
        
        repair_result = self.auto_repair.repair_issue(
            f'critical_error: {error}',
            self.marie.current_mode.value,
            {'emergency': True}
        )
        
        return repair_result['success']
    
    def _should_continue_conversation(self, exchange_result: RealExchangeResult) -> bool:
        """Détermine si la conversation doit continuer"""
        
        # Arrêter si trop de problèmes critiques
        critical_issues = [issue for issue in exchange_result.issues_detected if 'critical' in issue or 'error' in issue]
        if len(critical_issues) > 1:
            logger.info("Trop de problèmes critiques, arrêt de la conversation")
            return False
        
        # Arrêter si Marie est en mode clôture
        if self.marie.current_mode.value == 'cloture_decision':
            logger.info("Marie a pris sa décision, fin de conversation")
            return False
        
        # Arrêter si satisfaction très faible depuis trop longtemps
        if (self.marie.satisfaction_level < 0.2 and 
            self.current_exchange >= 5):
            logger.info("Satisfaction Marie trop faible, arrêt de conversation")
            return False
        
        # Arrêter si temps d'échange trop long de manière répétée
        if exchange_result.total_exchange_time > self.config.max_exchange_time:
            recent_slow_exchanges = sum(1 for ex in self.exchange_results[-3:] 
                                      if ex.total_exchange_time > self.config.max_exchange_time)
            if recent_slow_exchanges >= 2:
                logger.info("Échanges trop lents de manière répétée, arrêt")
                return False
        
        return True
    
    async def _generate_conversation_report(self) -> Dict[str, Any]:
        """Génère le rapport final de la conversation réelle"""
        
        conversation_duration = time.time() - self.conversation_start_time
        
        # Statistiques globales
        total_exchanges = len(self.exchange_results)
        successful_exchanges = sum(1 for ex in self.exchange_results if ex.success)
        
        # Moyennes de performance
        avg_exchange_time = sum(ex.total_exchange_time for ex in self.exchange_results) / total_exchanges if total_exchanges > 0 else 0
        avg_quality = sum(ex.quality_scores.get('overall_exchange_quality', 0) for ex in self.exchange_results) / total_exchanges if total_exchanges > 0 else 0
        
        # Progression de Marie
        marie_final_state = self.marie.get_marie_state_summary()
        
        # Analyse du pipeline
        pipeline_performance = self._analyze_pipeline_performance()
        
        return {
            'conversation_metadata': {
                'start_time': self.conversation_start_time,
                'duration': conversation_duration,
                'total_exchanges': total_exchanges,
                'successful_exchanges': successful_exchanges,
                'success_rate': successful_exchanges / total_exchanges if total_exchanges > 0 else 0,
                'conversation_mode': 'real_conversation_with_marie'
            },
            'marie_evolution': {
                'initial_state': {
                    'satisfaction': 0.5,
                    'interest': 0.3,
                    'patience': 0.8
                },
                'final_state': marie_final_state['conversation_state'],
                'conversation_progression': marie_final_state['conversation_quality']['progression'],
                'decision_reached': marie_final_state['conversation_state']['mode_actuel'] == 'cloture_decision'
            },
            'performance_metrics': {
                'avg_exchange_time': avg_exchange_time,
                'avg_quality_score': avg_quality,
                'pipeline_performance': pipeline_performance,
                'total_issues_detected': sum(len(ex.issues_detected) for ex in self.exchange_results),
                'total_repairs_applied': sum(len(ex.repairs_applied) for ex in self.exchange_results)
            },
            'exchange_details': [asdict(ex) for ex in self.exchange_results],
            'conversation_summary': {
                'outcome': self._determine_conversation_outcome(),
                'key_insights': self._extract_key_insights(),
                'recommendations': self._generate_recommendations()
            }
        }
    
    def _analyze_pipeline_performance(self) -> Dict[str, Any]:
        """Analyse les performances du pipeline"""
        
        if not self.exchange_results:
            return {'no_data': True}
        
        # Moyennes des temps par étape
        avg_times = {}
        all_pipeline_times = [ex.pipeline_times for ex in self.exchange_results if ex.pipeline_times]
        
        if all_pipeline_times:
            steps = all_pipeline_times[0].keys()
            for step in steps:
                times = [pt[step] for pt in all_pipeline_times if step in pt]
                avg_times[step] = sum(times) / len(times) if times else 0
        
        # Taux de succès par composant
        tts_success_rate = sum(1 for ex in self.exchange_results if ex.user_audio_generated and ex.marie_audio_generated) / len(self.exchange_results)
        vosk_success_rate = sum(1 for ex in self.exchange_results if ex.vosk_confidence > 0.5) / len(self.exchange_results)
        
        return {
            'average_step_times': avg_times,
            'component_success_rates': {
                'tts_success_rate': tts_success_rate,
                'vosk_success_rate': vosk_success_rate,
                'overall_pipeline_success': sum(1 for ex in self.exchange_results if ex.success) / len(self.exchange_results)
            }
        }
    
    def _determine_conversation_outcome(self) -> str:
        """Détermine le résultat final de la conversation"""
        
        marie_satisfaction = self.marie.satisfaction_level
        marie_mode = self.marie.current_mode.value
        
        if marie_mode == 'cloture_decision' and marie_satisfaction > 0.8:
            return "accord_conclu"
        elif marie_mode == 'cloture_decision' and marie_satisfaction > 0.6:
            return "decision_reportee"
        elif marie_satisfaction < 0.3:
            return "echec_commercial"
        elif marie_satisfaction > 0.6:
            return "progression_positive"
        else:
            return "conversation_neutre"
    
    def _extract_key_insights(self) -> List[str]:
        """Extrait les insights clés de la conversation"""
        
        insights = []
        
        # Insights sur la progression de Marie
        if self.marie.satisfaction_level > 0.7:
            insights.append("Marie a montré un intérêt croissant pour la solution proposée")
        elif self.marie.satisfaction_level < 0.4:
            insights.append("Marie est restée sceptique malgré les arguments présentés")
        
        # Insights sur la performance du pipeline
        avg_exchange_time = sum(ex.total_exchange_time for ex in self.exchange_results) / len(self.exchange_results)
        if avg_exchange_time > 30:
            insights.append("Les échanges sont plus longs que l'optimal, optimisation nécessaire")
        
        # Insights sur les problèmes récurrents
        all_issues = [issue for ex in self.exchange_results for issue in ex.issues_detected]
        if len(all_issues) > len(self.exchange_results) * 0.5:
            insights.append("Problèmes techniques fréquents détectés dans le pipeline")
        
        return insights
    
    def _generate_recommendations(self) -> List[str]:
        """Génère des recommandations d'amélioration"""
        
        recommendations = []
        
        # Recommandations basées sur la performance
        avg_quality = sum(ex.quality_scores.get('overall_exchange_quality', 0) for ex in self.exchange_results) / len(self.exchange_results)
        if avg_quality < 0.7:
            recommendations.append("Améliorer la qualité globale des échanges")
        
        # Recommandations basées sur Marie
        if self.marie.satisfaction_level < 0.5:
            recommendations.append("Adapter la stratégie commerciale pour mieux convaincre Marie")
        
        return recommendations
    
    async def _generate_error_report(self, error: str) -> Dict[str, Any]:
        """Génère un rapport d'erreur"""
        
        return {
            'error': True,
            'error_message': error,
            'conversation_duration': time.time() - self.conversation_start_time if self.conversation_start_time else 0,
            'exchanges_completed': len(self.exchange_results),
            'partial_results': [asdict(ex) for ex in self.exchange_results],
            'marie_final_state': self.marie.get_marie_state_summary(),
            'timestamp': time.time()
        }

# Point d'entrée principal
async def main():
    """Fonction principale pour lancer une conversation réelle avec Marie"""
    
    print("Conversation Réelle avec Marie - Directrice Commerciale")
    print("=" * 60)
    
    # Configuration de la conversation
    config = RealConversationConfig(
        max_exchanges=8,
        max_conversation_time=480.0,  # 8 minutes
        marie_personality_intensity=0.8,  # Marie très exigeante
        user_simulation_realism=0.9,
        enable_auto_repair=True,
        save_conversation_audio=True
    )
    
    # Créer et lancer le gestionnaire
    manager = RealConversationManager(config)
    
    try:
        # Lancer la conversation
        report = await manager.start_real_conversation()
        
        # Sauvegarder le rapport
        timestamp = int(time.time())
        report_filename = f'real_conversation_marie_{timestamp}.json'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\nRapport sauvegardé: {report_filename}")
        
        # Afficher le résumé
        if not report.get('error'):
            metadata = report['conversation_metadata']
            marie_final = report['marie_evolution']['final_state']
            
            print(f"\nRÉSUMÉ DE LA CONVERSATION:")
            print(f"Durée totale: {metadata['duration']:.1f}s")
            print(f"Échanges réalisés: {metadata['total_exchanges']}")
            print(f"Taux de succès: {metadata['success_rate']:.1%}")
            print(f"Marie satisfaction finale: {marie_final['satisfaction_level']:.2f}")
            print(f"Marie intérêt final: {marie_final['interest_level']:.2f}")
            print(f"Résultat: {report['conversation_summary']['outcome']}")
            
            # Insights clés
            insights = report['conversation_summary']['key_insights']
            if insights:
                print(f"\nINSIGHTS CLÉS:")
                for i, insight in enumerate(insights, 1):
                    print(f"{i}. {insight}")
        else:
            print(f"ERREUR: {report['error_message']}")
        
        return True
    
    except Exception as e:
        print(f"ERREUR CRITIQUE: {e}")
        return False

if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())