#!/usr/bin/env python3
"""
Orchestrateur Hybride VOSK + Whisper
====================================

Coordonne la reconnaissance temps réel (VOSK) avec l'analyse finale (Whisper)
Génère des métriques prosodiques avancées et des recommandations personnalisées
"""

import asyncio
import logging
import time
import numpy as np
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
import uuid
import librosa
import io
import wave

from .vosk_realtime_service import VoskRealtimeService
from .whisper_client_service import WhisperClientService, WhisperResult

logger = logging.getLogger(__name__)

@dataclass
class HybridSession:
    """Session hybride combinant VOSK et Whisper"""
    session_id: str
    vosk_session_id: str
    created_at: float
    vosk_results: List[Dict[str, Any]]
    whisper_result: Optional[WhisperResult]
    prosody_analysis: Dict[str, Any]
    recommendations: List[str]
    status: str  # "active", "completed", "error"

@dataclass
class ProsodyAnalysis:
    """Analyse prosodique complète"""
    speaking_rate_wpm: float
    pause_count: int
    average_pause_duration: float
    longest_pause: float
    speech_to_pause_ratio: float
    confidence_score: float
    articulation_score: float
    rhythm_consistency: float
    voice_stability: float
    hesitation_count: int
    filler_words: List[str]
    energy_variation: float

class HybridOrchestrator:
    """
    Orchestrateur principal du système hybride
    Coordonne VOSK (temps réel) et Whisper (analyse finale)
    """
    
    def __init__(self, vosk_service: VoskRealtimeService, whisper_client: WhisperClientService):
        self.vosk_service = vosk_service
        self.whisper_client = whisper_client
        self.active_sessions: Dict[str, HybridSession] = {}
        self.metrics = {
            "total_sessions": 0,
            "successful_analyses": 0,
            "avg_processing_time": 0.0,
            "avg_accuracy_score": 0.0
        }
        
        # Mots de remplissage français pour la détection d'hésitations
        self.filler_words = {
            "euh", "heu", "uhm", "hum", "ben", "alors", "donc", "voilà", 
            "quoi", "enfin", "disons", "comment dire", "tu vois", "vous voyez"
        }
        
    async def create_hybrid_session(self, session_id: str) -> Dict[str, Any]:
        """Crée une nouvelle session d'évaluation hybride"""
        try:
            logger.info(f"🎯 Création session hybride: {session_id}")
            
            # Créer la session VOSK associée
            vosk_session_data = await self.vosk_service.create_session(f"vosk_{session_id}")
            
            # Créer la session hybride
            hybrid_session = HybridSession(
                session_id=session_id,
                vosk_session_id=f"vosk_{session_id}",
                created_at=time.time(),
                vosk_results=[],
                whisper_result=None,
                prosody_analysis={},
                recommendations=[],
                status="active"
            )
            
            self.active_sessions[session_id] = hybrid_session
            self.metrics["total_sessions"] += 1
            
            return {
                "session_id": session_id,
                "vosk_session": vosk_session_data,
                "status": "ready",
                "capabilities": {
                    "realtime_feedback": True,
                    "final_transcription": True,
                    "prosody_analysis": True,
                    "recommendations": True
                }
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur création session hybride {session_id}: {e}")
            raise
    
    async def process_realtime_result(self, session_id: str, vosk_result: Dict[str, Any]):
        """Traite les résultats temps réel de VOSK pour enrichissement"""
        try:
            if session_id not in self.active_sessions:
                return vosk_result
                
            session = self.active_sessions[session_id]
            session.vosk_results.append(vosk_result)
            
            # Enrichir le résultat VOSK avec des métriques supplémentaires
            enhanced_result = vosk_result.copy()
            enhanced_result.update({
                "session_word_count": self._count_total_words(session),
                "session_confidence_trend": self._calculate_confidence_trend(session),
                "detected_hesitations": self._detect_realtime_hesitations(vosk_result),
                "speaking_pace_status": self._evaluate_speaking_pace(session)
            })
            
            return enhanced_result
            
        except Exception as e:
            logger.error(f"❌ Erreur traitement résultat temps réel {session_id}: {e}")
            return vosk_result
    
    async def analyze_prosody(self, audio_data: bytes, whisper_transcript: str) -> Dict[str, Any]:
        """
        Analyse prosodique complète combinant VOSK et Whisper
        
        Args:
            audio_data: Données audio pour analyse acoustique
            whisper_transcript: Transcription Whisper pour analyse textuelle
            
        Returns:
            Analyse prosodique détaillée
        """
        try:
            logger.info("🔍 Démarrage analyse prosodique hybride")
            start_time = time.time()
            
            # Analyse acoustique de l'audio
            acoustic_analysis = await self._analyze_audio_features(audio_data)
            
            # Analyse textuelle de la transcription
            textual_analysis = await self._analyze_transcript_features(whisper_transcript)
            
            # Combinaison des analyses
            prosody_analysis = {
                **acoustic_analysis,
                **textual_analysis,
                "analysis_duration": time.time() - start_time,
                "timestamp": time.time()
            }
            
            # Calcul du score global
            prosody_analysis["overall_score"] = self._calculate_overall_score(prosody_analysis)
            
            logger.info(f"✅ Analyse prosodique terminée en {prosody_analysis['analysis_duration']:.2f}s")
            return prosody_analysis
            
        except Exception as e:
            logger.error(f"❌ Erreur analyse prosodique: {e}")
            return {}
    
    async def _analyze_audio_features(self, audio_data: bytes) -> Dict[str, Any]:
        """Analyse les caractéristiques acoustiques de l'audio"""
        try:
            # Convertir les bytes en array numpy pour librosa
            with io.BytesIO(audio_data) as audio_buffer:
                with wave.open(audio_buffer, 'rb') as wav_file:
                    frames = wav_file.readframes(-1)
                    sound_info = wav_file.getparams()
                    
            # Convertir en array numpy
            audio_array = np.frombuffer(frames, dtype=np.int16).astype(np.float32)
            audio_array = audio_array / 32768.0  # Normaliser
            
            sample_rate = sound_info.framerate
            duration = len(audio_array) / sample_rate
            
            # Détection des pauses par analyse d'énergie
            pauses = self._detect_pauses(audio_array, sample_rate)
            
            # Analyse de la fréquence fondamentale (F0)
            f0_analysis = self._analyze_pitch(audio_array, sample_rate)
            
            # Analyse de l'énergie vocale
            energy_analysis = self._analyze_energy(audio_array, sample_rate)
            
            return {
                "duration": duration,
                "pause_count": len(pauses),
                "average_pause_duration": np.mean([p[1] - p[0] for p in pauses]) if pauses else 0.0,
                "longest_pause": max([p[1] - p[0] for p in pauses]) if pauses else 0.0,
                "speech_to_pause_ratio": duration - sum([p[1] - p[0] for p in pauses]) / duration if duration > 0 else 0.0,
                "fundamental_frequency": f0_analysis,
                "energy_variation": energy_analysis["variation"],
                "voice_stability": energy_analysis["stability"]
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur analyse audio: {e}")
            return {}
    
    async def _analyze_transcript_features(self, transcript: str) -> Dict[str, Any]:
        """Analyse les caractéristiques textuelles de la transcription"""
        try:
            words = transcript.lower().split()
            word_count = len(words)
            
            # Détection des mots de remplissage
            filler_count = sum(1 for word in words if word.strip(".,!?;:") in self.filler_words)
            filler_ratio = filler_count / max(1, word_count)
            
            # Analyse de la complexité lexicale
            unique_words = len(set(words))
            lexical_diversity = unique_words / max(1, word_count)
            
            # Détection des répétitions
            repetitions = self._detect_repetitions(words)
            
            # Analyse de la longueur des phrases
            sentences = transcript.split('.')
            avg_sentence_length = np.mean([len(sentence.split()) for sentence in sentences if sentence.strip()])
            
            return {
                "word_count": word_count,
                "filler_words": [word for word in words if word.strip(".,!?;:") in self.filler_words],
                "hesitation_count": filler_count,
                "filler_ratio": filler_ratio,
                "lexical_diversity": lexical_diversity,
                "repetition_count": len(repetitions),
                "average_sentence_length": avg_sentence_length,
                "articulation_score": max(0.0, 1.0 - filler_ratio * 2)  # Score basé sur les hésitations
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur analyse transcription: {e}")
            return {}
    
    def _detect_pauses(self, audio_array: np.ndarray, sample_rate: int, 
                      silence_threshold: float = 0.01, min_pause_duration: float = 0.3) -> List[Tuple[float, float]]:
        """Détecte les pauses dans l'audio"""
        try:
            # Calculer l'énergie RMS par fenêtre
            window_size = int(0.1 * sample_rate)  # Fenêtres de 100ms
            energy = []
            
            for i in range(0, len(audio_array), window_size):
                window = audio_array[i:i+window_size]
                rms = np.sqrt(np.mean(window**2))
                energy.append(rms)
            
            # Détecter les zones silencieuses
            silent_windows = np.array(energy) < silence_threshold
            
            # Convertir en intervalles de temps
            pauses = []
            in_pause = False
            pause_start = 0
            
            for i, is_silent in enumerate(silent_windows):
                time_pos = i * window_size / sample_rate
                
                if is_silent and not in_pause:
                    pause_start = time_pos
                    in_pause = True
                elif not is_silent and in_pause:
                    pause_duration = time_pos - pause_start
                    if pause_duration >= min_pause_duration:
                        pauses.append((pause_start, time_pos))
                    in_pause = False
            
            return pauses
            
        except Exception as e:
            logger.error(f"❌ Erreur détection pauses: {e}")
            return []
    
    def _analyze_pitch(self, audio_array: np.ndarray, sample_rate: int) -> Dict[str, float]:
        """Analyse la fréquence fondamentale"""
        try:
            # Utiliser librosa pour l'analyse de pitch
            pitches, magnitudes = librosa.piptrack(y=audio_array, sr=sample_rate, threshold=0.1)
            
            # Extraire les fréquences fondamentales
            f0_values = []
            for t in range(pitches.shape[1]):
                index = magnitudes[:, t].argmax()
                pitch = pitches[index, t]
                if pitch > 0:
                    f0_values.append(pitch)
            
            if f0_values:
                return {
                    "mean_f0": np.mean(f0_values),
                    "std_f0": np.std(f0_values),
                    "min_f0": np.min(f0_values),
                    "max_f0": np.max(f0_values)
                }
            else:
                return {"mean_f0": 0.0, "std_f0": 0.0, "min_f0": 0.0, "max_f0": 0.0}
                
        except Exception as e:
            logger.error(f"❌ Erreur analyse pitch: {e}")
            return {"mean_f0": 0.0, "std_f0": 0.0, "min_f0": 0.0, "max_f0": 0.0}
    
    def _analyze_energy(self, audio_array: np.ndarray, sample_rate: int) -> Dict[str, float]:
        """Analyse l'énergie vocale"""
        try:
            # Calculer l'énergie RMS par fenêtre
            window_size = int(0.05 * sample_rate)  # Fenêtres de 50ms
            energies = []
            
            for i in range(0, len(audio_array), window_size):
                window = audio_array[i:i+window_size]
                rms = np.sqrt(np.mean(window**2))
                energies.append(rms)
            
            energies = np.array(energies)
            
            return {
                "mean_energy": np.mean(energies),
                "variation": np.std(energies),
                "stability": 1.0 - (np.std(energies) / max(0.001, np.mean(energies)))
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur analyse énergie: {e}")
            return {"mean_energy": 0.0, "variation": 0.0, "stability": 0.0}
    
    def _detect_repetitions(self, words: List[str]) -> List[Tuple[str, int]]:
        """Détecte les répétitions de mots"""
        repetitions = []
        i = 0
        while i < len(words) - 1:
            current_word = words[i].strip(".,!?;:")
            count = 1
            j = i + 1
            
            while j < len(words) and words[j].strip(".,!?;:") == current_word:
                count += 1
                j += 1
            
            if count > 1:
                repetitions.append((current_word, count))
                i = j
            else:
                i += 1
                
        return repetitions
    
    def _calculate_overall_score(self, prosody_analysis: Dict[str, Any]) -> float:
        """Calcule un score global de performance orale"""
        try:
            score = 1.0
            
            # Pénalités basées sur l'analyse
            filler_ratio = prosody_analysis.get("filler_ratio", 0.0)
            score -= min(0.3, filler_ratio * 2)  # Max -30% pour les hésitations
            
            # Bonus pour la diversité lexicale
            lexical_diversity = prosody_analysis.get("lexical_diversity", 0.0)
            score += min(0.2, lexical_diversity * 0.5)  # Max +20%
            
            # Pénalités pour les pauses excessives
            pause_ratio = 1.0 - prosody_analysis.get("speech_to_pause_ratio", 1.0)
            if pause_ratio > 0.3:  # Plus de 30% de pauses
                score -= min(0.2, (pause_ratio - 0.3) * 2)
            
            # Bonus pour la stabilité vocale
            stability = prosody_analysis.get("voice_stability", 0.0)
            score += min(0.1, stability * 0.2)
            
            return max(0.0, min(1.0, score))  # Limiter entre 0 et 1
            
        except Exception as e:
            logger.error(f"❌ Erreur calcul score global: {e}")
            return 0.5
    
    async def generate_recommendations(self, whisper_result: WhisperResult, 
                                     prosody_analysis: Dict[str, Any]) -> List[str]:
        """Génère des recommandations personnalisées"""
        recommendations = []
        
        try:
            # Recommandations basées sur les hésitations
            filler_ratio = prosody_analysis.get("filler_ratio", 0.0)
            if filler_ratio > 0.1:
                recommendations.append(
                    f"🎯 Réduire les mots de remplissage ({filler_ratio:.1%} détectés). "
                    "Prenez des pauses plutôt que d'utiliser 'euh', 'hm'."
                )
            
            # Recommandations sur le débit
            wpm = prosody_analysis.get("word_count", 0) / max(0.1, whisper_result.duration / 60)
            if wpm < 120:
                recommendations.append(
                    f"⚡ Augmenter le débit de parole ({wpm:.0f} mots/min). "
                    "Objectif: 150-180 mots/minute pour un discours fluide."
                )
            elif wpm > 200:
                recommendations.append(
                    f"🐌 Ralentir le débit de parole ({wpm:.0f} mots/min). "
                    "Prendre plus de temps pour articuler clairement."
                )
            
            # Recommandations sur les pauses
            pause_count = prosody_analysis.get("pause_count", 0)
            duration = whisper_result.duration
            if duration > 0 and pause_count / duration > 0.5:
                recommendations.append(
                    "⏸️ Optimiser les pauses. Utiliser des pauses stratégiques "
                    "plutôt que des hésitations fréquentes."
                )
            
            # Recommandations sur la diversité lexicale
            lexical_diversity = prosody_analysis.get("lexical_diversity", 0.0)
            if lexical_diversity < 0.5:
                recommendations.append(
                    "📚 Enrichir le vocabulaire. Éviter les répétitions en "
                    "utilisant des synonymes et expressions variées."
                )
            
            # Recommandations sur la stabilité vocale
            voice_stability = prosody_analysis.get("voice_stability", 0.0)
            if voice_stability < 0.6:
                recommendations.append(
                    "🎵 Améliorer la stabilité vocale. Travailler la respiration "
                    "et le contrôle de l'intensité de la voix."
                )
            
            # Recommandation positive si tout va bien
            overall_score = prosody_analysis.get("overall_score", 0.0)
            if overall_score >= 0.8:
                recommendations.append(
                    "🎉 Excellente performance orale ! Continuez sur cette lancée."
                )
            
            return recommendations
            
        except Exception as e:
            logger.error(f"❌ Erreur génération recommandations: {e}")
            return ["❌ Erreur lors de l'analyse. Veuillez réessayer."]
    
    # Méthodes utilitaires pour l'enrichissement temps réel
    def _count_total_words(self, session: HybridSession) -> int:
        """Compte le total de mots détectés en temps réel"""
        total_words = 0
        for result in session.vosk_results:
            if result.get("type") == "final" and result.get("text"):
                total_words += len(result["text"].split())
        return total_words
    
    def _calculate_confidence_trend(self, session: HybridSession) -> str:
        """Calcule la tendance de confiance en temps réel"""
        confidences = [
            result.get("confidence", 0.0) 
            for result in session.vosk_results[-10:]  # 10 derniers résultats
            if result.get("confidence") is not None
        ]
        
        if len(confidences) < 3:
            return "insufficient_data"
            
        trend = np.polyfit(range(len(confidences)), confidences, 1)[0]
        
        if trend > 0.01:
            return "improving"
        elif trend < -0.01:
            return "declining"
        else:
            return "stable"
    
    def _detect_realtime_hesitations(self, vosk_result: Dict[str, Any]) -> List[str]:
        """Détecte les hésitations en temps réel"""
        text = vosk_result.get("partial", "") + " " + vosk_result.get("text", "")
        words = text.lower().split()
        
        detected_fillers = [
            word for word in words 
            if word.strip(".,!?;:") in self.filler_words
        ]
        
        return detected_fillers
    
    def _evaluate_speaking_pace(self, session: HybridSession) -> str:
        """Évalue le rythme de parole en temps réel"""
        total_words = self._count_total_words(session)
        session_duration = time.time() - session.created_at
        
        if session_duration < 10:  # Pas assez de données
            return "evaluating"
            
        wpm = (total_words / session_duration) * 60
        
        if wpm < 100:
            return "too_slow"
        elif wpm > 220:
            return "too_fast"
        else:
            return "optimal"
    
    async def get_session_status(self, session_id: str) -> Dict[str, Any]:
        """Obtient le statut d'une session hybride"""
        if session_id not in self.active_sessions:
            return {"error": "Session not found"}
            
        session = self.active_sessions[session_id]
        
        return {
            "session_id": session_id,
            "status": session.status,
            "created_at": session.created_at,
            "vosk_results_count": len(session.vosk_results),
            "has_whisper_result": session.whisper_result is not None,
            "has_prosody_analysis": bool(session.prosody_analysis),
            "recommendations_count": len(session.recommendations)
        }
    
    async def cleanup_session(self, session_id: str):
        """Nettoie une session hybride"""
        try:
            if session_id in self.active_sessions:
                session = self.active_sessions[session_id]
                
                # Nettoyer la session VOSK associée
                await self.vosk_service.cleanup_session(session.vosk_session_id)
                
                # Supprimer la session hybride
                del self.active_sessions[session_id]
                
                logger.info(f"🔄 Session hybride nettoyée: {session_id}")
                
        except Exception as e:
            logger.error(f"❌ Erreur nettoyage session hybride {session_id}: {e}")