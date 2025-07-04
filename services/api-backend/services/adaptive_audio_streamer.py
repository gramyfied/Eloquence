import asyncio
import logging
import time
from typing import Optional, Dict, Any
from livekit import rtc
from .real_time_streaming_tts import RealTimeStreamingTTS
from .intelligent_adaptive_streaming import IntelligentAdaptiveStreaming, StreamingProfile

logger = logging.getLogger(__name__)

class AdaptiveAudioStreamer:
    """
    Service de streaming audio adaptatif utilisant l'intelligence adaptative
    pour atteindre 95%+ d'efficacité avec LiveKit
    """
    
    def __init__(self, livekit_room: rtc.Room):
        self.room = livekit_room
        self.tts_service = RealTimeStreamingTTS()
        self.adaptive_streaming = IntelligentAdaptiveStreaming(livekit_room)
        
        # Métriques de performance
        self.total_streaming_time = 0.0
        self.total_overhead_time = 0.0
        self.streaming_sessions = 0
        
        # Configuration
        self.target_sample_rate = 48000  # LiveKit optimal
        self.monitoring_task: Optional[asyncio.Task] = None
        
        logger.info("🚀 AdaptiveAudioStreamer initialisé avec streaming adaptatif intelligent")
        
    async def initialize(self) -> None:
        """Initialiser le service de streaming adaptatif"""
        try:
            # Forcer le chargement du modèle TTS
            if not hasattr(self.tts_service, 'synthesizer_model') or self.tts_service.synthesizer_model is None:
                logger.info("🔄 Chargement du modèle TTS...")
                self.tts_service._load_piper_model()
            
            # Démarrer le monitoring adaptatif
            self.monitoring_task = asyncio.create_task(self.adaptive_streaming.start_monitoring())
            
            logger.info("✅ Service de streaming adaptatif initialisé avec succès")
            
        except Exception as e:
            logger.error(f"❌ Erreur initialisation streaming adaptatif: {e}", exc_info=True)
            
    async def stream_text_to_audio_adaptive(self, text: str) -> Dict[str, Any]:
        """
        Stream du texte vers audio avec adaptation intelligente
        Retourne les métriques de performance
        """
        session_start = time.time()
        metrics = {
            'text_length': len(text),
            'chunks_sent': 0,
            'total_bytes': 0,
            'efficiency_percent': 0.0,
            'average_latency_ms': 0.0,
            'profile_used': '',
            'errors': 0
        }
        
        try:
            self.streaming_sessions += 1
            logger.info(f"🎯 Début streaming adaptatif pour: '{text[:50]}...'")
            
            # Collecter tous les chunks audio du TTS
            audio_chunks = []
            chunk_generation_start = time.time()
            
            async for chunk in self.tts_service.stream_generate_audio(text):
                if chunk:
                    audio_chunks.append(chunk)
                    
            chunk_generation_time = time.time() - chunk_generation_start
            
            if not audio_chunks:
                logger.warning("⚠️ Aucun chunk audio généré par TTS")
                return metrics
                
            # Combiner les chunks pour un traitement optimal
            combined_audio = b''.join(audio_chunks)
            metrics['total_bytes'] = len(combined_audio)
            
            # Streaming adaptatif intelligent
            streaming_start = time.time()
            await self.adaptive_streaming.intelligent_stream(combined_audio)
            streaming_time = time.time() - streaming_start
            
            # Calculer l'efficacité réelle
            total_time = time.time() - session_start
            useful_time = chunk_generation_time
            overhead_time = total_time - useful_time
            
            self.total_streaming_time += useful_time
            self.total_overhead_time += overhead_time
            
            efficiency = (useful_time / total_time) * 100 if total_time > 0 else 0
            
            # Récupérer les métriques du streaming adaptatif
            adaptive_metrics = self.adaptive_streaming.get_current_metrics()
            
            # Mettre à jour les métriques
            metrics.update({
                'chunks_sent': adaptive_metrics['chunks_sent'],
                'efficiency_percent': efficiency,
                'average_latency_ms': adaptive_metrics['latency_ms'],
                'profile_used': adaptive_metrics['profile'],
                'errors': adaptive_metrics['error_rate_percent'],
                'generation_time_ms': chunk_generation_time * 1000,
                'streaming_time_ms': streaming_time * 1000,
                'overhead_time_ms': overhead_time * 1000,
                'total_time_ms': total_time * 1000
            })
            
            # Log des performances
            logger.info(f"✅ Streaming terminé - Efficacité: {efficiency:.1f}%, "
                       f"Latence: {adaptive_metrics['latency_ms']:.1f}ms, "
                       f"Profil: {adaptive_metrics['profile']}")
            
            # Alerte si efficacité faible
            if efficiency < 50:
                logger.warning(f"⚠️ Efficacité faible détectée: {efficiency:.1f}%")
                # Forcer une adaptation
                await self.adaptive_streaming._adapt_realtime()
                
        except Exception as e:
            logger.error(f"❌ Erreur streaming adaptatif: {e}", exc_info=True)
            metrics['errors'] += 1
            
        return metrics
        
    async def optimize_for_scenario(self, scenario_type: str) -> None:
        """Optimiser le streaming pour un scénario spécifique"""
        profile_mapping = {
            'conversation': StreamingProfile.BALANCED_OPTIMAL,
            'presentation': StreamingProfile.HIGH_THROUGHPUT,
            'realtime': StreamingProfile.ULTRA_PERFORMANCE,
            'training': StreamingProfile.BALANCED_OPTIMAL
        }
        
        target_profile = profile_mapping.get(
            scenario_type.lower(), 
            StreamingProfile.BALANCED_OPTIMAL
        )
        
        logger.info(f"🎯 Optimisation pour scénario '{scenario_type}' avec profil {target_profile.value}")
        await self.adaptive_streaming._switch_profile(target_profile)
        
    def get_performance_report(self) -> Dict[str, Any]:
        """Obtenir un rapport de performance détaillé"""
        global_efficiency = 0.0
        if self.total_streaming_time + self.total_overhead_time > 0:
            global_efficiency = (self.total_streaming_time / 
                               (self.total_streaming_time + self.total_overhead_time)) * 100
                               
        current_metrics = self.adaptive_streaming.get_current_metrics()
        
        return {
            'sessions_count': self.streaming_sessions,
            'global_efficiency_percent': global_efficiency,
            'total_streaming_time_s': self.total_streaming_time,
            'total_overhead_time_s': self.total_overhead_time,
            'current_profile': current_metrics['profile'],
            'current_efficiency': current_metrics['efficiency_percent'],
            'current_latency_ms': current_metrics['latency_ms'],
            'total_data_sent_mb': current_metrics['bytes_sent'] / 1024 / 1024,
            'improvement_factor': global_efficiency / 5.3 if global_efficiency > 0 else 0  # vs 5.3% initial
        }
        
    async def stop(self) -> None:
        """Arrêter le service de streaming adaptatif"""
        logger.info("🛑 Arrêt du service de streaming adaptatif")
        
        # Arrêter le monitoring
        if self.monitoring_task and not self.monitoring_task.done():
            self.monitoring_task.cancel()
            try:
                await self.monitoring_task
            except asyncio.CancelledError:
                pass
                
        # Arrêter le streaming adaptatif
        await self.adaptive_streaming.stop_streaming()
        
        # Log du rapport final
        report = self.get_performance_report()
        logger.info(f"📊 RAPPORT FINAL - Efficacité globale: {report['global_efficiency_percent']:.1f}%, "
                   f"Amélioration: {report['improvement_factor']:.1f}x")