# Documentation Technique - Système de Test Conversationnel Interactif avec Auto-Réparation

**Version :** 1.0  
**Date :** 2025  
**Auteur :** Système Eloquence  
**Compatibilité :** Windows 11, Python 3.8+  

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture Système](#architecture-système)
3. [Installation et Configuration](#installation-et-configuration)
4. [Guide d'Utilisation](#guide-dutilisation)
5. [API et Interfaces](#api-et-interfaces)
6. [Composants Détaillés](#composants-détaillés)
7. [Exemples Pratiques](#exemples-pratiques)
8. [Configuration Avancée](#configuration-avancée)
9. [Monitoring et Métriques](#monitoring-et-métriques)
10. [Dépannage](#dépannage)
11. [Performances et Optimisation](#performances-et-optimisation)
12. [Maintenance](#maintenance)

---

## Vue d'Ensemble

### Objectif du Système

Le Système de Test Conversationnel Interactif est une solution avancée conçue pour tester automatiquement l'IA Marie d'Eloquence dans des conditions conversationnelles réalistes. Il simule des utilisateurs virtuels, collecte plus de 30 métriques par échange et applique des réparations automatiques en cas de problème.

### Fonctionnalités Principales

- **Conversation Adaptative** : Pas de scripts figés, adaptation dynamique selon les réponses IA
- **Auto-Réparation Multi-Niveaux** : Détection et correction automatique des problèmes
- **Métriques Exhaustives** : Plus de 30 métriques par échange conversationnel
- **Simulation Utilisateur Réaliste** : Via LiveKit avec synthèse TTS et transcription VOSK
- **Scénarios Diversifiés** : Commercial, présentation, négociation, support technique
- **Rapports JSON Complets** : Analyse de tendances et recommandations automatiques

### Compatibilité Windows

Le système est spécifiquement optimisé pour Windows 11 avec :
- Gestion native des chemins Windows
- Compatibilité CMD/PowerShell
- Support des services Windows
- Aucun émoji pour compatibilité console Windows

---

## Architecture Système

### Vue d'Ensemble Architecturale

```
┌─────────────────────────────────────────────────────────────┐
│                 ORCHESTRATEUR PRINCIPAL                    │
│              InteractiveConversationTester                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼───────┐ ┌───▼───┐ ┌──────▼────────┐
│ COLLECTEUR    │ │MOTEUR │ │ DÉTECTEUR     │
│ MÉTRIQUES     │ │CONVER │ │ ANOMALIES     │
│ (30+ metrics) │ │SATION │ │ (Temps réel)  │
└───────────────┘ └───────┘ └───────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
┌─────────────────────▼─────────────────────┐
│           SERVICES INTÉGRÉS               │
├─────────────┬─────────────┬─────────────┤
│    VOSK     │    TTS      │   MISTRAL    │
│   :2700     │   :5002     │    API       │
└─────────────┴─────────────┴─────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
┌─────────────────────▼─────────────────────┐
│          SIMULATION UTILISATEUR           │
│              LiveKit :7880                │
│         (Client Virtuel + Audio)         │
└───────────────────────────────────────────┘
```

### Flux de Données Principal

1. **Initialisation** : Configuration du scénario et personnalité utilisateur
2. **Génération Message** : Création contextuelle du message utilisateur
3. **Synthèse TTS** : Conversion texte vers audio réaliste
4. **Transcription VOSK** : Audio vers texte avec métriques
5. **Génération IA** : Réponse Mistral avec contexte conversationnel
6. **Collecte Métriques** : 30+ indicateurs de performance
7. **Détection Anomalies** : Analyse temps réel des problèmes
8. **Auto-Réparation** : Application de stratégies correctives
9. **Rapport Final** : JSON avec tendances et recommandations

---

## Installation et Configuration

### Prérequis Système

**Environnement Windows :**
- Windows 11 (recommandé) ou Windows 10
- Python 3.8+ (testé avec Python 3.11)
- 8 GB RAM minimum (16 GB recommandé)
- 2 GB espace disque libre
- Connexion Internet pour APIs externes

**Services Requis :**
- VOSK STT Analysis sur port 2700
- OpenAI-TTS Service sur port 5002
- LiveKit Server sur port 7880
- Agent Mistral sur port 8080 (optionnel pour tests réels)

### Installation des Dépendances

```bash
# Dépendances Python principales
pip install numpy==1.24.3
pip install aiohttp==3.8.4
pip install websockets==11.0.3
pip install asyncio-mqtt==0.13.0

# Dépendances LiveKit
pip install livekit-api==0.5.0
pip install livekit-rtc==0.8.0

# Dépendances audio et traitement
pip install wave
pip install scipy==1.10.1
pip install librosa==0.10.1

# Dépendances API et HTTP
pip install requests==2.31.0
pip install httpx==0.24.1

# Utilitaires
pip install python-dotenv==1.0.0
pip install pydantic==2.0.3
```

### Configuration Services Windows

**1. Service VOSK (Port 2700)**
```bash
cd services/vosk-stt-analysis
python main.py --port 2700 --host 0.0.0.0
```

**2. Service TTS (Port 5002)**
```bash
cd services/openai-tts
python main.py --port 5002 --host 0.0.0.0
```

**3. Service LiveKit (Port 7880)**
```bash
cd services/livekit-server
python main.py --port 7880 --host 0.0.0.0
```

### Fichier de Configuration

Créer `config.env` :
```env
# Configuration services
VOSK_HOST=localhost
VOSK_PORT=2700

TTS_HOST=localhost
TTS_PORT=5002

LIVEKIT_HOST=localhost
LIVEKIT_PORT=7880

MISTRAL_API_KEY=your_mistral_api_key
MISTRAL_MODEL=mistral-large-latest

# Configuration test
DEFAULT_SCENARIO=presentation_client
DEFAULT_PERSONALITY=commercial_confiant
MAX_EXCHANGES=10
CONVERSATION_TIMEOUT=300
EXCHANGE_TIMEOUT=30

# Métriques et logs
ENABLE_DETAILED_LOGGING=true
METRICS_COLLECTION_LEVEL=full
AUTO_REPAIR_ENABLED=true
ANOMALY_DETECTION_ENABLED=true

# Audio
SAMPLE_RATE=16000
AUDIO_CHANNELS=1
AUDIO_QUALITY=high

# Rapports
REPORT_FORMAT=json
REPORT_DIRECTORY=./reports
SAVE_AUDIO_FILES=false
```

---

## Guide d'Utilisation

### Démarrage Rapide

**1. Test de Base**
```python
import asyncio
from main_orchestrator import InteractiveConversationTester, TestConfiguration

# Configuration simple
config = TestConfiguration(
    max_exchanges=5,
    scenario_type="presentation_client",
    user_personality="commercial_confiant"
)

# Lancer le test
async def main():
    tester = InteractiveConversationTester(config)
    report = await tester.run_interactive_conversation_test()
    print(f"Test terminé : {report['test_summary']['overall_success_rate']:.1%} succès")

asyncio.run(main())
```

**2. Test avec Scénario Personnalisé**
```python
from adaptive_conversation_scenarios import ConversationDynamics, ScenarioType, UserProfile

# Configurer le scénario
dynamics = ConversationDynamics()
dynamics.set_scenario(ScenarioType.NEGOCIATION_PRIX, UserProfile.CLIENT_EXIGEANT)

# Intégrer dans le test
config = TestConfiguration(
    scenario_type="negociation_prix",
    user_personality="client_exigeant",
    max_exchanges=8
)
```

### Commandes Principales

**Lancement Test Standard :**
```bash
python main_orchestrator.py
```

**Test avec Configuration Spécifique :**
```bash
python main_orchestrator.py --config custom_config.env --scenario commercial_demo --personality technicien_sceptique
```

**Validation Système :**
```bash
python comprehensive_test_suite.py
```

**Test Client LiveKit :**
```bash
python livekit_virtual_user_client.py
```

### Types de Tests Disponibles

1. **Test Présentation Client** : Scénario de présentation commerciale formelle
2. **Test Démonstration** : Démonstration interactive des fonctionnalités  
3. **Test Négociation** : Négociation tarifaire et conditions commerciales
4. **Test Support Technique** : Assistance et résolution de problèmes
5. **Test Formation** : Formation utilisateur sur le produit

---

## API et Interfaces

### Interface Principale - InteractiveConversationTester

```python
class InteractiveConversationTester:
    def __init__(self, config: TestConfiguration = None)
    
    async def run_interactive_conversation_test(self) -> Dict[str, Any]:
        """Lance le test conversationnel complet"""
        
    async def _execute_complete_exchange(self, ai_last_response: Optional[str]) -> ExchangeResult:
        """Exécute un échange complet utilisateur → IA"""
        
    async def _validate_all_services(self):
        """Valide que tous les services sont opérationnels"""
    
    def _should_continue_conversation(self, exchange_result: ExchangeResult) -> bool:
        """Détermine si la conversation doit continuer"""
```

### Interface Collecteur de Métriques

```python
class ConversationMetricsCollector:
    def collect_exchange_metrics(self, exchange_data: Dict[str, Any]) -> ConversationMetrics:
        """Collecte toutes les métriques d'un échange"""
    
    def generate_conversation_report(self) -> Dict[str, Any]:
        """Génère le rapport de conversation complet"""
        
    def _calculate_relevance(self, user_message: str, ai_response: str) -> float:
        """Calcule la pertinence de la réponse IA"""
```

### Interface Moteur de Conversation

```python
class IntelligentConversationEngine:
    def generate_next_user_message(self, ai_previous_response: str = None) -> Dict[str, Any]:
        """Génère le prochain message utilisateur contextuel"""
        
    def _analyze_ai_response(self, ai_response: str) -> Dict[str, Any]:
        """Analyse la réponse IA pour adaptation"""
        
    def _update_conversation_state(self, ai_analysis: Dict[str, Any], user_context: Dict[str, Any]):
        """Met à jour l'état de conversation"""
```

### Interface Auto-Réparation

```python
class AutoRepairSystem:
    def repair_issue(self, issue_type: str, conversation_state: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Répare un problème détecté"""
        
    def get_repair_statistics(self) -> Dict[str, Any]:
        """Retourne les statistiques de réparation"""
```

### Interface Services Wrappers

```python
class RealTTSService:
    async def synthesize_speech(self, text: str) -> Dict[str, Any]:
        """Synthétise la parole à partir du texte"""
        
class RealVoskService:
    async def transcribe_audio(self, audio_data: bytes, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Transcrit l'audio en texte"""
        
class RealMistralService:
    async def generate_response(self, user_input: str, conversation_type: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Génère une réponse IA"""
```

---

## Composants Détaillés

### 1. Collecteur de Métriques (interactive_conversation_tester.py)

**Métriques Temporelles :**
- tts_response_time : Temps de synthèse vocale
- vosk_response_time : Temps de transcription  
- mistral_response_time : Temps de génération IA
- total_exchange_time : Temps total d'échange

**Métriques Audio :**
- audio_duration : Durée de l'audio généré
- audio_quality_score : Score qualité audio (0-1)
- signal_to_noise_ratio : Rapport signal/bruit (dB)
- voice_activity_detection : Détection activité vocale

**Métriques IA :**
- response_relevance : Pertinence réponse (0-1)
- response_coherence : Cohérence textuelle (0-1)
- response_engagement : Niveau d'engagement (0-1)
- response_completeness : Complétude réponse (0-1)

**Métriques Conversationnelles :**
- conversation_flow_score : Fluidité conversation (0-1)
- topic_continuity : Continuité thématique (0-1)
- user_satisfaction_estimate : Satisfaction estimée (0-1)
- conversation_progress : Progression conversation (0-1)

**Métriques Techniques :**
- transcription_confidence : Confiance VOSK (0-1)
- api_response_time : Temps réponse API (ms)
- total_tokens_used : Tokens consommés
- cost_estimate : Coût estimé (euros)
- error_count : Nombre d'erreurs
- retry_count : Nombre de tentatives

### 2. Moteur de Conversation (conversation_engine.py)

**États de Conversation :**
- GREETING : Salutations initiales
- PRESENTATION : Présentation d'Eloquence  
- QUESTIONS_REPONSES : Questions/réponses
- NEGOCIATION : Négociation commerciale
- CLOSING : Clôture de conversation
- ERROR_RECOVERY : Récupération d'erreur

**Personnalités Utilisateur :**
- COMMERCIAL_CONFIANT : Commercial expérimenté et sûr
- CLIENT_EXIGEANT : Client difficile avec standards élevés
- PROSPECT_INTERESSE : Prospect curieux et engagé
- DECISION_MAKER : Décideur avec contraintes budgétaires
- TECHNICIEN_SCEPTIQUE : Expert technique méfiant

**Templates Conversationnels :**
- Messages adaptés par état et personnalité
- Variations contextuelles automatiques
- Historique et progression conversationnelle

### 3. Système Auto-Réparation (conversation_engine.py)

**Types de Problèmes Détectés :**
- response_too_short : Réponse IA trop courte
- low_engagement : Engagement utilisateur faible
- context_incoherence : Incohérence contextuelle
- service_timeout : Timeout de service
- transcription_error : Erreur de transcription
- ai_generation_error : Erreur génération IA

**Stratégies de Réparation :**
- **Contextuelle** : Ajustement selon l'état conversation
- **Technique** : Retry avec paramètres modifiés  
- **Conversationnelle** : Reformulation et relance
- **Escalade** : Passage en mode dégradé

### 4. Détecteur d'Anomalies (main_orchestrator.py)

**Seuils de Détection :**
- response_time_threshold : 15.0 secondes
- confidence_threshold : 0.6 (60%)
- relevance_threshold : 0.5 (50%)  
- engagement_threshold : 0.4 (40%)
- consecutive_failures_threshold : 2 échecs

**Types d'Anomalies :**
- excessive_response_time : Temps réponse trop élevé
- low_transcription_confidence : Confiance transcription faible
- low_ai_relevance : Pertinence IA insuffisante
- low_ai_engagement : Engagement IA faible
- consecutive_failures : Échecs consécutifs
- quality_regression : Régression qualité
- conversation_state_stuck : Blocage état conversation

### 5. Client LiveKit (livekit_virtual_user_client.py)

**Fonctionnalités :**
- Connexion WebSocket temps réel
- Génération audio synthétique réaliste  
- Gestion des callbacks et événements
- Sessions utilisateur avec personnalités
- Statistiques de performance

**Formats Audio Supportés :**
- WAV 16kHz mono
- Qualité CD avec réduction bruit
- Fade in/out automatique
- SNR optimisé

---

## Exemples Pratiques

### Exemple 1 : Test Commercial Standard

```python
import asyncio
from main_orchestrator import InteractiveConversationTester, TestConfiguration

async def test_commercial_standard():
    """Test de présentation commerciale standard"""
    
    # Configuration
    config = TestConfiguration(
        max_exchanges=8,
        scenario_type="presentation_client",
        user_personality="commercial_confiant",
        enable_auto_repair=True,
        enable_real_time_metrics=True,
        conversation_timeout=300.0,
        exchange_timeout=30.0
    )
    
    # Exécution
    tester = InteractiveConversationTester(config)
    report = await tester.run_interactive_conversation_test()
    
    # Analyse résultats
    success_rate = report['test_summary']['overall_success_rate']
    avg_time = report['test_summary']['average_exchange_time']
    
    print(f"Taux de succès : {success_rate:.1%}")
    print(f"Temps moyen par échange : {avg_time:.1f}s")
    
    # Recommandations
    for rec in report.get('recommendations', []):
        print(f"- {rec}")
    
    return report

# Lancer le test
report = asyncio.run(test_commercial_standard())
```

### Exemple 2 : Test Négociation Difficile

```python
async def test_negociation_difficile():
    """Test de négociation avec client exigeant"""
    
    config = TestConfiguration(
        max_exchanges=12,
        scenario_type="negociation_prix", 
        user_personality="client_exigeant",
        enable_auto_repair=True
    )
    
    tester = InteractiveConversationTester(config)
    
    # Modifier les seuils pour client difficile
    tester.anomaly_detector.anomaly_thresholds.update({
        'engagement_threshold': 0.3,  # Plus strict
        'consecutive_failures_threshold': 3  # Plus tolérant
    })
    
    report = await tester.run_interactive_conversation_test()
    
    # Analyser les objections
    objections = []
    for exchange in report['exchange_details']:
        if 'objection' in exchange['user_message'].lower():
            objections.append(exchange)
    
    print(f"Objections traitées : {len(objections)}")
    return report
```

### Exemple 3 : Test Support Technique

```python
async def test_support_technique():
    """Test de support technique spécialisé"""
    
    # Configuration spécifique support
    config = TestConfiguration(
        max_exchanges=6,
        scenario_type="support_technique",
        user_personality="technicien_sceptique"
    )
    
    tester = InteractiveConversationTester(config)
    
    # Personnaliser pour support technique
    tester.conversation_engine.context.scenario_type = "support_technique"
    
    report = await tester.run_interactive_conversation_test()
    
    # Vérifier résolution problème
    final_state = report['test_summary']['final_conversation_state']
    resolution_successful = final_state in ['conclusion', 'suivi']
    
    print(f"Problème résolu : {'Oui' if resolution_successful else 'Non'}")
    return report
```

### Exemple 4 : Test Personnalisé avec Scénarios

```python
from adaptive_conversation_scenarios import ConversationDynamics, ScenarioType, UserProfile

async def test_scenario_personnalise():
    """Test avec scénario et personnalité personnalisés"""
    
    # Configurer la dynamique conversationnelle
    dynamics = ConversationDynamics()
    dynamics.set_scenario(ScenarioType.COMMERCIAL_DEMO, UserProfile.DECISION_MAKER)
    
    # Générer quelques messages de test
    messages = []
    ai_response = None
    
    for i in range(5):
        user_data = dynamics.generate_contextual_user_message(ai_response)
        messages.append(user_data)
        
        # Simuler réponse IA
        ai_response = f"Excellente question ! Concernant {user_data['conversation_phase']}, notre solution..."
    
    # Métriques du scénario
    metrics = dynamics.get_scenario_metrics()
    
    print(f"Scénario : {metrics['scenario_name']}")
    print(f"Progression : {metrics['progression_percentage']:.1%}")
    print(f"Engagement : {metrics['user_engagement']:.1f}")
    
    return messages, metrics
```

### Exemple 5 : Validation Complète du Système

```python
from comprehensive_test_suite import ComprehensiveTestSuite

async def validation_complete():
    """Validation complète de tous les composants"""
    
    test_suite = ComprehensiveTestSuite()
    report = await test_suite.run_all_tests()
    
    # Résumé
    summary = report['summary']
    print(f"Tests total : {summary['total_tests']}")
    print(f"Succès : {summary['tests_passed']}")
    print(f"Échecs : {summary['tests_failed']}")
    print(f"Taux réussite : {summary['success_rate']:.1%}")
    
    # Tests échoués
    failed = report['failed_tests_analysis']
    if failed:
        print("\nTests échoués :")
        for test in failed:
            print(f"- {test['test_name']} : {test['error_message']}")
    
    # Recommandations
    print("\nRecommandations :")
    for rec in report['recommendations']:
        print(f"- {rec}")
    
    return report

# Lancer la validation
validation = asyncio.run(validation_complete())
```

---

## Configuration Avancée

### Personnalisation des Métriques

```python
# Ajouter des métriques personnalisées
class CustomMetricsCollector(ConversationMetricsCollector):
    
    def collect_exchange_metrics(self, exchange_data: Dict[str, Any]) -> ConversationMetrics:
        """Métriques personnalisées"""
        
        metrics = super().collect_exchange_metrics(exchange_data)
        
        # Métrique personnalisée : complexité du vocabulaire
        vocabulary_complexity = self._calculate_vocabulary_complexity(
            exchange_data['ai_response']
        )
        
        # Métrique personnalisée : adaptation culturelle
        cultural_adaptation = self._calculate_cultural_adaptation(
            exchange_data['user_message'],
            exchange_data['ai_response']
        )
        
        # Ajouter aux métriques existantes
        metrics.custom_vocabulary_complexity = vocabulary_complexity
        metrics.custom_cultural_adaptation = cultural_adaptation
        
        return metrics
    
    def _calculate_vocabulary_complexity(self, text: str) -> float:
        """Calcule la complexité du vocabulaire utilisé"""
        words = text.split()
        unique_words = set(words)
        avg_word_length = sum(len(word) for word in words) / len(words) if words else 0
        complexity = (len(unique_words) / len(words) if words else 0) * (avg_word_length / 10)
        return min(1.0, complexity)
    
    def _calculate_cultural_adaptation(self, user_msg: str, ai_response: str) -> float:
        """Évalue l'adaptation culturelle de la réponse"""
        # Logique personnalisée d'analyse culturelle
        return 0.8  # Exemple
```

### Stratégies de Réparation Personnalisées

```python
class CustomAutoRepairSystem(AutoRepairSystem):
    
    def __init__(self):
        super().__init__()
        
        # Ajouter des stratégies personnalisées
        self.repair_strategies.update({
            'custom_low_cultural_adaptation': self._repair_cultural_adaptation,
            'custom_vocabulary_too_complex': self._repair_vocabulary_complexity
        })
    
    def _repair_cultural_adaptation(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Répare les problèmes d'adaptation culturelle"""
        
        return {
            'success': True,
            'strategy_used': 'cultural_context_adjustment',
            'message': 'Ajustement du contexte culturel appliqué',
            'actions_taken': [
                'Modification du registre de langue',
                'Adaptation des références culturelles',
                'Ajustement du niveau de formalisme'
            ]
        }
    
    def _repair_vocabulary_complexity(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Répare la complexité excessive du vocabulaire"""
        
        return {
            'success': True,
            'strategy_used': 'vocabulary_simplification',
            'message': 'Simplification du vocabulaire appliquée',
            'actions_taken': [
                'Remplacement termes techniques',
                'Ajout d\'explications simples',
                'Utilisation de synonymes accessibles'
            ]
        }
```

### Scénarios Personnalisés

```python
from adaptive_conversation_scenarios import ScenarioTemplate, ConversationRule, ConversationPhase

def create_custom_scenario():
    """Créer un scénario personnalisé"""
    
    # Règles personnalisées
    custom_rules = [
        ConversationRule(
            condition="technical_demo_requested",
            action="provide_detailed_technical_explanation",
            priority=1,
            description="Fournir une explication technique détaillée",
            examples=[
                "Techniquement, notre algorithme utilise...",
                "L'architecture système repose sur..."
            ]
        ),
        ConversationRule(
            condition="integration_concerns_raised", 
            action="address_integration_specifics",
            priority=1,
            description="Traiter les préoccupations d'intégration",
            examples=[
                "Concernant l'intégration, nous proposons...",
                "Notre API REST facilite l'intégration..."
            ]
        )
    ]
    
    # Template de scénario personnalisé
    custom_scenario = ScenarioTemplate(
        scenario_type="technical_deep_dive",
        name="Plongée Technique Approfondie",
        description="Démonstration technique détaillée pour experts",
        conversation_phases=[
            ConversationPhase.ACCUEIL,
            ConversationPhase.IDENTIFICATION_BESOIN,
            ConversationPhase.PRESENTATION_SOLUTION,
            ConversationPhase.CONCLUSION
        ],
        user_profiles=["technicien_expert", "architecte_solution"],
        conversation_rules=custom_rules,
        expected_keywords={
            'accueil': ['expertise', 'technique', 'architecture'],
            'identification_besoin': ['intégration', 'api', 'performance'],
            'presentation_solution': ['algorithme', 'scalabilité', 'sécurité'],
            'conclusion': ['faisabilité', 'roadmap', 'implémentation']
        },
        success_criteria={
            'technical_depth_achieved': True,
            'integration_concerns_addressed': True,
            'architecture_explained': True,
            'performance_discussed': True
        },
        typical_duration=20.0,
        difficulty_level=5
    )
    
    return custom_scenario
```

---

## Monitoring et Métriques

### Surveillance en Temps Réel

Le système fournit un monitoring complet avec :

**Métriques de Performance :**
- Temps de réponse par service (TTS, VOSK, Mistral)
- Taux de succès des échanges
- Utilisation des ressources système
- Latence réseau et API

**Métriques de Qualité :**
- Score de pertinence des réponses IA
- Niveau d'engagement conversationnel  
- Cohérence contextuelle
- Satisfaction utilisateur estimée

**Métriques d'Anomalies :**
- Fréquence des anomalies par type
- Efficacité des réparations automatiques
- Temps de récupération après incident
- Tendances de dégradation

### Dashboard de Métriques

```python
def generate_metrics_dashboard(report: Dict[str, Any]) -> str:
    """Génère un dashboard ASCII des métriques principales"""
    
    summary = report['test_summary']
    
    dashboard = f"""
╔══════════════════════════════════════════════════════════════╗
║                    DASHBOARD MÉTRIQUES                       ║
╠══════════════════════════════════════════════════════════════╣
║ Échanges Réalisés    : {summary['total_exchanges']:>6}                      ║
║ Taux de Succès       : {summary['overall_success_rate']:>6.1%}                      ║
║ Temps Moyen/Échange  : {summary['average_exchange_time']:>6.1f}s                     ║
║ État Final           : {summary['final_conversation_state']:>15}           ║
║ Conversation Terminée: {'Oui' if summary['conversation_completed'] else 'Non':>6}                       ║
╠══════════════════════════════════════════════════════════════╣
║ Problèmes Détectés   : {summary['total_issues_detected']:>6}                      ║
║ Réparations Appliq.  : {summary['total_repairs_applied']:>6}                      ║
╚══════════════════════════════════════════════════════════════╝
"""
    
    return dashboard
```

### Alertes et Notifications

```python
class AlertSystem:
    """Système d'alertes pour monitoring"""
    
    def __init__(self):
        self.alert_thresholds = {
            'success_rate_critical': 0.5,      # 50%
            'response_time_warning': 10.0,     # 10s
            'response_time_critical': 20.0,    # 20s
            'anomaly_rate_warning': 0.2,       # 20%
            'anomaly_rate_critical': 0.4       # 40%
        }
    
    def check_alerts(self, metrics: Dict[str, Any]) -> List[str]:
        """Vérifie et génère les alertes nécessaires"""
        
        alerts = []
        
        # Alerte taux de succès
        success_rate = metrics.get('overall_success_rate', 1.0)
        if success_rate < self.alert_thresholds['success_rate_critical']:
            alerts.append(f"CRITIQUE: Taux de succès très faible ({success_rate:.1%})")
        
        # Alerte temps de réponse
        avg_time = metrics.get('average_exchange_time', 0)
        if avg_time > self.alert_thresholds['response_time_critical']:
            alerts.append(f"CRITIQUE: Temps de réponse excessif ({avg_time:.1f}s)")
        elif avg_time > self.alert_thresholds['response_time_warning']:
            alerts.append(f"ATTENTION: Temps de réponse élevé ({avg_time:.1f}s)")
        
        # Alerte anomalies
        total_exchanges = metrics.get('total_exchanges', 1)
        issues_detected = metrics.get('total_issues_detected', 0)
        anomaly_rate = issues_detected / total_exchanges if total_exchanges > 0 else 0
        
        if anomaly_rate > self.alert_thresholds['anomaly_rate_critical']:
            alerts.append(f"CRITIQUE: Taux d'anomalies très élevé ({anomaly_rate:.1%})")
        elif anomaly_rate > self.alert_thresholds['anomaly_rate_warning']:
            alerts.append(f"ATTENTION: Taux d'anomalies élevé ({anomaly_rate:.1%})")
        
        return alerts
```

---

## Dépannage

### Problèmes Courants et Solutions

**1. Service VOSK Inaccessible**

*Symptômes :*
- Erreur "Connection refused" port 2700
- Timeout lors de la transcription

*Solutions :*
```bash
# Vérifier le service
curl http://localhost:2700/health

# Redémarrer le service
cd services/vosk-stt-analysis
python main.py --port 2700

# Vérifier les logs
tail -f vosk_service.log
```

**2. Service TTS Indisponible**

*Symptômes :*
- Erreur génération audio
- API OpenAI inaccessible

*Solutions :*
```bash
# Vérifier configuration API
echo $OPENAI_API_KEY

# Test manuel du service
curl -X POST http://localhost:5002/synthesize \
  -H "Content-Type: application/json" \
  -d '{"text": "Test audio", "voice": "fr"}'

# Redémarrer avec debug
python main.py --port 5002 --debug
```

**3. LiveKit Connexion Échouée**

*Symptômes :*
- WebSocket connection failed
- Token validation error

*Solutions :*
```python
# Test de connexion LiveKit
from livekit_virtual_user_client import LiveKitVirtualUserClient

async def test_livekit():
    client = LiveKitVirtualUserClient()
    result = await client.test_livekit_connection()
    print(f"Connexion: {'OK' if result['connection_successful'] else 'ÉCHEC'}")
```

**4. Métriques Incomplètes**

*Symptômes :*
- Métriques manquantes dans le rapport
- Erreurs de calcul de métriques

*Solutions :*
```python
# Vérifier la collecte de métriques
from interactive_conversation_tester import ConversationMetricsCollector

collector = ConversationMetricsCollector()

# Test avec données minimales
test_data = {
    'user_message': 'Test',
    'ai_response': 'Réponse test',
    'conversation_state': 'greeting',
    # ... autres champs requis
}

metrics = collector.collect_exchange_metrics(test_data)
print(f"Métriques collectées: {len(asdict(metrics))} champs")
```

**5. Auto-Réparation Inefficace**

*Symptômes :*
- Réparations échouent systématiquement
- Même problème répété

*Solutions :*
```python
# Analyser les statistiques de réparation
from conversation_engine import AutoRepairSystem

repair_system = AutoRepairSystem()
stats = repair_system.get_repair_statistics()

print(f"Taux de succès réparations: {stats.get('success_rate', 0):.1%}")
print(f"Stratégies les plus utilisées: {stats.get('most_used_strategies', [])}")

# Ajuster les seuils si nécessaire
repair_system.repair_thresholds['max_retries'] = 5
```

### Logs et Diagnostics

**Activation du Logging Détaillé :**
```python
import logging

# Configuration logging avancé
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('conversation_test.log'),
        logging.StreamHandler()
    ]
)

# Logs spécifiques par composant
logger = logging.getLogger('ConversationTest')
logger.setLevel(logging.DEBUG)
```

**Diagnostic Performance :**
```python
import time
import psutil

def diagnose_performance():
    """Diagnostic des performances système"""
    
    # CPU et mémoire
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    
    # Espace disque
    disk = psutil.disk_usage('.')
    
    print(f"CPU: {cpu_percent}%")
    print(f"Mémoire: {memory.percent}% ({memory.used // (1024**3)}GB/{memory.total // (1024**3)}GB)")
    print(f"Disque: {disk.percent}% ({disk.free // (1024**3)}GB libres)")
    
    # Test réseau
    start = time.time()
    import requests
    try:
        requests.get('http://localhost:2700/health', timeout=5)
        network_latency = (time.time() - start) * 1000
        print(f"Latence réseau: {network_latency:.1f}ms")
    except Exception as e:
        print(f"Problème réseau: {e}")
```

---

## Performances et Optimisation

### Optimisations Recommandées

**1. Configuration Services**

*VOSK Optimisé :*
```python
# Configuration VOSK pour performance
vosk_config = {
    'model_size': 'small',      # Pour rapidité
    'beam_size': 10,            # Équilibre précision/vitesse
    'max_alternatives': 1,      # Une seule alternative
    'enable_partial_results': False  # Désactiver pour performance
}
```

*TTS Optimisé :*
```python
# Configuration TTS pour rapidité
tts_config = {
    'voice_speed': 1.2,         # Parole plus rapide
    'audio_quality': 'standard', # Qualité standard
    'enable_streaming': True,   # Streaming pour réactivité
    'cache_audio': True         # Cache pour répétitions
}
```

**2. Gestion Mémoire**

```python
import gc

class OptimizedConversationTester(InteractiveConversationTester):
    
    async def _execute_complete_exchange(self, ai_last_response: Optional[str]) -> ExchangeResult:
        """Version optimisée avec gestion mémoire"""
        
        result = await super()._execute_complete_exchange(ai_last_response)
        
        # Nettoyage mémoire après chaque échange
        if self.current_exchange % 5 == 0:  # Tous les 5 échanges
            gc.collect()
        
        return result
```

**3. Parallélisation**

```python
import asyncio
import concurrent.futures

async def run_parallel_tests(configurations: List[TestConfiguration]):
    """Lance plusieurs tests en parallèle"""
    
    async def run_single_test(config):
        tester = InteractiveConversationTester(config)
        return await tester.run_interactive_conversation_test()
    
    # Limiter le nombre de tests simultanés
    semaphore = asyncio.Semaphore(3)
    
    async def bounded_test(config):
        async with semaphore:
            return await run_single_test(config)
    
    # Lancer tous les tests
    tasks = [bounded_test(config) for config in configurations]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    return results
```

**4. Cache et Optimisations**

```python
from functools import lru_cache
import pickle

class CachedMetricsCollector(ConversationMetricsCollector):
    
    @lru_cache(maxsize=1000)
    def _calculate_relevance_cached(self, user_msg_hash: str, ai_response_hash: str) -> float:
        """Version cachée du calcul de pertinence"""
        # Utiliser les hashs pour cache, calculer si pas en cache
        return self._calculate_relevance_base(user_msg_hash, ai_response_hash)
    
    def _calculate_relevance(self, user_message: str, ai_response: str) -> float:
        """Utilise le cache pour optimiser"""
        user_hash = str(hash(user_message))
        ai_hash = str(hash(ai_response))
        return self._calculate_relevance_cached(user_hash, ai_hash)
```

### Benchmarks de Performance

**Métriques de Performance Cibles :**

| Composant | Temps Cible | Temps Acceptable | Temps Critique |
|-----------|-------------|------------------|----------------|
| TTS | < 2s | < 5s | > 10s |
| VOSK | < 1s | < 3s | > 8s |
| Mistral | < 3s | < 8s | > 15s |
| Échange Total | < 6s | < 15s | > 30s |
| Rapport Final | < 10s | < 30s | > 60s |

**Test de Performance :**
```python
async def benchmark_performance():
    """Benchmark de performance du système"""
    
    import time
    
    # Configuration de test
    config = TestConfiguration(max_exchanges=5)
    tester = InteractiveConversationTester(config)
    
    # Mesures
    start_time = time.time()
    
    # Test avec monitoring détaillé
    exchange_times = []
    
    for i in range(5):
        exchange_start = time.time()
        
        # Simuler un échange
        user_msg = tester.conversation_engine.generate_next_user_message()
        
        exchange_time = time.time() - exchange_start
        exchange_times.append(exchange_time)
    
    total_time = time.time() - start_time
    
    # Résultats
    results = {
        'total_time': total_time,
        'average_exchange_time': sum(exchange_times) / len(exchange_times),
        'min_exchange_time': min(exchange_times),
        'max_exchange_time': max(exchange_times),
        'exchanges_per_second': len(exchange_times) / total_time
    }
    
    return results
```

---

## Maintenance

### Tâches de Maintenance Régulières

**1. Nettoyage des Logs**
```bash
# Nettoyage hebdomadaire des logs
find ./logs -name "*.log" -mtime +7 -delete

# Rotation des logs volumineux
logrotate /etc/logrotate.d/conversation_test
```

**2. Mise à Jour des Modèles**
```bash
# Mise à jour modèle VOSK
cd services/vosk-stt-analysis
./download_model.sh --update

# Vérification compatibilité
python test_model_compatibility.py
```

**3. Monitoring Proactif**
```python
async def maintenance_check():
    """Vérification de maintenance automatique"""
    
    checks = []
    
    # Vérifier l'espace disque
    disk_usage = psutil.disk_usage('.')
    if disk_usage.percent > 85:
        checks.append(f"ATTENTION: Espace disque faible ({disk_usage.percent}%)")
    
    # Vérifier les services
    services = ['vosk:2700', 'tts:5002', 'livekit:7880']
    for service in services:
        host, port = service.split(':')
        try:
            # Test de connexion
            pass  # Implémenter test connexion
        except:
            checks.append(f"ERREUR: Service {service} inaccessible")
    
    # Vérifier les performances récentes
    # Analyser les logs des dernières 24h
    
    return checks
```

**4. Sauvegarde et Archivage**
```bash
# Script de sauvegarde quotidienne
#!/bin/bash

DATE=$(date +%Y%m%d)
BACKUP_DIR="./backups/$DATE"

mkdir -p $BACKUP_DIR

# Sauvegarder les configurations
cp config.env $BACKUP_DIR/
cp *.py $BACKUP_DIR/

# Sauvegarder les rapports récents
cp reports/*_$(date +%Y%m%d)*.json $BACKUP_DIR/

# Compression
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR

echo "Sauvegarde terminée: $BACKUP_DIR.tar.gz"
```

### Mise à Jour du Système

**1. Mise à Jour Patch (Correctifs)**
```bash
# Sauvegarder la configuration actuelle
cp config.env config.env.backup

# Appliquer les patches
git pull origin main

# Tester après mise à jour
python comprehensive_test_suite.py
```

**2. Mise à Jour Majeure (Nouvelles Fonctionnalités)**
```bash
# Sauvegarder complète
./backup_system.sh

# Mise à jour avec précautions
git checkout -b update_$(date +%Y%m%d)
git pull origin main

# Tests complets
python comprehensive_test_suite.py

# Validation manuelle
python main_orchestrator.py --config test_config.env
```

**3. Plan de Rollback**
```bash
# En cas de problème, retour version précédente
git checkout main
git reset --hard HEAD~1

# Restaurer la configuration
cp config.env.backup config.env

# Vérifier fonctionnement
python comprehensive_test_suite.py
```

### Optimisation Continue

**1. Analyse des Tendances**
```python
def analyze_performance_trends(reports_directory: str):
    """Analyse les tendances de performance sur plusieurs rapports"""
    
    import json
    import glob
    from datetime import datetime
    
    report_files = glob.glob(f"{reports_directory}/conversation_test_report_*.json")
    report_files.sort()
    
    trends = {
        'success_rates': [],
        'average_times': [],
        'anomaly_rates': [],
        'dates': []
    }
    
    for file_path in report_files[-30:]:  # 30 derniers rapports
        try:
            with open(file_path, 'r') as f:
                report = json.load(f)
            
            summary = report.get('test_summary', {})
            trends['success_rates'].append(summary.get('overall_success_rate', 0))
            trends['average_times'].append(summary.get('average_exchange_time', 0))
            
            # Extraire la date du nom de fichier
            timestamp = file_path.split('_')[-1].split('.')[0]
            date = datetime.fromtimestamp(int(timestamp))
            trends['dates'].append(date)
            
        except Exception as e:
            print(f"Erreur lecture rapport {file_path}: {e}")
    
    # Calculer les tendances
    if len(trends['success_rates']) >= 2:
        recent_avg = sum(trends['success_rates'][-7:]) / min(7, len(trends['success_rates']))
        older_avg = sum(trends['success_rates'][-14:-7]) / min(7, len(trends['success_rates'][:-7]))
        
        if recent_avg < older_avg * 0.95:  # Dégradation de 5%
            print("ALERTE: Dégradation des performances détectée")
        elif recent_avg > older_avg * 1.05:  # Amélioration de 5%
            print("AMÉLIORATION: Performances en hausse")
    
    return trends
```

**2. Recommandations Automatiques**
```python
def generate_optimization_recommendations(trends: Dict[str, List]) -> List[str]:
    """Génère des recommandations d'optimisation basées sur les tendances"""
    
    recommendations = []
    
    # Analyse du taux de succès
    if trends['success_rates']:
        recent_success = trends['success_rates'][-5:]
        avg_success = sum(recent_success) / len(recent_success)
        
        if avg_success < 0.9:
            recommendations.append("Investiguer les causes d'échec répétées")
            recommendations.append("Ajuster les seuils d'auto-réparation")
        
        # Variabilité
        if len(recent_success) > 1:
            variability = max(recent_success) - min(recent_success)
            if variability > 0.2:  # 20% de variabilité
                recommendations.append("Stabiliser les performances - variabilité élevée détectée")
    
    # Analyse des temps de réponse
    if trends['average_times']:
        recent_times = trends['average_times'][-5:]
        avg_time = sum(recent_times) / len(recent_times)
        
        if avg_time > 10.0:  # Plus de 10 secondes
            recommendations.append("Optimiser les temps de réponse des services")
            recommendations.append("Considérer la mise en cache des réponses fréquentes")
        
        # Tendance à la hausse
        if len(recent_times) >= 3:
            if all(recent_times[i] <= recent_times[i+1] for i in range(len(recent_times)-1)):
                recommendations.append("Temps de réponse en augmentation constante - investigation requise")
    
    if not recommendations:
        recommendations.append("Performances stables - continuer le monitoring régulier")
    
    return recommendations
```

---

## Conclusion

Ce système de test conversationnel interactif fournit une solution complète pour valider automatiquement les performances de l'IA Marie dans des conditions réalistes. Avec ses capacités d'auto-réparation, ses métriques exhaustives et son monitoring en temps réel, il assure une qualité conversationnelle optimale.

### Points Clés à Retenir

1. **Installation Simplifiée** : Configuration rapide avec détection automatique des services
2. **Tests Adaptatifs** : Scénarios qui s'adaptent aux réponses de l'IA en temps réel
3. **Monitoring Complet** : Plus de 30 métriques par échange avec alertes automatiques
4. **Auto-Réparation** : Correction automatique des problèmes détectés
5. **Rapports Détaillés** : JSON structuré avec recommandations d'amélioration

### Support et Contact

Pour toute question technique ou support :
- Consulter les logs détaillés dans `./logs/`
- Utiliser `comprehensive_test_suite.py` pour diagnostic complet
- Analyser les rapports JSON pour insights détaillés

**Version du Document :** 1.0  
**Dernière Mise à Jour :** 2025  
**Compatibilité Testée :** Windows 11, Python 3.8+