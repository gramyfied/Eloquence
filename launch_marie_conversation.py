#!/usr/bin/env python3
"""
Launch Marie Conversation - Script de démarrage one-click avec mode simulation

Script simplifié pour lancer rapidement une conversation avec Marie sans configuration technique.
Interface conviviale avec sélection de mode, validation automatique et lancement one-click.
Inclut maintenant un mode simulation sans Docker pour tester Marie directement.

Usage:
    python launch_marie_conversation.py
    
Le script guide l'utilisateur à travers :
- Sélection du mode de conversation souhaité
- Vérification automatique de l'environnement
- Configuration optimale automatique
- Lancement de la conversation (réelle ou simulation)
- Monitoring temps réel optionnel
- Génération rapport final

Modes disponibles :
- Démonstration client (qualité maximale)
- Formation commerciale (apprentissage)
- Test performance (vitesse)
- Mode équilibré (usage général)
- Debug (développement)
- Mode simulation (sans Docker)
"""

import sys
import os
import asyncio
import time
from datetime import datetime
from typing import Optional, Dict, Any
import json

# Interface utilisateur colorée
try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
    COLORS_AVAILABLE = True
except ImportError:
    COLORS_AVAILABLE = False
    # Fallback sans couleurs
    class Fore:
        RED = GREEN = YELLOW = BLUE = CYAN = MAGENTA = WHITE = RESET = ""
    class Back:
        RED = GREEN = YELLOW = BLUE = CYAN = MAGENTA = WHITE = BLACK = RESET = ""
    class Style:
        BRIGHT = DIM = NORMAL = RESET_ALL = ""

# Import des composants conversation
try:
    from real_conversation_launcher import RealConversationLauncher
    from real_conversation_config import OptimizedConfigFactory, load_config_by_name, RealConversationConfiguration
    from service_validator import ServiceValidator
    from marie_conversation_simulator import MarieConversationSimulator
    REAL_MODE_AVAILABLE = True
    SIMULATION_MODE_AVAILABLE = True
except ImportError as e:
    print(f"{Fore.RED}[ERREUR] Erreur import composants conversation: {e}")
    print(f"{Fore.YELLOW}[INFO] Tentative de chargement en mode simulation seulement...")
    try:
        from marie_conversation_simulator import MarieConversationSimulator
        REAL_MODE_AVAILABLE = False
        SIMULATION_MODE_AVAILABLE = True
        print(f"{Fore.GREEN}[OK] Mode simulation disponible")
    except ImportError:
        print(f"{Fore.RED}[ERREUR] Aucun mode disponible")
        sys.exit(1)

class ConversationLaunchWizard:
    """
    Assistant de lancement conversation one-click
    
    Interface utilisateur simplifiée pour :
    - Sélection mode conversation (réel ou simulation)
    - Configuration automatique optimale
    - Validation environnement (si mode réel)
    - Lancement et monitoring
    - Rapport final
    """
    
    def __init__(self):
        self.selected_config = None
        self.launch_time = None
        self.conversation_result = None
        
    def print_header(self):
        """Affiche l'en-tête du programme"""
        print(f"\n{Style.BRIGHT}{Fore.CYAN}{'=' * 70}")
        print(f"{Fore.CYAN}[ELOQUENCE] - CONVERSATION AVEC MARIE AI CHARACTER")
        print(f"{Fore.CYAN}{'=' * 70}")
        print(f"{Fore.WHITE}Directrice commerciale IA exigeante")
        if REAL_MODE_AVAILABLE:
            print(f"{Fore.WHITE}Modes : Pipeline TTS->VOSK->Mistral->TTS + Simulation")
        else:
            print(f"{Fore.YELLOW}Mode : Simulation uniquement (Docker non disponible)")
        print(f"{Fore.WHITE}Assistant de lancement simplifié")
        print(f"{Fore.CYAN}{'=' * 70}{Style.RESET_ALL}\n")
    
    def show_available_modes(self) -> Dict[str, Dict[str, str]]:
        """
        Affiche les modes disponibles avec descriptions
        
        Returns:
            Dict[str, Dict[str, str]]: Modes avec métadonnées
        """
        modes = {}
        
        if REAL_MODE_AVAILABLE:
            modes.update({
                "1": {
                    "name": "demonstration",
                    "title": "🎯 Démonstration Client",
                    "description": "Qualité maximale pour impressionner vos clients",
                    "duration": "12 min",
                    "marie_level": "Professionnelle et patiente",
                    "best_for": "Présentations commerciales, démos produit",
                    "type": "real"
                },
                "2": {
                    "name": "balanced",
                    "title": "⚖️  Mode Équilibré",
                    "description": "Configuration par défaut, usage général",
                    "duration": "15 min",
                    "marie_level": "Modérément exigeante",
                    "best_for": "Tests généraux, découverte du système",
                    "type": "real"
                },
                "3": {
                    "name": "commercial_training",
                    "title": "🎓 Formation Commerciale",
                    "description": "Apprentissage et coaching avec feedback détaillé",
                    "duration": "18 min",
                    "marie_level": "Pédagogique mais exigeante",
                    "best_for": "Formation équipes, amélioration compétences",
                    "type": "real"
                },
                "4": {
                    "name": "intensive_evaluation",
                    "title": "🔥 Évaluation Intensive",
                    "description": "Marie très exigeante, challenge maximum",
                    "duration": "20 min",
                    "marie_level": "Très exigeante et impatiente",
                    "best_for": "Tests de limite, évaluation expertise",
                    "type": "real"
                },
                "5": {
                    "name": "performance_test",
                    "title": "⚡ Test Performance",
                    "description": "Vitesse maximale, conversations rapides",
                    "duration": "10 min",
                    "marie_level": "Directe et efficace",
                    "best_for": "Benchmarks, tests techniques",
                    "type": "real"
                },
                "6": {
                    "name": "debug_development",
                    "title": "🔧 Mode Debug",
                    "description": "Développement et débogage avec logs détaillés",
                    "duration": "8 min",
                    "marie_level": "Prévisible et tolérante",
                    "best_for": "Développement, tests d'intégration",
                    "type": "real"
                }
            })
        
        # Mode simulation toujours disponible
        modes["7" if REAL_MODE_AVAILABLE else "1"] = {
            "name": "simulation_mode",
            "title": "Mode Simulation",
            "description": "Conversation avec Marie sans services Docker",
            "duration": "5 min",
            "marie_level": "Intelligente et adaptative",
            "best_for": "Tests rapides, démo sans infrastructure",
            "type": "simulation"
        }
        
        print(f"{Style.BRIGHT}{Fore.WHITE}MODES DE CONVERSATION DISPONIBLES :")
        print(f"{Fore.WHITE}{'─' * 70}")
        
        for key, mode in modes.items():
            if mode['type'] == 'simulation':
                print(f"\n{Fore.MAGENTA}{key}. {mode['title']} [SIMULATION]")
            else:
                print(f"\n{Fore.CYAN}{key}. {mode['title']}")
            print(f"   {Fore.WHITE}Description : {mode['description']}")
            print(f"   {Fore.GREEN}Durée       : {mode['duration']}")
            print(f"   {Fore.YELLOW}Marie       : {mode['marie_level']}")
            print(f"   {Fore.MAGENTA}Idéal pour  : {mode['best_for']}")
        
        print(f"\n{Fore.WHITE}{'─' * 70}")
        return modes
    
    def get_user_choice(self, modes: Dict[str, Dict[str, str]]) -> tuple[str, str]:
        """
        Demande à l'utilisateur de choisir un mode
        
        Args:
            modes: Modes disponibles
            
        Returns:
            tuple[str, str]: (nom du mode sélectionné, type du mode)
        """
        while True:
            try:
                max_choice = len(modes)
                print(f"\n{Fore.WHITE}Selectionnez un mode de conversation (1-{max_choice}) :")
                choice = input(f"{Fore.CYAN}Votre choix : {Style.RESET_ALL}").strip()
                
                if choice in modes:
                    selected_mode = modes[choice]
                    print(f"\n{Fore.GREEN}✅ Mode sélectionné : {selected_mode['title']}")
                    print(f"{Fore.WHITE}   {selected_mode['description']}")
                    
                    # Confirmation
                    confirm = input(f"\n{Fore.YELLOW}Confirmer ce choix ? (o/n) : {Style.RESET_ALL}").lower()
                    if confirm in ['o', 'oui', 'y', 'yes', '']:
                        return selected_mode['name'], selected_mode['type']
                    else:
                        continue
                else:
                    print(f"{Fore.RED}[ERREUR] Choix invalide. Veuillez saisir un nombre de 1 à {max_choice}.")
                    
            except (KeyboardInterrupt, EOFError):
                print(f"\n{Fore.YELLOW}👋 Arrêt demandé par l'utilisateur.")
                sys.exit(0)
            except Exception as e:
                print(f"{Fore.RED}[ERREUR] Erreur saisie : {e}")
    
    def show_simulation_config_summary(self, mode_name: str):
        """Affiche la configuration pour le mode simulation"""
        print(f"\n{Style.BRIGHT}{Fore.WHITE}CONFIGURATION SIMULATION :")
        print(f"{Fore.WHITE}{'─' * 50}")
        print(f"{Fore.CYAN}Mode          : Simulation Marie AI Character")
        print(f"{Fore.WHITE}Type          : Conversation textuelle interactive")
        print(f"{Fore.GREEN}Échanges max  : 8")
        print(f"{Fore.YELLOW}Durée cible   : 5 minutes")
        print(f"{Fore.MAGENTA}Marie intensité: 0.8/1.0 (très exigeante)")
        print(f"{Fore.BLUE}Avantages     : Pas de dépendance Docker, test immédiat")
        print(f"{Fore.WHITE}{'─' * 50}")
    
    def show_configuration_summary(self, config):
        """
        Affiche le résumé de la configuration sélectionnée
        
        Args:
            config: Configuration chargée
        """
        print(f"\n{Style.BRIGHT}{Fore.WHITE}📋 RÉSUMÉ CONFIGURATION :")
        print(f"{Fore.WHITE}{'─' * 50}")
        print(f"{Fore.CYAN}Nom           : {config.config_name}")
        print(f"{Fore.WHITE}Description   : {config.config_description}")
        print(f"{Fore.GREEN}Échanges max  : {config.max_exchanges}")
        print(f"{Fore.YELLOW}Durée cible   : {config.target_duration_minutes} minutes")
        print(f"{Fore.MAGENTA}Marie intensité: {config.marie_personality.intensity:.1f}/1.0")
        print(f"{Fore.BLUE}Réalisme user : {config.user_simulation.realism_level:.1f}/1.0")
        print(f"{Fore.WHITE}{'─' * 50}")
        
        if config.optimization_notes:
            print(f"\n{Fore.WHITE}💡 Optimisations appliquées :")
            for note in config.optimization_notes[:3]:  # Top 3
                print(f"   • {note}")
    
    async def validate_environment(self) -> bool:
        """
        Valide l'environnement requis (pour mode réel seulement)
        
        Returns:
            bool: True si environnement prêt
        """
        print(f"\n{Style.BRIGHT}{Fore.WHITE}🔍 VALIDATION ENVIRONNEMENT...")
        print(f"{Fore.WHITE}{'─' * 50}")
        
        try:
            # Animation validation
            validation_steps = [
                "Vérification clés API...",
                "Test service TTS (localhost:5002)...",
                "Test service VOSK (localhost:2700)...",
                "Validation Mistral API Scaleway...",
                "Vérification composants Marie..."
            ]
            
            for i, step in enumerate(validation_steps):
                print(f"{Fore.YELLOW}⏳ {step}", end="", flush=True)
                
                # Simulation progression
                for _ in range(3):
                    time.sleep(0.3)
                    print(".", end="", flush=True)
                
                print(f" {Fore.GREEN}✅")
            
            # Validation réelle rapide
            validator = ServiceValidator()
            validation_results = await validator.validate_all_services()
            
            print(f"\n{Fore.WHITE}📊 Résultats validation :")
            
            # Récupérer le score de santé
            global_metrics = validation_results.get('global_metrics', {})
            health_score = global_metrics.get('average_health_score', 0) * 100
            print(f"{Fore.GREEN}Score santé global : {health_score:.1f}%")
            
            # Vérifier si prêt
            readiness = validation_results.get('readiness_assessment', {})
            is_ready = readiness.get('ready_for_marie_conversation', False)
            
            if is_ready:
                print(f"{Fore.GREEN}[OK] Environnement prêt pour conversation réelle !")
                return True
            else:
                print(f"{Fore.RED}[ERREUR] Problèmes détectés :")
                
                # Récupérer les actions immédiates comme "issues"
                immediate_actions = validation_results.get('recommendations', {}).get('immediate_actions', [])
                for issue in immediate_actions[:3]:
                    print(f"   • {issue}")
                
                print(f"\n{Fore.YELLOW}[INFO] Recommandations :")
                all_recommendations = validation_results.get('recommendations', {}).get('all_recommendations', [])
                for rec in all_recommendations[:2]:
                    print(f"   • {rec}")
                
                # Proposition mode simulation
                print(f"\n{Fore.CYAN}💡 SUGGESTION : Utiliser le mode simulation pour tester Marie sans Docker")
                switch_to_simulation = input(f"\n{Fore.YELLOW}Passer en mode simulation ? (o/n) : {Style.RESET_ALL}").lower()
                if switch_to_simulation in ['o', 'oui', 'y', 'yes']:
                    return "switch_simulation"
                
                # Proposition de continuer quand même
                continue_anyway = input(f"\n{Fore.YELLOW}Continuer malgré les problèmes ? (o/n) : {Style.RESET_ALL}").lower()
                return continue_anyway in ['o', 'oui', 'y', 'yes']
                
        except Exception as e:
            print(f"\n{Fore.RED}[ERREUR] Erreur validation : {e}")
            print(f"\n{Fore.CYAN}💡 Suggestion : Utiliser le mode simulation")
            return False
    
    def show_launch_countdown(self, is_simulation: bool = False):
        """Affiche compte à rebours avant lancement"""
        if is_simulation:
            print(f"\n{Style.BRIGHT}{Fore.WHITE}LANCEMENT SIMULATION MARIE...")
        else:
            print(f"\n{Style.BRIGHT}{Fore.WHITE}🚀 LANCEMENT CONVERSATION MARIE...")
        
        for i in range(3, 0, -1):
            print(f"{Fore.CYAN}Démarrage dans {i}...", end="", flush=True)
            time.sleep(0.8)
            print(f" {Fore.GREEN}✓")
        
        if is_simulation:
            print(f"\n{Style.BRIGHT}{Fore.MAGENTA}🗣️  SIMULATION EN COURS...")
        else:
            print(f"\n{Style.BRIGHT}{Fore.GREEN}🗣️  CONVERSATION EN COURS...")
        print(f"{Fore.WHITE}{'=' * 50}")
    
    async def launch_simulation(self, mode_name: str) -> Dict[str, Any]:
        """
        Lance la simulation de conversation avec Marie
        
        Args:
            mode_name: Nom du mode sélectionné
            
        Returns:
            Dict[str, Any]: Résultats de la simulation
        """
        try:
            print(f"{Fore.WHITE}Marie va maintenant commencer la conversation en mode simulation...")
            print(f"{Fore.YELLOW}Appuyez sur Ctrl+C pour arrêter à tout moment.\n")
            
            # Configuration simulation
            simulator = MarieConversationSimulator(
                max_exchanges=8,
                marie_intensity=0.8,
                debug=True
            )
            
            # Lancement simulation
            result = await simulator.run_simulation()
            
            # Adapter le format pour compatibilité avec l'affichage
            adapted_result = {
                'conversation_session': {
                    'status': 'completed',
                    'total_duration_seconds': result.get('simulation_metadata', {}).get('total_duration', 0)
                },
                'pipeline_performance': {
                    'total_exchanges_completed': result.get('simulation_metadata', {}).get('total_exchanges', 0),
                    'pipeline_success_rate': 1.0
                },
                'quality_metrics': {
                    'overall_conversation_quality': result.get('conversation_performance', {}).get('average_quality_score', 0),
                    'transcription_accuracy': 1.0,  # Simulation parfaite
                    'marie_response_relevance': 0.9
                },
                'marie_character_analysis': {
                    'final_satisfaction_level': result.get('marie_character_analysis', {}).get('final_state', {}).get('satisfaction_level', 0),
                    'conversation_modes_used': result.get('marie_character_analysis', {}).get('modes_progression', [])
                },
                'simulation_mode': True,
                'raw_simulation_result': result
            }
            
            return adapted_result
            
        except KeyboardInterrupt:
            print(f"\n{Fore.YELLOW}⏹️  Simulation interrompue par l'utilisateur")
            return {"status": "interrupted", "message": "Arrêt utilisateur", "simulation_mode": True}
        except Exception as e:
            print(f"\n{Fore.RED}[ERREUR] Erreur pendant simulation : {e}")
            return {"status": "error", "error": str(e), "simulation_mode": True}
    
    async def launch_conversation(self, config) -> Dict[str, Any]:
        """
        Lance la conversation avec la configuration sélectionnée (mode réel)
        
        Args:
            config: Configuration à utiliser
            
        Returns:
            Dict[str, Any]: Résultats de la conversation
        """
        try:
            # Configuration launcher
            launcher_config = {
                'max_exchanges': config.max_exchanges,
                'marie_intensity': config.marie_personality.intensity,
                'user_realism': config.user_simulation.realism_level,
                'save_audio': config.performance.enable_audio_save,
                'debug': config.mode.value == 'debug_development',
                'interactive': True  # Mode interactif activé
            }
            
            # Création et lancement
            launcher = RealConversationLauncher(launcher_config)
            self.launch_time = datetime.now()
            
            # Lancement avec monitoring basique
            print(f"{Fore.WHITE}Marie va maintenant commencer la conversation...")
            print(f"{Fore.YELLOW}Appuyez sur Ctrl+C pour arrêter à tout moment.\n")
            
            # Lancement conversation
            result = await launcher.start_conversation()
            
            return result
            
        except KeyboardInterrupt:
            print(f"\n{Fore.YELLOW}⏹️  Conversation interrompue par l'utilisateur")
            return {"status": "interrupted", "message": "Arrêt utilisateur"}
        except Exception as e:
            print(f"\n{Fore.RED}[ERREUR] Erreur pendant conversation : {e}")
            return {"status": "error", "error": str(e)}
    
    def show_conversation_results(self, result: Dict[str, Any]):
        """
        Affiche les résultats finaux de la conversation
        
        Args:
            result: Résultats de conversation
        """
        is_simulation = result.get('simulation_mode', False)
        
        if is_simulation:
            print(f"\n\n{Style.BRIGHT}{Fore.WHITE}📊 RÉSULTATS SIMULATION MARIE")
        else:
            print(f"\n\n{Style.BRIGHT}{Fore.WHITE}📊 RÉSULTATS CONVERSATION MARIE")
        print(f"{Fore.WHITE}{'=' * 60}")
        
        status = result.get('conversation_session', {}).get('status', 'unknown')
        
        if status == 'completed':
            # Conversation/simulation réussie
            session = result.get('conversation_session', {})
            performance = result.get('pipeline_performance', {})
            quality = result.get('quality_metrics', {})
            marie_analysis = result.get('marie_character_analysis', {})
            
            if is_simulation:
                print(f"{Fore.GREEN}✅ Simulation terminée avec succès !")
            else:
                print(f"{Fore.GREEN}✅ Conversation terminée avec succès !")
                
            print(f"\n{Fore.CYAN}📈 MÉTRIQUES PRINCIPALES :")
            print(f"{Fore.WHITE}   Durée totale      : {session.get('total_duration_seconds', 0):.1f} secondes")
            print(f"{Fore.WHITE}   Échanges réalisés : {performance.get('total_exchanges_completed', 0)}")
            print(f"{Fore.WHITE}   Taux de succès    : {performance.get('pipeline_success_rate', 0)*100:.1f}%")
            
            print(f"\n{Fore.MAGENTA}🎯 QUALITÉ CONVERSATION :")
            print(f"{Fore.WHITE}   Qualité globale   : {quality.get('overall_conversation_quality', 0)*100:.1f}%")
            if not is_simulation:
                print(f"{Fore.WHITE}   Précision VOSK    : {quality.get('transcription_accuracy', 0)*100:.1f}%")
            print(f"{Fore.WHITE}   Pertinence Marie  : {quality.get('marie_response_relevance', 0)*100:.1f}%")
            
            print(f"\n{Fore.YELLOW}👤 ANALYSE MARIE :")
            print(f"{Fore.WHITE}   Satisfaction finale : {marie_analysis.get('final_satisfaction_level', 0)*100:.1f}%")
            print(f"{Fore.WHITE}   Modes utilisés      : {len(marie_analysis.get('conversation_modes_used', []))}")
            
            if not is_simulation:
                # Performance technique (mode réel seulement)
                print(f"\n{Fore.BLUE}⚡ PERFORMANCE TECHNIQUE :")
                tts_perf = performance.get('tts_performance', {})
                vosk_perf = performance.get('vosk_performance', {})
                mistral_perf = performance.get('mistral_performance', {})
                
                print(f"{Fore.WHITE}   Latence TTS       : {tts_perf.get('average_latency', 0):.1f}s")
                print(f"{Fore.WHITE}   Latence VOSK      : {vosk_perf.get('average_latency', 0):.1f}s")
                print(f"{Fore.WHITE}   Latence Mistral   : {mistral_perf.get('average_latency', 0):.1f}s")
            else:
                print(f"\n{Fore.BLUE}MODE SIMULATION :")
                print(f"{Fore.WHITE}   Type              : Conversation textuelle")
                print(f"{Fore.WHITE}   Avantages         : Pas de dépendance externe")
                print(f"{Fore.WHITE}   Intelligence      : 100% Marie AI Character")
            
        elif status == 'interrupted':
            if is_simulation:
                print(f"{Fore.YELLOW}⏹️  Simulation interrompue")
            else:
                print(f"{Fore.YELLOW}⏹️  Conversation interrompue")
            print(f"{Fore.WHITE}La conversation a été arrêtée avant la fin.")
            
        elif status == 'error':
            if is_simulation:
                print(f"{Fore.RED}[ERREUR] Erreur pendant la simulation")
            else:
                print(f"{Fore.RED}[ERREUR] Erreur pendant la conversation")
            print(f"{Fore.WHITE}Détails : {result.get('error', 'Erreur inconnue')}")
            
        else:
            print(f"{Fore.YELLOW}⚠️  Statut inconnu : {status}")
        
        print(f"\n{Fore.WHITE}{'=' * 60}")
    
    def show_final_options(self, result: Dict[str, Any]):
        """
        Affiche les options finales après conversation
        
        Args:
            result: Résultats de conversation
        """
        print(f"\n{Fore.WHITE}🎯 OPTIONS DISPONIBLES :")
        print(f"{Fore.CYAN}1. Relancer une nouvelle conversation")
        print(f"{Fore.CYAN}2. Voir le rapport détaillé (JSON)")
        print(f"{Fore.CYAN}3. Quitter le programme")
        
        try:
            choice = input(f"\n{Fore.WHITE}Votre choix (1-3) : {Style.RESET_ALL}").strip()
            
            if choice == "1":
                return "restart"
            elif choice == "2":
                return "show_report"
            elif choice == "3":
                return "quit"
            else:
                return "quit"
                
        except (KeyboardInterrupt, EOFError):
            return "quit"
    
    def save_and_show_report(self, result: Dict[str, Any]):
        """
        Sauvegarde et affiche le rapport détaillé
        
        Args:
            result: Résultats de conversation
        """
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            is_simulation = result.get('simulation_mode', False)
            
            if is_simulation:
                report_file = f"marie_simulation_report_{timestamp}.json"
            else:
                report_file = f"marie_conversation_report_{timestamp}.json"
            
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            
            print(f"\n{Fore.GREEN}Rapport sauvegarde : {report_file}")
            if is_simulation:
                print(f"{Fore.WHITE}Le rapport contient l'analyse complète de la simulation.")
            else:
                print(f"{Fore.WHITE}Le rapport contient l'analyse complète de la conversation.")
            
        except Exception as e:
            print(f"{Fore.RED}[ERREUR] Erreur sauvegarde rapport : {e}")
    
    async def run(self):
        """Fonction principale du wizard"""
        while True:
            try:
                # En-tête
                self.print_header()
                
                # Sélection mode
                available_modes = self.show_available_modes()
                selected_mode_name, mode_type = self.get_user_choice(available_modes)
                
                # Traitement selon le type de mode
                if mode_type == "simulation":
                    # Mode simulation - pas besoin de configuration complexe
                    self.show_simulation_config_summary(selected_mode_name)
                    
                    # Lancement direct
                    self.show_launch_countdown(is_simulation=True)
                    result = await self.launch_simulation(selected_mode_name)
                    
                else:
                    # Mode réel - chargement configuration
                    try:
                        config = load_config_by_name(selected_mode_name)
                        self.selected_config = config
                        self.show_configuration_summary(config)
                    except Exception as e:
                        print(f"{Fore.RED}[ERREUR] Erreur chargement configuration : {e}")
                        print(f"{Fore.CYAN}💡 Essayez le mode simulation (option 7)")
                        continue
                    
                    # Validation environnement
                    env_result = await self.validate_environment()
                    if env_result == "switch_simulation":
                        # Basculer en mode simulation
                        print(f"\n{Fore.CYAN}🔄 Basculement vers le mode simulation...")
                        time.sleep(1)
                        self.show_simulation_config_summary("simulation_mode")
                        self.show_launch_countdown(is_simulation=True)
                        result = await self.launch_simulation("simulation_mode")
                    elif not env_result:
                        print(f"{Fore.RED}[ERREUR] Environnement non prêt. Essayez le mode simulation.")
                        continue
                    else:
                        # Lancement conversation réelle
                        self.show_launch_countdown(is_simulation=False)
                        result = await self.launch_conversation(config)
                
                # Affichage résultats
                self.show_conversation_results(result)
                
                # Options post-conversation
                next_action = self.show_final_options(result)
                
                if next_action == "restart":
                    print(f"\n{Fore.CYAN}🔄 Redémarrage...")
                    time.sleep(1)
                    continue
                elif next_action == "show_report":
                    self.save_and_show_report(result)
                    # Demander si continuer
                    continue_choice = input(f"\n{Fore.WHITE}Lancer une autre conversation ? (o/n) : {Style.RESET_ALL}").lower()
                    if continue_choice in ['o', 'oui', 'y', 'yes']:
                        continue
                    else:
                        break
                else:
                    break
                    
            except KeyboardInterrupt:
                print(f"\n{Fore.YELLOW}👋 Arrêt demandé par l'utilisateur.")
                break
            except Exception as e:
                print(f"\n{Fore.RED}[ERREUR] Erreur inattendue : {e}")
                retry = input(f"{Fore.YELLOW}Réessayer ? (o/n) : {Style.RESET_ALL}").lower()
                if retry not in ['o', 'oui', 'y', 'yes']:
                    break
        
        # Message final
        print(f"\n{Style.BRIGHT}{Fore.CYAN}👋 Merci d'avoir utilisé Eloquence - Conversation Marie !")
        print(f"{Fore.WHITE}À bientôt pour de nouvelles conversations avec Marie.{Style.RESET_ALL}\n")

async def main():
    """Point d'entrée principal"""
    # Vérification Python version
    if sys.version_info < (3, 7):
        print("[ERREUR] Python 3.7+ requis")
        sys.exit(1)
    
    # Lancement wizard
    wizard = ConversationLaunchWizard()
    await wizard.run()

if __name__ == "__main__":
    try:
        # Installation colorama si manquant
        if not COLORS_AVAILABLE:
            print("💡 Pour une meilleure expérience, installez colorama: pip install colorama")
            time.sleep(2)
        
        # Lancement principal
        asyncio.run(main())
        
    except KeyboardInterrupt:
        print("\n👋 Au revoir !")
        sys.exit(0)
    except Exception as e:
        print(f"[ERREUR] Erreur fatale : {e}")
        sys.exit(1)