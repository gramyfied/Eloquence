#!/usr/bin/env python3
"""
Marie Conversation Simulator - Simulation de conversation complète avec Marie AI Character

Ce simulateur permet de tester l'intelligence conversationnelle de Marie sans nécessiter
les services Docker (TTS, VOSK). Il simule une conversation commerciale réaliste avec
la personnalité adaptative de Marie comme directrice commerciale exigeante.

Fonctionnalités :
- Conversation interactive utilisateur/Marie
- 6 modes conversationnels de Marie (EVALUATION_INITIALE → CLOTURE_DECISION)
- Progression dynamique de satisfaction/patience/intérêt
- Génération de messages utilisateur contextuels
- Rapport détaillé avec analyse de performance
- Interface temps réel avec affichage état Marie

Usage:
    python marie_conversation_simulator.py [--exchanges N] [--intensity F] [--debug]
"""

import asyncio
import time
import json
import random
from datetime import datetime
from typing import Dict, Any, List
from dataclasses import dataclass, asdict

# Import des composants existants
from marie_ai_character import MarieAICharacter
from real_conversation_manager import UserMessageGenerator

@dataclass
class SimulatedExchange:
    """Résultat d'un échange simulé"""
    exchange_number: int
    user_message: str
    marie_response: str
    marie_mode: str
    marie_satisfaction: float
    marie_patience: float
    marie_interest: float
    conversation_phase: str
    exchange_duration: float
    quality_score: float
    insights: List[str]

class MarieConversationSimulator:
    """
    Simulateur de conversation complète avec Marie AI Character
    
    Simule une conversation commerciale réaliste avec tous les aspects
    de la personnalité adaptative de Marie sans nécessiter les services externes.
    """
    
    def __init__(self, max_exchanges: int = 10, marie_intensity: float = 0.8, debug: bool = False):
        """
        Initialise le simulateur de conversation
        
        Args:
            max_exchanges: Nombre maximum d'échanges
            marie_intensity: Intensité personnalité Marie (0.0-1.0)
            debug: Mode debug avec logs détaillés
        """
        self.max_exchanges = max_exchanges
        self.marie_intensity = marie_intensity
        self.debug = debug
        
        # Initialiser Marie AI Character
        self.marie = MarieAICharacter()
        self._configure_marie_intensity()
        
        # Générateur de messages utilisateur
        self.user_generator = UserMessageGenerator(realism_level=0.9)
        
        # État de la simulation
        self.exchanges: List[SimulatedExchange] = []
        self.start_time = None
        self.conversation_active = True
        
        # Scénarios de messages utilisateur prédéfinis
        self.user_scenarios = [
            "Bonjour Marie, je viens vous présenter notre nouvelle solution CRM révolutionnaire.",
            "Notre produit peut augmenter votre chiffre d'affaires de 30% dès le premier mois.",
            "Nous avons déjà transformé plus de 500 entreprises avec notre technologie.",
            "Je peux vous proposer une démonstration personnalisée pour votre équipe.",
            "Le ROI est garanti à 200% sur 12 mois avec notre support premium inclus.",
            "Nous offrons une intégration complète en 3 semaines maximum.",
            "Sur le budget, nous pouvons proposer un échelonnement sur 24 mois.",
            "Parfait, nous sommes d'accord. Quand pouvons-nous signer le contrat ?"
        ]
    
    def _configure_marie_intensity(self):
        """Configure l'intensité de la personnalité de Marie"""
        intensity = self.marie_intensity
        
        if intensity >= 0.8:  # Très exigeante
            self.marie.patience_level = 0.6
            self.marie.satisfaction_level = 0.3
            self.marie.interest_level = 0.4
        elif intensity >= 0.6:  # Moyennement exigeante  
            self.marie.patience_level = 0.7
            self.marie.satisfaction_level = 0.4
            self.marie.interest_level = 0.5
        else:  # Plus accommodante
            self.marie.patience_level = 0.8
            self.marie.satisfaction_level = 0.5
            self.marie.interest_level = 0.6
    
    def _get_contextual_user_message(self, exchange_number: int, marie_last_response: str = "") -> str:
        """Génère un message utilisateur contextuel"""
        if exchange_number == 1:
            return self.user_scenarios[0]  # Ouverture
        elif exchange_number <= len(self.user_scenarios):
            return self.user_scenarios[exchange_number - 1]
        else:
            # Utiliser le générateur pour les messages suivants
            marie_state = self.marie.get_marie_state_summary()
            conversation_phase = self._determine_conversation_phase()
            return self.user_generator.generate_contextual_message(
                marie_last_response, conversation_phase, marie_state['conversation_state']
            )
    
    def _determine_conversation_phase(self) -> str:
        """Détermine la phase actuelle de la conversation"""
        exchange_count = len(self.exchanges)
        
        if exchange_count == 0:
            return "opening"
        elif exchange_count < 3:
            return "presentation"
        elif self.marie.satisfaction_level < 0.4:
            return "objection_handling"
        elif self.marie.satisfaction_level > 0.7:
            return "closing"
        else:
            return "negotiation"
    
    def _calculate_exchange_quality(self, user_msg: str, marie_response: str, 
                                  marie_state: Dict) -> float:
        """Calcule la qualité de l'échange"""
        # Pertinence de la réponse de Marie
        relevance = len(set(user_msg.lower().split()) & set(marie_response.lower().split())) / max(len(user_msg.split()), 1)
        
        # Progression de la conversation
        satisfaction_progress = marie_state['conversation_state']['satisfaction_level']
        
        # Longueur appropriée de la réponse
        length_score = min(1.0, len(marie_response.split()) / 20.0)  # Optimal ~20 mots
        
        return (relevance + satisfaction_progress + length_score) / 3.0
    
    def _generate_exchange_insights(self, exchange: SimulatedExchange) -> List[str]:
        """Génère des insights pour l'échange"""
        insights = []
        
        # Insights sur Marie
        if exchange.marie_satisfaction > 0.8:
            insights.append("Marie montre un fort intérêt pour la proposition")
        elif exchange.marie_satisfaction < 0.3:
            insights.append("Marie reste très sceptique, stratégie à revoir")
        
        if exchange.marie_patience < 0.4:
            insights.append("Patience de Marie en baisse, accélérer la démonstration")
        
        # Insights sur la progression
        if exchange.marie_mode == "validation_finale":
            insights.append("Marie entre en phase de validation, opportunité de conclure")
        elif exchange.marie_mode == "objection_challenger":
            insights.append("Marie teste la solidité de l'offre, maintenir la confiance")
        
        # Insights sur la qualité
        if exchange.quality_score > 0.8:
            insights.append("Échange de très haute qualité, excellent alignement")
        elif exchange.quality_score < 0.5:
            insights.append("Qualité d'échange faible, améliorer la pertinence")
        
        return insights
    
    async def simulate_exchange(self, exchange_number: int, marie_last_response: str = "") -> SimulatedExchange:
        """Simule un échange complet utilisateur/Marie"""
        exchange_start = time.time()
        
        # 1. Générer message utilisateur
        user_message = self._get_contextual_user_message(exchange_number, marie_last_response)
        
        if self.debug:
            print(f"\n[ECHANGE {exchange_number}]")
            print(f"UTILISATEUR: {user_message}")
        
        # 2. Marie analyse et répond
        marie_analysis = self.marie.analyze_user_input(
            user_message, 
            {'exchange_number': exchange_number, 'total_time': time.time() - self.start_time}
        )
        
        marie_response_data = self.marie.generate_marie_response(user_message, marie_analysis)
        marie_response = marie_response_data['response']
        
        # Ajouter question de suivi si pertinent
        if marie_response_data.get('follow_up_question'):
            marie_response += " " + marie_response_data['follow_up_question']
        
        if self.debug:
            print(f"MARIE ({self.marie.current_mode.value}): {marie_response}")
        
        # 3. Calculer métriques
        exchange_duration = time.time() - exchange_start
        marie_state = self.marie.get_marie_state_summary()
        conversation_phase = self._determine_conversation_phase()
        
        quality_score = self._calculate_exchange_quality(
            user_message, marie_response, marie_state
        )
        
        # 4. Créer résultat échange
        exchange = SimulatedExchange(
            exchange_number=exchange_number,
            user_message=user_message,
            marie_response=marie_response,
            marie_mode=self.marie.current_mode.value,
            marie_satisfaction=self.marie.satisfaction_level,
            marie_patience=self.marie.patience_level,
            marie_interest=self.marie.interest_level,
            conversation_phase=conversation_phase,
            exchange_duration=exchange_duration,
            quality_score=quality_score,
            insights=[]  # Sera rempli après
        )
        
        # 5. Générer insights
        exchange.insights = self._generate_exchange_insights(exchange)
        
        if self.debug:
            print(f"Satisfaction: {exchange.marie_satisfaction:.2f} | "
                  f"Patience: {exchange.marie_patience:.2f} | "
                  f"Qualite: {exchange.quality_score:.2f}")
        
        return exchange
    
    def _should_continue_conversation(self) -> bool:
        """Détermine si la conversation doit continuer"""
        # Arrêter si Marie a pris sa décision
        if self.marie.current_mode.value == 'cloture_decision':
            return False
        
        # Arrêter si satisfaction très faible depuis longtemps
        if (self.marie.satisfaction_level < 0.2 and len(self.exchanges) >= 5):
            return False
        
        # Arrêter si patience épuisée
        if self.marie.patience_level < 0.1:
            return False
        
        return True
    
    async def run_simulation(self) -> Dict[str, Any]:
        """Lance la simulation complète de conversation avec Marie"""
        self.start_time = time.time()
        
        print("=" * 80)
        print("SIMULATION CONVERSATION AVEC MARIE AI CHARACTER")
        print("=" * 80)
        print(f"Marie : Directrice commerciale (intensite {self.marie_intensity:.1f})")
        print(f"Objectif : {self.max_exchanges} echanges maximum")
        print(f"Etat initial Marie : Satisfaction={self.marie.satisfaction_level:.2f}, "
              f"Patience={self.marie.patience_level:.2f}")
        print("=" * 80)
        
        marie_last_response = ""
        
        for exchange_num in range(1, self.max_exchanges + 1):
            if not self.conversation_active or not self._should_continue_conversation():
                break
            
            try:
                # Simuler un échange
                exchange = await self.simulate_exchange(exchange_num, marie_last_response)
                self.exchanges.append(exchange)
                marie_last_response = exchange.marie_response
                
                # Afficher insights en temps réel
                if self.debug and exchange.insights:
                    print(f"Insights: {'; '.join(exchange.insights)}")
                
                # Petite pause pour réalisme
                await asyncio.sleep(0.5)
                
            except Exception as e:
                print(f"❌ Erreur échange {exchange_num}: {e}")
                break
        
        # Générer rapport final
        total_duration = time.time() - self.start_time
        report = self._generate_simulation_report(total_duration)
        
        # Afficher résumé
        self._display_simulation_summary(report)
        
        return report
    
    def _generate_simulation_report(self, total_duration: float) -> Dict[str, Any]:
        """Génère le rapport complet de la simulation"""
        marie_final_state = self.marie.get_marie_state_summary()
        
        # Statistiques globales
        total_exchanges = len(self.exchanges)
        avg_quality = sum(ex.quality_score for ex in self.exchanges) / total_exchanges if total_exchanges > 0 else 0
        avg_satisfaction_progression = (self.marie.satisfaction_level - 0.3) if self.marie_intensity >= 0.8 else (self.marie.satisfaction_level - 0.4)
        
        # Analyse progression de Marie
        satisfaction_evolution = [ex.marie_satisfaction for ex in self.exchanges]
        patience_evolution = [ex.marie_patience for ex in self.exchanges]
        modes_used = list(set(ex.marie_mode for ex in self.exchanges))
        
        # Déterminer le résultat final
        if self.marie.current_mode.value == 'cloture_decision' and self.marie.satisfaction_level > 0.8:
            outcome = "ACCORD_CONCLU"
        elif self.marie.current_mode.value == 'cloture_decision' and self.marie.satisfaction_level > 0.6:
            outcome = "DECISION_REPORTEE"
        elif self.marie.satisfaction_level < 0.3:
            outcome = "ECHEC_COMMERCIAL"
        elif self.marie.satisfaction_level > 0.6:
            outcome = "PROGRESSION_POSITIVE"
        else:
            outcome = "CONVERSATION_NEUTRE"
        
        # Collecter tous les insights
        all_insights = []
        for ex in self.exchanges:
            all_insights.extend(ex.insights)
        
        return {
            'simulation_metadata': {
                'start_time': self.start_time,
                'total_duration': total_duration,
                'total_exchanges': total_exchanges,
                'marie_intensity_configured': self.marie_intensity,
                'simulation_mode': 'marie_ai_character_simulation'
            },
            'marie_character_analysis': {
                'initial_state': {
                    'satisfaction': 0.3 if self.marie_intensity >= 0.8 else 0.4,
                    'patience': 0.6 if self.marie_intensity >= 0.8 else 0.7,
                    'interest': 0.4 if self.marie_intensity >= 0.8 else 0.5
                },
                'final_state': marie_final_state['conversation_state'],
                'satisfaction_evolution': satisfaction_evolution,
                'patience_evolution': patience_evolution,
                'modes_progression': modes_used,
                'personality_adaptation': marie_final_state['conversation_quality']['progression']
            },
            'conversation_performance': {
                'average_quality_score': avg_quality,
                'satisfaction_progression': avg_satisfaction_progression,
                'conversation_outcome': outcome,
                'phases_covered': list(set(ex.conversation_phase for ex in self.exchanges)),
                'marie_modes_activated': len(modes_used)
            },
            'detailed_exchanges': [asdict(ex) for ex in self.exchanges],
            'insights_summary': {
                'total_insights_generated': len(all_insights),
                'key_insights': list(set(all_insights)),  # Insights uniques
                'marie_behavioral_patterns': self._analyze_marie_patterns(),
                'conversation_dynamics': self._analyze_conversation_dynamics()
            },
            'recommendations': {
                'marie_tuning_suggestions': self._generate_marie_recommendations(),
                'conversation_strategy_tips': self._generate_strategy_recommendations(),
                'simulation_improvements': self._generate_simulation_improvements()
            }
        }
    
    def _analyze_marie_patterns(self) -> List[str]:
        """Analyse les patterns comportementaux de Marie"""
        patterns = []
        
        if len(self.exchanges) < 2:
            return patterns
        
        # Analyser évolution satisfaction
        satisfaction_trend = self.exchanges[-1].marie_satisfaction - self.exchanges[0].marie_satisfaction
        if satisfaction_trend > 0.3:
            patterns.append("Marie montre une progression positive constante")
        elif satisfaction_trend < -0.2:
            patterns.append("Marie devient de plus en plus sceptique")
        
        # Analyser changements de mode
        mode_changes = len(set(ex.marie_mode for ex in self.exchanges))
        if mode_changes >= 4:
            patterns.append("Marie explore activement différentes approches conversationnelles")
        elif mode_changes <= 2:
            patterns.append("Marie reste dans des modes conversationnels limités")
        
        # Analyser patience
        final_patience = self.exchanges[-1].marie_patience
        if final_patience < 0.3:
            patterns.append("Patience de Marie fortement éprouvée")
        elif final_patience > 0.7:
            patterns.append("Marie maintient une patience professionnelle")
        
        return patterns
    
    def _analyze_conversation_dynamics(self) -> List[str]:
        """Analyse la dynamique conversationnelle"""
        dynamics = []
        
        if not self.exchanges:
            return dynamics
        
        # Qualité moyenne
        avg_quality = sum(ex.quality_score for ex in self.exchanges) / len(self.exchanges)
        if avg_quality > 0.7:
            dynamics.append("Dynamique conversationnelle excellente")
        elif avg_quality < 0.5:
            dynamics.append("Dynamique conversationnelle à améliorer")
        
        # Progression phases
        phases = [ex.conversation_phase for ex in self.exchanges]
        if "closing" in phases:
            dynamics.append("Conversation progresse vers la conclusion")
        elif phases.count("objection_handling") > len(phases) / 2:
            dynamics.append("Conversation dominée par la gestion d'objections")
        
        return dynamics
    
    def _generate_marie_recommendations(self) -> List[str]:
        """Génère des recommandations pour l'ajustement de Marie"""
        recommendations = []
        
        final_satisfaction = self.marie.satisfaction_level
        final_patience = self.marie.patience_level
        
        if final_satisfaction < 0.4:
            recommendations.append("Ajuster la sensibilité de Marie aux arguments positifs")
        elif final_satisfaction > 0.9:
            recommendations.append("Augmenter le niveau d'exigence de Marie")
        
        if final_patience < 0.3:
            recommendations.append("Calibrer la décroissance de patience de Marie")
        
        if len(set(ex.marie_mode for ex in self.exchanges)) < 3:
            recommendations.append("Encourager plus de transitions entre modes conversationnels")
        
        return recommendations
    
    def _generate_strategy_recommendations(self) -> List[str]:
        """Génère des recommandations stratégiques"""
        recommendations = []
        
        # Analyser performance par phase
        phase_quality = {}
        for ex in self.exchanges:
            phase = ex.conversation_phase
            if phase not in phase_quality:
                phase_quality[phase] = []
            phase_quality[phase].append(ex.quality_score)
        
        for phase, qualities in phase_quality.items():
            avg_quality = sum(qualities) / len(qualities)
            if avg_quality < 0.6:
                recommendations.append(f"Améliorer la stratégie en phase {phase}")
        
        return recommendations
    
    def _generate_simulation_improvements(self) -> List[str]:
        """Génère des suggestions d'amélioration de la simulation"""
        improvements = []
        
        if len(self.exchanges) < self.max_exchanges / 2:
            improvements.append("Prolonger les conversations pour plus d'insights")
        
        avg_duration = sum(ex.exchange_duration for ex in self.exchanges) / len(self.exchanges) if self.exchanges else 0
        if avg_duration < 0.1:
            improvements.append("Ajouter plus de complexité dans les échanges")
        
        return improvements
    
    def _display_simulation_summary(self, report: Dict[str, Any]):
        """Affiche le résumé de la simulation"""
        print("\n" + "=" * 80)
        print("RESUME SIMULATION CONVERSATION MARIE")
        print("=" * 80)
        
        metadata = report['simulation_metadata']
        marie_analysis = report['marie_character_analysis']
        performance = report['conversation_performance']
        
        print(f"Duree totale : {metadata['total_duration']:.1f}s")
        print(f"Echanges realises : {metadata['total_exchanges']}")
        print(f"Resultat final : {performance['conversation_outcome']}")
        print(f"Qualite moyenne : {performance['average_quality_score']:.2f}")
        
        print(f"\nEVOLUTION MARIE:")
        final_state = marie_analysis['final_state']
        print(f"   Satisfaction : {final_state['satisfaction_level']:.2f}")
        print(f"   Patience : {final_state['patience_level']:.2f}")
        print(f"   Interet : {final_state['interest_level']:.2f}")
        print(f"   Mode final : {final_state['mode_actuel']}")
        
        insights = report['insights_summary']
        if insights['key_insights']:
            print(f"\nINSIGHTS CLES:")
            for i, insight in enumerate(insights['key_insights'][:3], 1):
                print(f"   {i}. {insight}")
        
        if marie_analysis['modes_progression']:
            print(f"\nMODES MARIE UTILISES:")
            for mode in marie_analysis['modes_progression']:
                print(f"   - {mode}")
        
        print("=" * 80)

async def main():
    """Fonction principale du simulateur"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Simulateur de conversation avec Marie AI Character")
    parser.add_argument('--exchanges', type=int, default=8, help='Nombre maximum d\'échanges')
    parser.add_argument('--intensity', type=float, default=0.8, help='Intensité Marie (0.0-1.0)')
    parser.add_argument('--debug', action='store_true', help='Mode debug détaillé')
    
    args = parser.parse_args()
    
    # Créer et lancer le simulateur
    simulator = MarieConversationSimulator(
        max_exchanges=args.exchanges,
        marie_intensity=args.intensity,
        debug=args.debug
    )
    
    try:
        # Lancer la simulation
        report = await simulator.run_simulation()
        
        # Sauvegarder le rapport
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f'marie_simulation_report_{timestamp}.json'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\nRapport detaille sauvegarde : {report_filename}")
        
        return True
        
    except KeyboardInterrupt:
        print("\nSimulation interrompue par l'utilisateur")
        return False
    except Exception as e:
        print(f"\nErreur simulation : {e}")
        return False

if __name__ == "__main__":
    asyncio.run(main())