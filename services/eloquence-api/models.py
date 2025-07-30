from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum
import uuid

class ExerciseType(str, Enum):
    CONVERSATION = "conversation"
    ARTICULATION = "articulation"
    SPEAKING = "speaking"
    BREATHING = "breathing"

class Difficulty(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    ALL = "all"

class SessionStatus(str, Enum):
    CREATED = "created"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"

class ExerciseTemplate(BaseModel):
    """Template d'exercice standardisé"""
    id: str
    title: str
    description: str
    type: ExerciseType
    duration: int = 600  # secondes
    difficulty: Difficulty
    focus_areas: List[str] = []
    settings: Dict[str, Any] = {}

class ExerciseSession(BaseModel):
    """Session d'exercice active"""
    session_id: str = Field(default_factory=lambda: f"session_{uuid.uuid4().hex[:10]}")
    template_id: str
    user_id: Optional[str] = None
    livekit_room: str
    livekit_token: str
    status: SessionStatus = SessionStatus.CREATED
    created_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    settings: Dict[str, Any] = {}
    metrics: Dict[str, Any] = {}

class ExerciseMetrics(BaseModel):
    """Métriques d'évaluation d'exercice"""
    session_id: str
    overall_score: float = Field(ge=0.0, le=100.0)
    clarity: float = Field(ge=0.0, le=100.0)
    fluency: float = Field(ge=0.0, le=100.0)
    confidence: float = Field(ge=0.0, le=100.0)
    engagement: float = Field(ge=0.0, le=100.0)
    detailed_metrics: Dict[str, float] = {}
    feedback: Optional[str] = None
    improvements: List[str] = []
    achievements: List[str] = []
    timestamp: datetime = Field(default_factory=datetime.now)

class RealTimeMessage(BaseModel):
    """Message WebSocket temps réel"""
    type: str  # audio_chunk, metrics_update, final_result, error
    session_id: str
    timestamp: datetime = Field(default_factory=datetime.now)
    data: Dict[str, Any] = {}

class AudioAnalysisResult(BaseModel):
    """Résultat d'analyse audio"""
    transcription: str
    confidence: float
    metrics: Dict[str, float]
    processing_time: float
    timestamp: datetime = Field(default_factory=datetime.now)

class SessionCreateRequest(BaseModel):
    """Requête de création de session"""
    template_id: str
    user_id: Optional[str] = "anonymous"
    settings: Dict[str, Any] = {}

class SessionUpdateRequest(BaseModel):
    """Requête de mise à jour de session"""
    status: Optional[SessionStatus] = None
    metrics: Optional[Dict[str, Any]] = None
    settings: Optional[Dict[str, Any]] = None

class AudioAnalysisRequest(BaseModel):
    """Requête d'analyse audio"""
    session_id: str
    audio_data: str  # Base64 encoded audio
    format: str = "wav"
    sample_rate: int = 16000

class UserAnalytics(BaseModel):
    """Statistiques utilisateur"""
    user_id: str
    total_sessions: int
    completed_sessions: int
    completion_rate: float
    exercise_types: Dict[str, int]
    recent_sessions: List[Dict[str, Any]]
    average_scores: Dict[str, float] = {}
    improvement_trends: Dict[str, List[float]] = {}

class GlobalAnalytics(BaseModel):
    """Statistiques globales"""
    total_sessions: int
    active_sessions: int
    total_users: int
    popular_exercises: Dict[str, int]
    average_completion_rate: float = 0.0
    timestamp: datetime = Field(default_factory=datetime.now)
