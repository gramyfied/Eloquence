# 🔧 Guide d'Implémentation des Exercices

## 🎯 Objectif

Ce guide explique comment implémenter de nouveaux exercices dans Eloquence.

## 🏗️ Architecture des Exercices

### 1. Template d'Exercice

Chaque exercice est défini par un template:

```python
{
    "id": "mon_exercice",
    "title": "Mon Exercice",
    "description": "Description de l'exercice",
    "type": "conversation|articulation|speaking|breathing",
    "duration": 600,  # secondes
    "difficulty": "beginner|intermediate|advanced|all",
    "focus_areas": ["confiance", "articulation"],
    "settings": {
        "custom_param": "valeur"
    }
}
```

### 2. Session d'Exercice

Une session représente une instance d'exercice:

```python
{
    "session_id": "session_abc123",
    "template_id": "mon_exercice",
    "user_id": "user_123",
    "livekit_room": "exercise_abc123",
    "status": "created|active|completed|failed",
    "settings": {},
    "metrics": {}
}
```

## 🔄 Flux d'Exécution

### 1. Création de Session

```python
# POST /api/v1/exercises/sessions
{
    "template_id": "confidence_boost",
    "user_id": "user_123",
    "settings": {
        "language": "fr",
        "difficulty": "intermediate"
    }
}
```

### 2. Connexion Temps Réel

```javascript
// Frontend Flutter
const websocket = WebSocket('ws://localhost:8080/api/v1/exercises/realtime/session_abc123');

// Envoyer audio
websocket.send(JSON.stringify({
    type: 'audio_chunk',
    data: base64AudioData
}));

// Recevoir métriques
websocket.onMessage = (event) => {
    const message = JSON.parse(event.data);
    if (message.type === 'metrics_update') {
        updateUI(message.metrics);
    }
};
```

### 3. Analyse Audio

```python
# Traitement automatique côté backend
async def process_audio_chunk(audio_data, session_id):
    # 1. Transcription avec Vosk
    transcription = await vosk_client.transcribe(audio_data)
    
    # 2. Analyse métriques
    metrics = calculate_speech_metrics(audio_data, transcription)
    
    # 3. Feedback IA avec Mistral
    feedback = await mistral_client.generate_feedback(transcription, metrics)
    
    # 4. Envoyer résultats via WebSocket
    await websocket.send_json({
        'type': 'metrics_update',
        'metrics': metrics,
        'feedback': feedback
    })
```

## 🎨 Créer un Nouvel Exercice

### Étape 1: Définir le Template

```python
# Dans services/eloquence-api/templates/mon_exercice.py
TEMPLATE = {
    "id": "presentation_elevator",
    "title": "Elevator Pitch",
    "description": "Présenter son projet en 60 secondes",
    "type": "speaking",
    "duration": 60,
    "difficulty": "intermediate",
    "focus_areas": ["structure", "persuasion", "concision"],
    "settings": {
        "topics": ["startup", "personnel", "produit"],
        "time_limit": 60,
        "feedback_frequency": "real_time"
    }
}
```

### Étape 2: Logique Métier

```python
# Dans services/eloquence-api/exercises/elevator_pitch.py
class ElevatorPitchExercise:
    def __init__(self, session_id: str, settings: dict):
        self.session_id = session_id
        self.settings = settings
        self.start_time = None
        
    async def start_session(self):
        """Démarrer l'exercice"""
        self.start_time = datetime.now()
        
        # Générer prompt initial
        topic = random.choice(self.settings['topics'])
        prompt = f"Présentez votre {topic} en 60 secondes maximum"
        
        return {
            "type": "exercise_start",
            "prompt": prompt,
            "time_limit": 60
        }
    
    async def process_audio(self, audio_data: bytes):
        """Traiter chunk audio"""
        # Transcription
        transcription = await self.transcribe_audio(audio_data)
        
        # Métriques spécifiques elevator pitch
        metrics = {
            "structure_score": self.analyze_structure(transcription),
            "persuasion_score": self.analyze_persuasion(transcription),
            "time_management": self.calculate_time_usage(),
            "clarity": self.analyze_clarity(audio_data)
        }
        
        return metrics
    
    def analyze_structure(self, text: str) -> float:
        """Analyser structure du pitch"""
        # Rechercher éléments clés: problème, solution, marché, équipe
        key_elements = ["problème", "solution", "marché", "équipe"]
        found_elements = sum(1 for elem in key_elements if elem in text.lower())
        return (found_elements / len(key_elements)) * 100
    
    def analyze_persuasion(self, text: str) -> float:
        """Analyser pouvoir de persuasion"""
        persuasive_words = ["unique", "innovant", "révolutionnaire", "opportunité"]
        count = sum(1 for word in persuasive_words if word in text.lower())
        return min(count * 25, 100)  # Max 100%
```

### Étape 3: Interface Frontend

```dart
// Dans frontend/flutter_app/lib/features/exercises/elevator_pitch/
class ElevatorPitchScreen extends StatefulWidget {
  final String sessionId;
  
  @override
  _ElevatorPitchScreenState createState() => _ElevatorPitchScreenState();
}

class _ElevatorPitchScreenState extends State<ElevatorPitchScreen> {
  WebSocketChannel? _channel;
  Map<String, double> _metrics = {};
  String _currentPrompt = "";
  int _timeRemaining = 60;
  
  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }
  
  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/api/v1/exercises/realtime/${widget.sessionId}')
    );
    
    _channel!.stream.listen((message) {
      final data = json.decode(message);
      
      if (data['type'] == 'exercise_start') {
        setState(() {
          _currentPrompt = data['prompt'];
          _timeRemaining = data['time_limit'];
        });
      } else if (data['type'] == 'metrics_update') {
        setState(() {
          _metrics = Map<String, double>.from(data['metrics']);
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Elevator Pitch')),
      body: Column(
        children: [
          // Timer
          Text('Temps restant: $_timeRemaining s'),
          
          // Prompt
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(_currentPrompt),
            ),
          ),
          
          // Métriques temps réel
          if (_metrics.isNotEmpty) ...[
            Text('Structure: ${_metrics['structure_score']?.toInt()}%'),
            Text('Persuasion: ${_metrics['persuasion_score']?.toInt()}%'),
            Text('Clarté: ${_metrics['clarity']?.toInt()}%'),
          ],
          
          // Bouton enregistrement
          ElevatedButton(
            onPressed: _startRecording,
            child: Text('Commencer'),
          ),
        ],
      ),
    );
  }
}
```

## 📊 Métriques Personnalisées

### Définir des Métriques

```python
class ExerciseMetrics:
    """Métriques spécifiques par type d'exercice"""
    
    @staticmethod
    def conversation_metrics(audio_data, transcription):
        return {
            "engagement": calculate_engagement(audio_data),
            "naturalness": calculate_naturalness(transcription),
            "response_time": calculate_response_time(audio_data)
        }
    
    @staticmethod
    def articulation_metrics(audio_data, transcription):
        return {
            "pronunciation_accuracy": calculate_pronunciation(audio_data),
            "speech_rate": calculate_speech_rate(transcription),
            "articulation_clarity": calculate_articulation(audio_data)
        }
    
    @staticmethod
    def speaking_metrics(audio_data, transcription):
        return {
            "structure_score": analyze_structure(transcription),
            "vocabulary_richness": calculate_vocabulary(transcription),
            "persuasiveness": analyze_persuasion(transcription)
        }
```

## 🔧 Configuration Avancée

### Paramètres d'Exercice

```python
# Configuration flexible par exercice
EXERCISE_CONFIGS = {
    "confidence_boost": {
        "ai_personality": "encouraging",
        "feedback_frequency": "continuous",
        "difficulty_adaptation": True,
        "voice_analysis": ["tone", "pace", "volume"]
    },
    "tongue_twister": {
        "progressive_difficulty": True,
        "repetition_count": 3,
        "speed_target": 1.5,  # multiplicateur vitesse
        "accuracy_threshold": 85  # % minimum
    }
}
```

## 🚀 Déploiement

### Ajouter à l'API

```python
# Dans services/eloquence-api/app.py
from exercises.elevator_pitch import ElevatorPitchExercise

EXERCISE_CLASSES = {
    "confidence_boost": ConfidenceBoostExercise,
    "tongue_twister": TongueTwisterExercise,
    "elevator_pitch": ElevatorPitchExercise,  # Nouveau
}

@app.websocket("/api/v1/exercises/realtime/{session_id}")
async def websocket_exercise(websocket: WebSocket, session_id: str):
    # Récupérer type d'exercice
    session = get_session(session_id)
    exercise_class = EXERCISE_CLASSES[session.template_id]
    
    # Instancier exercice
    exercise = exercise_class(session_id, session.settings)
    
    # Traitement temps réel
    await exercise.handle_websocket(websocket)
```

## ✅ Tests

```python
# tests/test_elevator_pitch.py
import pytest
from exercises.elevator_pitch import ElevatorPitchExercise

@pytest.mark.asyncio
async def test_elevator_pitch_structure():
    exercise = ElevatorPitchExercise("test_session", {})
    
    # Test analyse structure
    text = "Notre startup résout le problème de transport avec une solution innovante"
    score = exercise.analyze_structure(text)
    
    assert score > 0
    assert score <= 100

@pytest.mark.asyncio
async def test_elevator_pitch_timing():
    exercise = ElevatorPitchExercise("test_session", {"time_limit": 60})
    
    # Simuler dépassement temps
    exercise.start_time = datetime.now() - timedelta(seconds=70)
    time_score = exercise.calculate_time_usage()
    
    assert time_score < 100  # Pénalité dépassement
```

## 🔗 Intégration avec Services Existants

### Utiliser Vosk pour STT

```python
async def transcribe_audio(self, audio_data: bytes) -> str:
    """Transcription avec Vosk"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{VOSK_URL}/transcribe",
            files={"audio": audio_data}
        )
        return response.json()["transcription"]
```

### Utiliser Mistral pour Feedback

```python
async def generate_feedback(self, transcription: str, metrics: dict) -> str:
    """Feedback IA avec Mistral"""
    prompt = f"""
    Analysez cette présentation elevator pitch:
    Transcription: {transcription}
    Métriques: {metrics}
    
    Donnez un feedback constructif en français.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{MISTRAL_URL}/generate",
            json={"prompt": prompt}
        )
        return response.json()["response"]
```

## 📱 Intégration Frontend

### Service Flutter

```dart
class ElevatorPitchService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  Future<String> createSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'template_id': 'elevator_pitch',
        'settings': {
          'topic': 'startup',
          'time_limit': 60
        }
      }),
    );
    
    final data = json.decode(response.body);
    return data['session_id'];
  }
  
  WebSocketChannel connectRealtime(String sessionId) {
    return WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/api/v1/exercises/realtime/$sessionId')
    );
  }
}
```

Ce guide vous permet d'implémenter facilement de nouveaux exercices dans Eloquence ! 🚀
