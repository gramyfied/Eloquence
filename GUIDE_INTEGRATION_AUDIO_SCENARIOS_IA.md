# 🎯 Guide d'Intégration Audio pour les Scénarios IA

## 📋 Vue d'Ensemble

Ce guide explique comment intégrer les exercices audio dans les scénarios IA d'Eloquence, en utilisant l'infrastructure existante (LiveKit, Vosk, Mistral) avec la configuration locale (192.168.1.44).

## 🏗️ Architecture Complète

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│                     │    │                     │    │                     │
│  Flutter App        │───▶│   Scénarios IA      │───▶│    LiveKit Agent    │
│  (Scénarios)        │    │   Configuration     │    │   (Conversation)    │
│                     │    │                     │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                           │                           │
           │                           │                           │
           ▼                           ▼                           ▼
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│                     │    │                     │    │                     │
│  Exercices API      │───▶│    Service Vosk     │───▶│   Service Mistral   │
│  (Port 8005)        │    │    (Port 8002)      │    │    (Port 8001)      │
│                     │    │                     │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                           │                           │
           │                           │                           │
           └───────────────────────────┼───────────────────────────┘
                                       │
                                       ▼
                             ┌─────────────────────┐
                             │                     │
                             │       Redis         │
                             │   (Stockage)        │
                             │                     │
                             └─────────────────────┘
```

## 🎯 Objectifs d'Intégration

### Pour les Scénarios IA
1. **Conversation temps réel** avec l'IA via LiveKit
2. **Analyse vocale** en temps réel avec Vosk
3. **Feedback intelligent** basé sur les métriques vocales
4. **Coaching adaptatif** selon le type de scénario

### Fonctionnalités Cibles
- ✅ **STT en temps réel** : Transcription de la parole utilisateur
- ✅ **Analyse vocale** : Métriques de clarté, fluidité, confiance
- ✅ **IA conversationnelle** : Réponses contextuelles de l'IA
- ✅ **TTS** : Synthèse vocale pour les réponses IA
- ✅ **Feedback adaptatif** : Conseils selon le scénario

## 🔧 Configuration Locale

### Services Requis (IP: 192.168.1.44)

| Service | Port | URL | Fonction |
|---------|------|-----|----------|
| **LiveKit Server** | 7880 | ws://192.168.1.44:7880 | WebRTC Audio/Video |
| **LiveKit Agent** | - | - | IA Conversationnelle |
| **Vosk STT** | 8002 | http://192.168.1.44:8002 | Speech-to-Text |
| **Mistral** | 8001 | http://192.168.1.44:8001 | IA Textuelle |
| **Exercices API** | 8005 | http://192.168.1.44:8005 | Analyse Vocale |
| **Token Service** | 8004 | http://192.168.1.44:8004 | Tokens LiveKit |
| **Redis** | 6379 | 192.168.1.44:6379 | Cache/Stockage |

### Démarrage des Services

```powershell
# Démarrer tous les services locaux
.\scripts\dev-local.ps1

# Ou manuellement
docker-compose -f docker-compose.local.yml up -d
```

## 📱 Intégration Flutter

### 1. Service d'Intégration Audio-Scénarios

Créer un service unifié pour les scénarios IA avec audio :

```dart
// lib/features/ai_scenarios/data/services/scenario_audio_service.dart

class ScenarioAudioService {
  final LiveKitService _liveKitService;
  final VoiceAnalysisService _voiceAnalysisService;
  final ScenarioConversationService _conversationService;
  
  // Configuration selon le type de scénario
  Future<void> configureForScenario(ScenarioType type) async {
    switch (type) {
      case ScenarioType.jobInterview:
        await _configureJobInterview();
        break;
      case ScenarioType.salesPitch:
        await _configureSalesPitch();
        break;
      case ScenarioType.presentation:
        await _configurePresentation();
        break;
      case ScenarioType.networking:
        await _configureNetworking();
        break;
    }
  }
  
  // Démarrer session audio avec IA
  Future<void> startAudioSession(ScenarioConfiguration config) async {
    // 1. Initialiser LiveKit
    await _liveKitService.connect(
      url: 'ws://192.168.1.44:7880',
      token: await _getScenarioToken(config),
    );
    
    // 2. Configurer l'agent IA selon le scénario
    await _conversationService.initializeScenario(config);
    
    // 3. Démarrer l'analyse vocale en temps réel
    await _voiceAnalysisService.startRealTimeAnalysis();
  }
  
  // Analyser la performance vocale
  Future<ScenarioVoiceMetrics> analyzeVoicePerformance(
    File audioFile,
    ScenarioType scenarioType,
  ) async {
    final analysis = await _voiceAnalysisService.analyzeDetailed(
      audioFile: audioFile,
      exerciseType: _mapScenarioToExerciseType(scenarioType),
    );
    
    return ScenarioVoiceMetrics.fromVoiceAnalysis(analysis, scenarioType);
  }
}
```

### 2. Modèles de Données Étendus

```dart
// lib/features/ai_scenarios/domain/entities/scenario_audio_models.dart

class ScenarioVoiceMetrics {
  final double clarity;
  final double fluency;
  final double confidence;
  final double energy;
  final double scenarioSpecificScore; // Score adapté au scénario
  final List<String> strengths;
  final List<String> improvements;
  final String scenarioFeedback;
  
  // Feedback spécialisé selon le scénario
  static ScenarioVoiceMetrics fromVoiceAnalysis(
    VoiceAnalysisResult analysis,
    ScenarioType scenarioType,
  ) {
    switch (scenarioType) {
      case ScenarioType.jobInterview:
        return _createJobInterviewMetrics(analysis);
      case ScenarioType.salesPitch:
        return _createSalesPitchMetrics(analysis);
      case ScenarioType.presentation:
        return _createPresentationMetrics(analysis);
      case ScenarioType.networking:
        return _createNetworkingMetrics(analysis);
    }
  }
}

class ScenarioAudioSession {
  final String sessionId;
  final ScenarioType scenarioType;
  final DateTime startTime;
  final Duration duration;
  final List<ConversationTurn> turns;
  final ScenarioVoiceMetrics finalMetrics;
  final AIPersonalityType aiPersonality;
}

class ConversationTurn {
  final String speaker; // 'user' ou 'ai'
  final String text;
  final DateTime timestamp;
  final Duration duration;
  final ScenarioVoiceMetrics? voiceMetrics; // Seulement pour l'utilisateur
}
```

### 3. Provider Étendu pour Scénarios Audio

```dart
// lib/features/ai_scenarios/presentation/providers/scenario_audio_provider.dart

class ScenarioAudioProvider extends StateNotifier<ScenarioAudioState> {
  final ScenarioAudioService _audioService;
  final ScenarioProvider _scenarioProvider;
  
  // Démarrer session avec audio
  Future<void> startAudioSession() async {
    state = state.copyWith(status: ScenarioAudioStatus.connecting);
    
    try {
      final config = _scenarioProvider.currentConfiguration;
      await _audioService.startAudioSession(config);
      
      state = state.copyWith(
        status: ScenarioAudioStatus.active,
        sessionId: _generateSessionId(),
        startTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: ScenarioAudioStatus.error,
        error: 'Erreur connexion audio: $e',
      );
    }
  }
  
  // Traiter un tour de conversation
  Future<void> processUserSpeech(File audioFile) async {
    try {
      // 1. Analyser la voix de l'utilisateur
      final voiceMetrics = await _audioService.analyzeVoicePerformance(
        audioFile,
        _scenarioProvider.currentConfiguration.scenarioType,
      );
      
      // 2. Transcrire le texte
      final transcription = await _audioService.transcribeAudio(audioFile);
      
      // 3. Ajouter le tour utilisateur
      final userTurn = ConversationTurn(
        speaker: 'user',
        text: transcription,
        timestamp: DateTime.now(),
        duration: await _getAudioDuration(audioFile),
        voiceMetrics: voiceMetrics,
      );
      
      state = state.copyWith(
        turns: [...state.turns, userTurn],
        currentMetrics: voiceMetrics,
      );
      
      // 4. Générer réponse IA
      await _generateAIResponse(transcription, voiceMetrics);
      
    } catch (e) {
      state = state.copyWith(error: 'Erreur traitement audio: $e');
    }
  }
  
  // Générer réponse IA contextuelle
  Future<void> _generateAIResponse(
    String userText,
    ScenarioVoiceMetrics voiceMetrics,
  ) async {
    final config = _scenarioProvider.currentConfiguration;
    
    // Contexte pour l'IA incluant les métriques vocales
    final context = ScenarioContext(
      scenarioType: config.scenarioType,
      aiPersonality: config.aiPersonality,
      userPerformance: voiceMetrics,
      conversationHistory: state.turns,
      sessionDuration: DateTime.now().difference(state.startTime),
    );
    
    final aiResponse = await _audioService.generateAIResponse(
      userText: userText,
      context: context,
    );
    
    // Ajouter le tour IA
    final aiTurn = ConversationTurn(
      speaker: 'ai',
      text: aiResponse.text,
      timestamp: DateTime.now(),
      duration: Duration.zero, // Sera mis à jour après TTS
    );
    
    state = state.copyWith(
      turns: [...state.turns, aiTurn],
      lastAIResponse: aiResponse,
    );
    
    // Synthèse vocale de la réponse IA
    await _audioService.speakAIResponse(aiResponse.text);
  }
}
```

### 4. Interface Utilisateur Enrichie

```dart
// lib/features/ai_scenarios/presentation/screens/scenario_exercise_audio_screen.dart

class ScenarioExerciseAudioScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioState = ref.watch(scenarioProvider);
    final audioState = ref.watch(scenarioAudioProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // En-tête avec métriques temps réel
          _buildRealTimeMetricsHeader(audioState.currentMetrics),
          
          // Zone de conversation avec avatar IA
          Expanded(
            child: _buildConversationArea(audioState.turns),
          ),
          
          // Contrôles audio avec feedback visuel
          _buildAudioControls(audioState),
          
          // Métriques vocales en temps réel
          _buildVoiceMetricsPanel(audioState.currentMetrics),
        ],
      ),
    );
  }
  
  Widget _buildRealTimeMetricsHeader(ScenarioVoiceMetrics? metrics) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricIndicator(
            label: 'Clarté',
            value: metrics?.clarity ?? 0.0,
            color: EloquenceTheme.cyan,
          ),
          _MetricIndicator(
            label: 'Fluidité',
            value: metrics?.fluency ?? 0.0,
            color: EloquenceTheme.violet,
          ),
          _MetricIndicator(
            label: 'Confiance',
            value: metrics?.confidence ?? 0.0,
            color: EloquenceTheme.successGreen,
          ),
          _MetricIndicator(
            label: 'Énergie',
            value: metrics?.energy ?? 0.0,
            color: EloquenceTheme.warningOrange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildConversationArea(List<ConversationTurn> turns) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: turns.length,
      itemBuilder: (context, index) {
        final turn = turns[index];
        return _ConversationBubble(
          turn: turn,
          isUser: turn.speaker == 'user',
        );
      },
    );
  }
  
  Widget _buildAudioControls(ScenarioAudioState audioState) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton microphone avec animation
          _AnimatedMicrophoneButton(
            isRecording: audioState.isRecording,
            onPressed: () => _handleMicrophonePress(context),
          ),
          
          // Bouton pause/reprise
          IconButton(
            icon: Icon(audioState.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => _handlePauseResume(context),
          ),
          
          // Bouton aide (suggestions contextuelles)
          _HelpButton(
            scenarioType: audioState.scenarioType,
            onPressed: () => _showContextualHelp(context),
          ),
        ],
      ),
    );
  }
}
```

## 🎯 Feedback Spécialisé par Scénario

### 1. Entretien d'Embauche

```dart
class JobInterviewFeedbackGenerator {
  static ScenarioVoiceMetrics generateMetrics(VoiceAnalysisResult analysis) {
    return ScenarioVoiceMetrics(
      clarity: analysis.clarity,
      fluency: analysis.fluency,
      confidence: analysis.confidence * 1.2, // Poids plus important
      energy: analysis.energy,
      scenarioSpecificScore: _calculateJobInterviewScore(analysis),
      strengths: _identifyJobInterviewStrengths(analysis),
      improvements: _identifyJobInterviewImprovements(analysis),
      scenarioFeedback: _generateJobInterviewFeedback(analysis),
    );
  }
  
  static String _generateJobInterviewFeedback(VoiceAnalysisResult analysis) {
    if (analysis.confidence > 0.8) {
      return "Excellente assurance ! Votre confiance transparaît dans votre voix, "
             "ce qui est essentiel en entretien.";
    } else if (analysis.confidence > 0.6) {
      return "Bonne présence vocale. Travaillez sur l'assurance pour projeter "
             "plus de confiance en vos compétences.";
    } else {
      return "Votre nervosité se ressent dans votre voix. Respirez profondément "
             "et rappelez-vous vos qualités avant de répondre.";
    }
  }
}
```

### 2. Présentation Commerciale

```dart
class SalesPitchFeedbackGenerator {
  static ScenarioVoiceMetrics generateMetrics(VoiceAnalysisResult analysis) {
    return ScenarioVoiceMetrics(
      clarity: analysis.clarity,
      fluency: analysis.fluency,
      confidence: analysis.confidence,
      energy: analysis.energy * 1.3, // Énergie cruciale en vente
      scenarioSpecificScore: _calculateSalesPitchScore(analysis),
      strengths: _identifySalesPitchStrengths(analysis),
      improvements: _identifySalesPitchImprovements(analysis),
      scenarioFeedback: _generateSalesPitchFeedback(analysis),
    );
  }
  
  static String _generateSalesPitchFeedback(VoiceAnalysisResult analysis) {
    if (analysis.energy > 0.8) {
      return "Excellent dynamisme ! Votre enthousiasme est contagieux et "
             "captivera vos prospects.";
    } else {
      return "Augmentez votre énergie vocale pour transmettre votre passion "
             "pour le produit et convaincre vos clients.";
    }
  }
}
```

## 🔧 Configuration des Services

### 1. Variables d'Environnement (.env)

```env
# Configuration locale
SERVER_MODE=LOCAL
LOCAL_IP=192.168.1.44

# LiveKit
LIVEKIT_URL=ws://192.168.1.44:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret123456789abcdef0123456789abcdef

# Services
VOSK_SERVICE_URL=http://192.168.1.44:8002
MISTRAL_API_URL=http://192.168.1.44:8001
EXERCISES_API_URL=http://192.168.1.44:8005
TOKEN_SERVICE_URL=http://192.168.1.44:8004

# Redis
REDIS_URL=redis://192.168.1.44:6379/0

# API Keys (à configurer)
MISTRAL_API_KEY=your_mistral_key
OPENAI_API_KEY=your_openai_key_for_tts
```

### 2. Configuration Docker Compose Local

```yaml
# docker-compose.local.yml (extrait)
services:
  livekit-agent:
    environment:
      - LIVEKIT_URL=ws://192.168.1.44:7880
      - VOSK_SERVICE_URL=http://192.168.1.44:8002
      - MISTRAL_API_URL=http://192.168.1.44:8001
      - SCENARIO_MODE=enabled
    ports:
      - "192.168.1.44:8006:8006"
```

## 🧪 Tests et Validation

### 1. Test de l'Intégration Complète

```python
# test_scenario_audio_integration.py

async def test_complete_scenario_audio_flow():
    """Test du flux complet scénario + audio"""
    
    # 1. Test des services de base
    assert await test_livekit_connectivity()
    assert await test_vosk_connectivity()
    assert await test_mistral_connectivity()
    
    # 2. Test de génération de token pour scénario
    token = await generate_scenario_token("job_interview_room", "candidate")
    assert token is not None
    
    # 3. Test d'analyse vocale spécialisée
    audio_file = "test_job_interview.wav"
    analysis = await analyze_scenario_voice(audio_file, "job_interview")
    assert analysis["scenario_specific_score"] > 0
    
    # 4. Test de conversation IA
    response = await generate_ai_response(
        user_text="Bonjour, je suis ravi d'être ici",
        scenario_type="job_interview",
        voice_metrics=analysis["metrics"]
    )
    assert "entretien" in response.lower()
    
    print("✅ Intégration scénario + audio validée")
```

### 2. Script de Test Rapide

```powershell
# test_scenario_audio.ps1

Write-Host "🧪 Test Intégration Scénarios Audio" -ForegroundColor Cyan

# Test des services
$services = @(
    @{Name="LiveKit"; URL="http://192.168.1.44:7880"},
    @{Name="Vosk"; URL="http://192.168.1.44:8002/health"},
    @{Name="Mistral"; URL="http://192.168.1.44:8001/health"},
    @{Name="Exercices API"; URL="http://192.168.1.44:8005/health"},
    @{Name="Token Service"; URL="http://192.168.1.44:8004/health"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 5
        Write-Host "✅ $($service.Name): OK" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($service.Name): KO" -ForegroundColor Red
    }
}

# Test spécifique scénarios
python test_scenario_audio_integration.py
```

## 🚀 Déploiement et Utilisation

### 1. Démarrage Complet

```powershell
# 1. Démarrer tous les services
.\scripts\dev-local.ps1

# 2. Vérifier la connectivité
python test_livekit_audio_local.py

# 3. Tester l'intégration scénarios
python test_scenario_audio_integration.py

# 4. Démarrer Flutter
cd frontend/flutter_app
flutter run
```

### 2. Utilisation dans l'App

1. **Configuration** : Sélectionner un scénario avec audio activé
2. **Connexion** : L'app se connecte automatiquement aux services locaux
3. **Conversation** : Interaction vocale temps réel avec l'IA
4. **Analyse** : Métriques vocales en temps réel
5. **Feedback** : Conseils spécialisés selon le scénario

## 🔧 Dépannage

### Problèmes Fréquents

| Problème | Cause | Solution |
|----------|-------|----------|
| IA muette | TTS non configuré | Vérifier OPENAI_API_KEY dans .env |
| Pas de transcription | Vosk inaccessible | Redémarrer service vosk-stt |
| Connexion échoue | LiveKit non démarré | Vérifier docker-compose logs |
| Métriques vides | Exercices API KO | Redémarrer eloquence-exercises-api |

### Commandes de Debug

```powershell
# Logs des services
docker-compose -f docker-compose.local.yml logs livekit-agent
docker-compose -f docker-compose.local.yml logs vosk-stt
docker-compose -f docker-compose.local.yml logs eloquence-exercises-api

# Test de connectivité
curl http://192.168.1.44:8005/health
curl http://192.168.1.44:8002/health

# Test audio spécifique
python test_livekit_audio_local.py
```

## 🎉 Résultat Final

Cette intégration permet de créer **l'expérience de scénarios IA la plus avancée** avec :

- ✅ **Conversation vocale temps réel** avec l'IA
- ✅ **Analyse vocale spécialisée** selon le scénario
- ✅ **Feedback intelligent adaptatif**
- ✅ **Métriques en temps réel**
- ✅ **Configuration locale simplifiée**

L'utilisateur peut maintenant pratiquer des scénarios professionnels avec une IA qui l'écoute, l'analyse et lui donne des conseils personnalisés en temps réel !

---

**🚀 Prêt pour l'implémentation avec votre configuration locale (192.168.1.44)**
