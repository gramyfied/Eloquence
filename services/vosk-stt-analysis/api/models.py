from pydantic import BaseModel
from typing import Dict, Any, List, Optional

class AnalysisRequest(BaseModel):
    exercise_type: str
    exercise_config: Optional[str] = None
    language: str = "fr"

class AnalysisResponse(BaseModel):
    exercise_type: str
    transcription: str
    recognition_details: Dict[str, Any]
    analysis: Dict[str, Any]
    processing_time_ms: float
    
class HealthResponse(BaseModel):
    status: str
    service: str
    vosk_models_loaded: List[str]
    available_analyzers: List[str]
    version: str