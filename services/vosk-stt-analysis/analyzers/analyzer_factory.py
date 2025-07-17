from typing import Dict, Type
from .base_analyzer import BaseAnalyzer
from .confidence_analyzer import ConfidenceAnalyzer

class AnalyzerFactory:
    """Factory pour créer les analyseurs selon le type d'exercice"""
    
    def __init__(self):
        self._analyzers: Dict[str, Type[BaseAnalyzer]] = {
            'confidence': ConfidenceAnalyzer,
            # Futurs analyseurs extensibles
            # 'pronunciation': PronunciationAnalyzer,
            # 'fluency': FluencyAnalyzer,
            # 'debate': DebateAnalyzer,
        }
        
    def get_analyzer(self, exercise_type: str) -> BaseAnalyzer:
        """Retourne l'analyseur approprié pour le type d'exercice"""
        
        if exercise_type not in self._analyzers:
            raise ValueError(f"Type d'exercice non supporté: {exercise_type}")
            
        analyzer_class = self._analyzers[exercise_type]
        return analyzer_class()
        
    def get_available_analyzers(self) -> list:
        """Retourne la liste des analyseurs disponibles"""
        return list(self._analyzers.keys())
        
    def register_analyzer(self, exercise_type: str, analyzer_class: Type[BaseAnalyzer]):
        """Enregistre un nouvel analyseur (pour extensibilité)"""
        self._analyzers[exercise_type] = analyzer_class