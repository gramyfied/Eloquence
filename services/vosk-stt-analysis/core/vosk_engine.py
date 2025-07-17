import vosk
import json
import asyncio
from typing import Dict, Any, List
import numpy as np
from concurrent.futures import ThreadPoolExecutor
import logging
import time

class VoskEngine:
    """Moteur Vosk ultra-optimisé pour infrastructure Scaleway"""
    
    def __init__(self):
        self.models: Dict[str, vosk.Model] = {}
        self.recognizers: Dict[str, vosk.KaldiRecognizer] = {}
        self.executor = ThreadPoolExecutor(max_workers=8)  # Scaleway power
        self.logger = logging.getLogger(__name__)
        
        # Configuration performance maximale
        vosk.SetLogLevel(-1)  # Désactiver logs verbeux
        
    async def initialize_all_models(self):
        """Initialise tous les modèles en parallèle pour performance"""
        model_configs = {
            "fr_large": {
                "path": "/app/models/vosk-model-fr-large-0.22",
                "sample_rate": 16000
            },
            "fr_small": {
                "path": "/app/models/vosk-model-fr-small-0.22",
                "sample_rate": 16000
            },
            "en_large": {
                "path": "/app/models/vosk-model-en-large-0.22", 
                "sample_rate": 16000
            },
            "speaker_id": {
                "path": "/app/models/vosk-model-spk-0.4",
                "sample_rate": 16000
            }
        }
        
        # Chargement parallèle pour performance maximale
        tasks = []
        for model_name, config in model_configs.items():
            task = asyncio.create_task(
                self._load_model_async(model_name, config)
            )
            tasks.append(task)
            
        await asyncio.gather(*tasks)
        self.logger.info(f"✅ {len(self.models)} modèles Vosk chargés")
        
    async def _load_model_async(self, model_name: str, config: Dict):
        """Charge un modèle de manière asynchrone"""
        loop = asyncio.get_event_loop()
        
        try:
            # Chargement en thread séparé pour ne pas bloquer
            model = await loop.run_in_executor(
                self.executor,
                vosk.Model,
                config["path"]
            )
            
            # Recognizer optimisé avec toutes les options
            recognizer = vosk.KaldiRecognizer(
                model, 
                config["sample_rate"]
            )
            recognizer.SetMaxAlternatives(3)  # Alternatives pour confiance
            recognizer.SetWords(True)        # Timestamps mots
            recognizer.SetPartialWords(True) # Pour temps réel
            
            self.models[model_name] = model
            self.recognizers[model_name] = recognizer
            
            self.logger.info(f"✅ Modèle {model_name} chargé")
            
        except Exception as e:
            self.logger.error(f"❌ Erreur chargement {model_name}: {e}")
            
    async def recognize_audio(
        self, 
        audio_data: bytes, 
        language: str = "fr",
        model_size: str = "large"
    ) -> Dict[str, Any]:
        """Reconnaissance audio ultra-optimisée avec métriques complètes"""
        
        start_time = time.time()
        
        model_key = f"{language}_{model_size}"
        if model_key not in self.recognizers:
            # Fallback vers modèle disponible
            available_models = list(self.recognizers.keys())
            model_key = available_models[0] if available_models else None
            
        if not model_key:
            raise ValueError("Aucun modèle Vosk disponible")
            
        recognizer = self.recognizers[model_key]
        
        # Traitement en thread pour performance
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            self.executor,
            self._process_audio_sync,
            recognizer,
            audio_data
        )
        
        # Ajouter métriques de performance
        result['processing_time'] = (time.time() - start_time) * 1000
        result['model_used'] = model_key
        
        return result
        
    def _process_audio_sync(self, recognizer, audio_data: bytes) -> Dict[str, Any]:
        """Traitement synchrone optimisé avec métriques complètes"""
        
        # Conversion audio optimisée
        audio_np = np.frombuffer(audio_data, dtype=np.int16)
        
        # Reconnaissance par chunks pour performance
        chunk_size = 4000
        results = []
        
        for i in range(0, len(audio_np), chunk_size):
            chunk = audio_np[i:i + chunk_size].tobytes()
            
            if recognizer.AcceptWaveform(chunk):
                result = json.loads(recognizer.Result())
                if result.get('text'):
                    results.append(result)
                    
        # Résultat final
        final_result = json.loads(recognizer.FinalResult())
        if final_result.get('text'):
            results.append(final_result)
            
        # Agrégation optimisée avec métriques
        return self._aggregate_results_with_metrics(results)
        
    def _aggregate_results_with_metrics(self, results: List[Dict]) -> Dict[str, Any]:
        """Agrège les résultats avec métriques complètes pour analyse"""
        
        if not results:
            return {
                'text': '',
                'words': [],
                'confidence': 0.0,
                'alternatives': [],
                'speech_metrics': self._empty_metrics()
            }
        
        # Agrégation texte
        full_text = " ".join([r.get('text', '') for r in results]).strip()
        
        # Agrégation mots avec timestamps
        all_words = []
        total_confidence = 0
        
        for result in results:
            if 'result' in result:
                words = result['result']
                all_words.extend(words)
                total_confidence += sum([w.get('conf', 0) for w in words])
                
        avg_confidence = total_confidence / len(all_words) if all_words else 0
        
        # Calcul métriques vocales avancées
        speech_metrics = self._calculate_speech_metrics(all_words)
        
        return {
            'text': full_text,
            'words': all_words,
            'confidence': avg_confidence,
            'alternatives': results[-1].get('alternatives', []) if results else [],
            'speech_metrics': speech_metrics,
            'processing_info': {
                'chunks_processed': len(results),
                'total_words': len(all_words),
                'avg_confidence': avg_confidence,
                'speech_duration': speech_metrics.get('duration', 0)
            }
        }
        
    def _calculate_speech_metrics(self, words: List[Dict]) -> Dict[str, float]:
        """Calcule métriques vocales avancées pour analyse"""
        
        if not words:
            return self._empty_metrics()
            
        # Durée totale
        duration = words[-1].get('end', 0) - words[0].get('start', 0)
        
        # Débit de parole (mots/minute)
        speech_rate = (len(words) / max(duration, 0.1)) * 60
        
        # Analyse des pauses
        pauses = []
        for i in range(1, len(words)):
            gap = words[i].get('start', 0) - words[i-1].get('end', 0)
            if gap > 0.1:  # Pause > 100ms
                pauses.append(gap)
                
        avg_pause_duration = sum(pauses) / len(pauses) if pauses else 0
        pause_frequency = len(pauses) / len(words) if words else 0
        
        # Distribution de confiance
        confidences = [w.get('conf', 0) for w in words]
        confidence_variance = np.var(confidences) if confidences else 0
        
        # Fluidité (basée sur pauses et confiance)
        fluency_score = max(0, 1 - (pause_frequency * 2) - (confidence_variance * 0.5))
        
        return {
            'duration': duration,
            'speech_rate': speech_rate,
            'avg_pause_duration': avg_pause_duration,
            'pause_frequency': pause_frequency,
            'confidence_variance': confidence_variance,
            'fluency_score': fluency_score,
            'word_count': len(words)
        }
        
    def _empty_metrics(self) -> Dict[str, float]:
        """Métriques vides par défaut"""
        return {
            'duration': 0.0,
            'speech_rate': 0.0,
            'avg_pause_duration': 0.0,
            'pause_frequency': 0.0,
            'confidence_variance': 0.0,
            'fluency_score': 0.0,
            'word_count': 0
        }
        
    def get_loaded_models(self) -> List[str]:
        """Retourne la liste des modèles chargés"""
        return list(self.models.keys())