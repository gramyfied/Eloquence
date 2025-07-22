#!/usr/bin/env python3
"""
Real Conversation Launcher - Script de lancement principal pour conversation réelle avec Marie

Ce script lance une conversation interactive en temps réel avec Marie, une IA ayant la personnalité
d'une directrice commerciale exigeante. Il utilise le pipeline complet :
TTS localhost:5002 → VOSK localhost:2700 → Mistral API Scaleway → TTS localhost:5002

Fonctionnalités principales :
- Validation complète des services requis
- Interface de contrôle utilisateur interactive  
- Lancement automatique de la conversation avec Marie
- Monitoring en temps réel des métriques
- Gestion des erreurs et auto-réparation
- Rapport final détaillé

Usage:
    python real_conversation_launcher.py [options]
    
Options:
    --max-exchanges N       Nombre maximum d'échanges (défaut: 10)
    --marie-intensity F     Intensité personnalité Marie 0.0-1.0 (défaut: 0.8)
    --user-realism F        Niveau réalisme utilisateur 0.0-1.0 (défaut: 0.7)
    --save-audio           Sauvegarder les fichiers audio
    --no-validation        Ignorer validation services (mode debug)
    --config-file PATH     Fichier configuration personnalisée
    --quiet                Mode silencieux (logs minimaux)
    --interactive          Mode interactif avec contrôles utilisateur
"""

import sys
import os
import argparse
import asyncio
import signal
import json
import time
import threading
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional, List
import logging

# Import des composants conversation réelle
from service_validator import ServiceValidator, ServiceValidationResult
from real_conversation_manager import RealConversationManager, RealConversationConfig
from marie_ai_character import MarieAICharacter
from service_wrappers import RealTTSService, RealVoskService, RealMistralService
from conversation_engine import AutoRepairSystem
from interactive_conversation_tester import ConversationMetricsCollector as MetricsCollector

class ConversationLauncherError(Exception):
    """Erreur spécifique au lanceur de conversation"""
    pass

class RealConversationLauncher:
    """
    Lanceur principal pour conversations réelles avec Marie
    
    Responsabilités :
    - Validation pré-lancement de tous les services
    - Configuration et initialisation des composants
    - Orchestration du pipeline conversation complète
    - Interface de contrôle utilisateur
    - Monitoring temps réel et gestion erreurs
    - Génération rapports finaux
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialise le lanceur avec configuration optionnelle
        
        Args:
            config: Configuration personnalisée pour la conversation
        """
        self.config = config or {}
        self.start_time = None
        self.end_time = None
        self.is_running = False
        self.conversation_manager = None
        self.validator = None
        self.validation_results = None
        self.metrics_collector = None
        self.marie_character = None
        self.services = {}
        self.conversation_thread = None
        self.monitoring_active = False
        
        # Configuration logging
        self._setup_logging()
        
        # Gestionnaire signaux pour arrêt propre
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        self.logger.info("RealConversationLauncher initialisé")
    
    def _setup_logging(self):
        """Configure le système de logging"""
        log_level = logging.DEBUG if self.config.get('debug', False) else logging.INFO
        if self.config.get('quiet', False):
            log_level = logging.WARNING
            
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler(f'conversation_launcher_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def _signal_handler(self, signum, frame):
        """Gestionnaire pour arrêt propre sur signal système"""
        self.logger.info(f"Signal {signum} reçu, arrêt en cours...")
        self.stop_conversation()
        sys.exit(0)
    
    async def validate_environment(self) -> Dict[str, Any]:
        """
        Valide l'environnement et tous les services requis
        
        Returns:
            Dict[str, Any]: Résultat complet de validation
        """
        self.logger.info("Début validation environnement...")
        
        self.validator = ServiceValidator()
        self.validation_results = await self.validator.validate_all_services()
        
        # Vérifier si l'environnement est prêt
        readiness = self.validation_results.get('readiness_assessment', {})
        is_ready = readiness.get('ready_for_marie_conversation', False)
        
        if not is_ready:
            self.logger.error("Validation échouée:")
            
            # Récupérer les actions immédiates comme "issues"
            immediate_actions = self.validation_results.get('recommendations', {}).get('immediate_actions', [])
            for issue in immediate_actions:
                self.logger.error(f"  - {issue}")
            
            self.logger.info("Recommandations:")
            all_recommendations = self.validation_results.get('recommendations', {}).get('all_recommendations', [])
            for rec in all_recommendations[:3]:  # Limiter à 3 recommandations
                self.logger.info(f"  + {rec}")
            
            # Obtenir le score de santé
            global_metrics = self.validation_results.get('global_metrics', {})
            health_score = global_metrics.get('average_health_score', 0) * 100
            
            raise ConversationLauncherError(
                f"Environnement non prêt pour conversation réelle. "
                f"Score santé: {health_score:.1f}%"
            )
        
        # Obtenir le score de santé pour le message de succès
        global_metrics = self.validation_results.get('global_metrics', {})
        health_score = global_metrics.get('average_health_score', 0) * 100
        
        self.logger.info(f"Validation réussie! Score santé: {health_score:.1f}%")
        return self.validation_results
    
    def _initialize_services(self):
        """Initialise tous les services requis pour la conversation"""
        self.logger.info("Initialisation des services...")
        
        # Services de base - utiliser uniquement les arguments supportés par les constructeurs
        self.services['tts'] = RealTTSService(
            base_url="http://localhost:5002"
        )
        
        self.services['vosk'] = RealVoskService(
            base_url="http://localhost:2700"
        )
        
        self.services['mistral'] = RealMistralService(
            api_key=None,  # Utilise la variable d'environnement MISTRAL_API_KEY
            model="mistral-nemo-instruct-2407"
        )
        
        # Collecteur de métriques
        self.metrics_collector = MetricsCollector()
        
        # Système auto-réparation
        auto_repair = AutoRepairSystem()
        
        # Caractère Marie AI
        self.marie_character = MarieAICharacter()
        
        # Configurer l'intensité manuellement après création
        intensity = self.config.get('marie_intensity', 0.8)
        self.marie_character.satisfaction_level = 0.5 - (intensity - 0.8) * 0.2  # Plus exigeante = moins satisfaite au début
        self.marie_character.patience_level = 0.8 - (intensity - 0.8) * 0.3      # Plus exigeante = moins patiente
        
        self.logger.info("Services initialisés avec succès")
    
    def _create_conversation_config(self) -> RealConversationConfig:
        """
        Crée la configuration pour la conversation réelle
        
        Returns:
            RealConversationConfig: Configuration optimisée
        """
        return RealConversationConfig(
            max_exchanges=self.config.get('max_exchanges', 10),
            max_conversation_time=self.config.get('max_conversation_time', 600.0),
            max_exchange_time=self.config.get('exchange_timeout', 45.0),
            enable_auto_repair=True,
            enable_real_time_monitoring=True,
            save_conversation_audio=self.config.get('save_audio', False),
            marie_personality_intensity=self.config.get('marie_intensity', 0.8),
            user_simulation_realism=self.config.get('user_realism', 0.7)
        )
    
    async def start_conversation(self) -> Dict[str, Any]:
        """
        Lance la conversation complète avec Marie
        
        Returns:
            Dict[str, Any]: Rapport détaillé de la conversation
        """
        if self.is_running:
            raise ConversationLauncherError("Une conversation est déjà en cours")
        
        self.logger.info("Lancement conversation réelle avec Marie...")
        self.start_time = datetime.now()
        self.is_running = True
        
        try:
            # 1. Validation environnement
            if not self.config.get('no_validation', False):
                await self.validate_environment()
            
            # 2. Initialisation services
            self._initialize_services()
            
            # 3. Configuration conversation
            conversation_config = self._create_conversation_config()
            
            # 4. Création manager conversation
            self.conversation_manager = RealConversationManager(config=conversation_config)
            
            # 5. Lancement monitoring temps réel
            if self.config.get('interactive', False):
                self._start_monitoring_thread()
            
            # 6. Exécution conversation principale
            self.logger.info("Début conversation avec Marie...")
            conversation_result = await self.conversation_manager.start_real_conversation()
            
            # 7. Analyse résultats
            final_report = self._generate_final_report(conversation_result)
            
            self.logger.info("Conversation terminée avec succès")
            return final_report
            
        except Exception as e:
            self.logger.error(f"Erreur durant conversation: {e}")
            error_report = self._generate_error_report(e)
            return error_report
            
        finally:
            self.is_running = False
            self.end_time = datetime.now()
            self.monitoring_active = False
    
    def _start_monitoring_thread(self):
        """Lance le thread de monitoring temps réel"""
        self.monitoring_active = True
        self.conversation_thread = threading.Thread(
            target=self._monitoring_loop,
            daemon=True
        )
        self.conversation_thread.start()
        self.logger.info("Monitoring temps réel activé")
    
    def _monitoring_loop(self):
        """Boucle monitoring temps réel avec interface utilisateur"""
        print("\n" + "="*60)
        print("CONVERSATION RÉELLE AVEC MARIE - CONTRÔLES INTERACTIFS")
        print("="*60)
        print("Commandes disponibles:")
        print("  'status' - Afficher état conversation")
        print("  'metrics' - Métriques temps réel")
        print("  'marie' - État personnalité Marie")
        print("  'stop' - Arrêter conversation")
        print("  'help' - Afficher aide")
        print("="*60)
        
        while self.monitoring_active:
            try:
                # Interface simple non-bloquante
                print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Conversation en cours...")
                
                if self.conversation_manager and self.conversation_manager.metrics_collector:
                    current_metrics = self.conversation_manager.metrics_collector.get_current_session_summary()
                    print(f"Échanges: {current_metrics.get('total_exchanges', 0)} | "
                          f"Qualité moy: {current_metrics.get('average_quality', 0):.2f} | "
                          f"Erreurs: {current_metrics.get('total_errors', 0)}")
                
                time.sleep(5)  # Update toutes les 5 secondes
                
            except Exception as e:
                self.logger.error(f"Erreur monitoring: {e}")
                break
    
    def _generate_final_report(self, conversation_result: Dict[str, Any]) -> Dict[str, Any]:
        """
        Génère le rapport final détaillé de la conversation
        
        Args:
            conversation_result: Résultats de la conversation
            
        Returns:
            Dict[str, Any]: Rapport complet structuré
        """
        duration = (self.end_time - self.start_time).total_seconds() if self.end_time and self.start_time else 0
        
        final_report = {
            'conversation_session': {
                'session_id': conversation_result.get('session_id'),
                'start_time': self.start_time.isoformat() if self.start_time else None,
                'end_time': self.end_time.isoformat() if self.end_time else None,
                'total_duration_seconds': duration,
                'status': 'completed' if conversation_result.get('success', False) else 'failed'
            },
            'marie_character_analysis': {
                'personality_evolution': conversation_result.get('marie_analysis', {}),
                'final_satisfaction_level': conversation_result.get('marie_final_satisfaction', 0),
                'conversation_modes_used': conversation_result.get('marie_modes_progression', []),
                'key_personality_moments': conversation_result.get('marie_key_moments', [])
            },
            'pipeline_performance': {
                'total_exchanges_completed': conversation_result.get('total_exchanges', 0),
                'pipeline_success_rate': conversation_result.get('pipeline_success_rate', 0),
                'average_exchange_duration': conversation_result.get('average_exchange_duration', 0),
                'tts_performance': conversation_result.get('tts_metrics', {}),
                'vosk_performance': conversation_result.get('vosk_metrics', {}),
                'mistral_performance': conversation_result.get('mistral_metrics', {})
            },
            'quality_metrics': {
                'overall_conversation_quality': conversation_result.get('overall_quality', 0),
                'transcription_accuracy': conversation_result.get('transcription_accuracy', 0),
                'marie_response_relevance': conversation_result.get('marie_relevance', 0),
                'user_simulation_realism': conversation_result.get('user_realism', 0)
            },
            'technical_insights': {
                'auto_repair_interventions': conversation_result.get('auto_repair_count', 0),
                'service_health_scores': self.validation_results.get('service_validation_results', {}) if self.validation_results else {},
                'critical_errors_resolved': conversation_result.get('critical_errors_resolved', 0),
                'performance_bottlenecks': conversation_result.get('bottlenecks_identified', [])
            },
            'recommendations': {
                'marie_personality_tuning': conversation_result.get('marie_tuning_suggestions', []),
                'pipeline_optimizations': conversation_result.get('pipeline_optimizations', []),
                'configuration_improvements': conversation_result.get('config_suggestions', [])
            }
        }
        
        return final_report
    
    def _generate_error_report(self, error: Exception) -> Dict[str, Any]:
        """
        Génère un rapport d'erreur détaillé
        
        Args:
            error: Exception capturée
            
        Returns:
            Dict[str, Any]: Rapport d'erreur structuré
        """
        return {
            'conversation_session': {
                'status': 'error',
                'error_type': type(error).__name__,
                'error_message': str(error),
                'start_time': self.start_time.isoformat() if self.start_time else None,
                'failure_time': datetime.now().isoformat()
            },
            'diagnostic_info': {
                'validation_results': self.validation_results if self.validation_results else None,
                'services_initialized': list(self.services.keys()),
                'configuration_used': self.config
            },
            'recovery_suggestions': [
                "Vérifier que tous les services (TTS:5002, VOSK:2700) sont démarrés",
                "Valider les clés API (MISTRAL_API_KEY, SCALEWAY_API_KEY)",
                "Relancer avec --no-validation si problème de validation",
                "Consulter les logs détaillés pour diagnostic approfondi"
            ]
        }
    
    def stop_conversation(self):
        """Arrête proprement la conversation en cours"""
        if self.is_running and self.conversation_manager:
            self.logger.info("Arrêt conversation demandé...")
            self.monitoring_active = False
            # Le conversation_manager gère son propre arrêt
            self.is_running = False
        
        if self.conversation_thread and self.conversation_thread.is_alive():
            self.conversation_thread.join(timeout=5.0)
    
    def save_report(self, report: Dict[str, Any], filepath: Optional[str] = None):
        """
        Sauvegarde le rapport dans un fichier JSON
        
        Args:
            report: Rapport à sauvegarder
            filepath: Chemin optionnel (auto-généré si None)
        """
        if not filepath:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = f"conversation_marie_report_{timestamp}.json"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Rapport sauvegardé: {filepath}")

def parse_arguments():
    """Parse les arguments de ligne de commande"""
    parser = argparse.ArgumentParser(
        description="Lance une conversation réelle avec Marie AI Character",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples d'utilisation:
  # Conversation standard
  python real_conversation_launcher.py
  
  # Conversation intensive avec Marie très exigeante
  python real_conversation_launcher.py --marie-intensity 1.0 --max-exchanges 15
  
  # Mode debug avec sauvegarde audio
  python real_conversation_launcher.py --save-audio --debug --interactive
  
  # Configuration personnalisée
  python real_conversation_launcher.py --config-file custom_marie_config.json
        """
    )
    
    parser.add_argument('--max-exchanges', type=int, default=10,
                       help='Nombre maximum d\'échanges (défaut: 10)')
    parser.add_argument('--marie-intensity', type=float, default=0.8,
                       help='Intensité personnalité Marie 0.0-1.0 (défaut: 0.8)')
    parser.add_argument('--user-realism', type=float, default=0.7,
                       help='Niveau réalisme utilisateur 0.0-1.0 (défaut: 0.7)')
    parser.add_argument('--save-audio', action='store_true',
                       help='Sauvegarder les fichiers audio')
    parser.add_argument('--no-validation', action='store_true',
                       help='Ignorer validation services (mode debug)')
    parser.add_argument('--config-file', type=str,
                       help='Fichier configuration personnalisée')
    parser.add_argument('--quiet', action='store_true',
                       help='Mode silencieux (logs minimaux)')
    parser.add_argument('--debug', action='store_true',
                       help='Mode debug avec logs détaillés')
    parser.add_argument('--interactive', action='store_true',
                       help='Mode interactif avec contrôles utilisateur')
    parser.add_argument('--output', type=str,
                       help='Fichier de sortie pour le rapport')
    
    return parser.parse_args()

def load_config_file(filepath: str) -> Dict[str, Any]:
    """
    Charge un fichier de configuration JSON
    
    Args:
        filepath: Chemin vers le fichier de configuration
        
    Returns:
        Dict[str, Any]: Configuration chargée
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Erreur chargement configuration {filepath}: {e}")
        return {}

async def main():
    """Fonction principale du lanceur"""
    print("=" * 70)
    print("ELOQUENCE - CONVERSATION RÉELLE AVEC MARIE AI CHARACTER")
    print("=" * 70)
    print("Pipeline: TTS -> VOSK -> Mistral API Scaleway -> TTS")
    print("Personnalité: Directrice commerciale exigeante")
    print("=" * 70)
    
    # Parse arguments
    args = parse_arguments()
    
    # Configuration de base depuis arguments
    config = {
        'max_exchanges': args.max_exchanges,
        'marie_intensity': args.marie_intensity,
        'user_realism': args.user_realism,
        'save_audio': args.save_audio,
        'no_validation': args.no_validation,
        'quiet': args.quiet,
        'debug': args.debug,
        'interactive': args.interactive
    }
    
    # Chargement configuration personnalisée si spécifiée
    if args.config_file:
        file_config = load_config_file(args.config_file)
        config.update(file_config)
    
    # Création et lancement du lanceur
    launcher = RealConversationLauncher(config)
    
    try:
        # Lancement conversation
        report = await launcher.start_conversation()
        
        # Sauvegarde rapport
        output_file = args.output or f"marie_conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        launcher.save_report(report, output_file)
        
        # Affichage résumé final
        print("\n" + "=" * 70)
        print("CONVERSATION TERMINÉE")
        print("=" * 70)
        print(f"Statut: {report['conversation_session']['status']}")
        
        # Vérifier si les clés existent avant d'y accéder
        duration = report.get('conversation_session', {}).get('total_duration_seconds', 0)
        exchanges = report.get('pipeline_performance', {}).get('total_exchanges_completed', 0)
        quality = report.get('quality_metrics', {}).get('overall_conversation_quality', 0)
        
        print(f"Durée: {duration:.1f}s")
        print(f"Échanges: {exchanges}")
        print(f"Qualité: {quality:.2f}")
        print(f"Rapport: {output_file}")
        print("=" * 70)
        
        return 0
        
    except KeyboardInterrupt:
        print("\nArrêt demandé par utilisateur...")
        launcher.stop_conversation()
        return 1
        
    except Exception as e:
        print(f"\nErreur fatale: {e}")
        if config.get('debug'):
            import traceback
            traceback.print_exc()
        return 1
    
    finally:
        launcher.stop_conversation()

if __name__ == '__main__':
    sys.exit(asyncio.run(main()))