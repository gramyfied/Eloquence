from pydantic import BaseModel, Field, ConfigDict
from typing import Dict, List, Optional, Any
import uuid
from datetime import datetime
from enum import Enum

class ExerciseTemplate(BaseModel):
    """Template d'exercice prédéfini"""
    template_id: str
    title: str
    description: str
    exercise_type: str
    default_duration_seconds: int = 600
    difficulty: str
    focus_areas: List[str]
    custom_settings: Dict[str, Any] = {}

class ExerciseConfig(BaseModel):
    """Configuration d'un exercice spécifique"""
    exercise_id: str = Field(default_factory=lambda: f"ex_{uuid.uuid4().hex[:8]}")
    template_id: Optional[str] = None
    title: str
    description: str
    exercise_type: str
    max_duration_seconds: int = 600
    language: str = "fr"
    difficulty: str = "intermediate"
    focus_areas: List[str] = []
    livekit_room_prefix: str = "exercise_"
    custom_settings: Dict[str, Any] = {}

class SessionConfig(BaseModel):
    """Configuration d'une session d'exercice"""
    session_id: str = Field(default_factory=lambda: f"session_{uuid.uuid4().hex[:10]}")
    exercise_id: str
    user_id: Optional[str] = None
    language: str = "fr"
    max_duration_seconds: Optional[int] = None
    custom_settings: Dict[str, Any] = {}

class SessionData(BaseModel):
    """Données d'une session d'exercice"""
    model_config = ConfigDict(
        # Sérialise automatiquement les datetime en ISO format
        json_encoders={datetime: lambda v: v.isoformat()}
    )
    
    session_id: str
    exercise_id: str
    livekit_room: str
    status: str = "created"
    config: Dict[str, Any]
    created_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    evaluation: Optional[Dict[str, Any]] = None

class ExerciseEvaluation(BaseModel):
    """Évaluation d'un exercice complété"""
    session_id: str
    overall_score: float = Field(ge=0.0, le=100.0)
    confidence_level: float = Field(ge=0.0, le=100.0)
    voice_clarity: float = Field(ge=0.0, le=100.0)
    engagement: float = Field(ge=0.0, le=100.0)
    improvement_areas: List[str] = []
    achievements: List[str] = []
    feedback: Optional[str] = None
    detailed_metrics: Dict[str, Any] = {}

class LiveKitSessionInfo(BaseModel):
    """Information de session LiveKit"""
    session_id: str
    exercise_id: str
    livekit_room: str
    livekit_url: str
    token: str
    status: str
    participant_name: Optional[str] = None
    metadata: Dict[str, Any] = {}

class ExerciseResponse(BaseModel):
    """Réponse pour la création d'exercice"""
    exercise_id: str
    title: str
    status: str
    message: Optional[str] = None

class SessionResponse(BaseModel):
    """Réponse pour la création de session"""
    session_id: str
    exercise_id: str
    livekit_room: str
    livekit_url: str
    token: str
    status: str
    metadata: Optional[Dict[str, Any]] = None

# ============================================
# Modèles pour l'analyse temps réel WebSocket
# ============================================

class RealTimeMessageType(str, Enum):
    """Types de messages WebSocket pour l'analyse temps réel"""
    AUDIO_CHUNK = "audio_chunk"
    START_SESSION = "start_session"
    END_SESSION = "end_session"
    PARTIAL_RESULT = "partial_result"
    FINAL_RESULT = "final_result"
    ERROR = "error"
    METRICS_UPDATE = "metrics_update"

class RealTimeAudioChunk(BaseModel):
    """Chunk audio pour analyse temps réel"""
    type: RealTimeMessageType = RealTimeMessageType.AUDIO_CHUNK
    session_id: str
    chunk_id: int
    audio_data: str  # Base64 encoded audio
    sample_rate: int = 16000
    timestamp: datetime = Field(default_factory=datetime.now)

class RealTimeSessionStart(BaseModel):
    """Message de début de session temps réel"""
    type: RealTimeMessageType = RealTimeMessageType.START_SESSION
    session_id: str
    exercise_type: str
    user_id: str
    settings: Optional[Dict[str, Any]] = None

class RealTimePartialResult(BaseModel):
    """Résultat partiel de l'analyse temps réel"""
    type: RealTimeMessageType = RealTimeMessageType.PARTIAL_RESULT
    session_id: str
    chunk_id: int
    transcription: str
    confidence: float
    timestamp: datetime
    partial_metrics: Dict[str, float]

class RealTimeMetricsUpdate(BaseModel):
    """Mise à jour des métriques en temps réel"""
    type: RealTimeMessageType = RealTimeMessageType.METRICS_UPDATE
    session_id: str
    timestamp: datetime
    clarity_score: float
    fluency_score: float
    energy_score: float
    speaking_rate: float  # mots par minute
    pause_ratio: float
    cumulative_confidence: float

class RealTimeFinalResult(BaseModel):
    """Résultat final de l'analyse temps réel"""
    type: RealTimeMessageType = RealTimeMessageType.FINAL_RESULT
    session_id: str
    total_duration: float
    final_transcription: str
    overall_metrics: Dict[str, float]
    strengths: List[str]
    improvements: List[str]
    feedback: str
    processing_time: float

class RealTimeError(BaseModel):
    """Message d'erreur pour WebSocket"""
    type: RealTimeMessageType = RealTimeMessageType.ERROR
    session_id: str
    error_code: str
    error_message: str
    timestamp: datetime = Field(default_factory=datetime.now)