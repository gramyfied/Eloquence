import asyncio
import json
import logging
import os
import time
import numpy as np
from dataclasses import dataclass
from typing import Any, AsyncIterator, Callable, Dict, List, Optional

from livekit import rtc
from livekit import agents
from livekit.agents import JobContext, llm, stt, tts, Agent, AgentSession
from datetime import datetime
import aiohttp
import tempfile
import wave
import base64
from scipy.signal import resample
import uuid

# Configuration du logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

@dataclass
class AudioDiagnosticData:
    """Données de diagnostic audio"""
    timestamp: float
    frame_count: int
    sample_rate: int
    num_channels: int
    data_length: int
    energy: float
    max_amplitude: float
    min_amplitude: float
    rms: float
    zero_crossing_rate: float
    is_silent: bool
    raw_data_sample: List[float]  # Premiers 10 échantillons pour debug

class AudioDiagnosticAgent:
    """Agent de diagnostic audio avancé pour identifier les problèmes d'audio silencieux"""
    
    def __init__(self):
        self.diagnostic_data: List[AudioDiagnosticData] = []
        self.frame_counter = 0
        self.total_frames_received = 0
        self.silent_frames_count = 0
        self.non_silent_frames_count = 0
        self.start_time = time.time()
        
    async def entrypoint(self, ctx: JobContext):
        """Point d'entrée agent avec diagnostic audio complet"""
        
        logger.info("🔍 [DIAGNOSTIC] === DÉMARRAGE AGENT DIAGNOSTIC AUDIO ===")
        
        try:
            # ÉTAPE 1 : Configuration audio source avec diagnostic
            logger.info("🔧 [DIAGNOSTIC] Configuration AudioSource avec monitoring...")
            audio_source = rtc.AudioSource(sample_rate=24000, num_channels=1)
            logger.info("✅ [DIAGNOSTIC] AudioSource configurée : 24kHz, mono")
            
            # ÉTAPE 2 : Créer track audio avec diagnostic
            track_name = f"diagnostic-agent-{uuid.uuid4().hex[:8]}"
            audio_track = rtc.LocalAudioTrack.create_audio_track(track_name, audio_source)
            logger.info(f"✅ [DIAGNOSTIC] LocalAudioTrack créée : {track_name}")
            
            # ÉTAPE 3 : Publier track avec options de diagnostic
            publication = await ctx.room.local_participant.publish_track(
                audio_track,
                rtc.TrackPublishOptions(
                    name="diagnostic-agent-audio",
                    source=rtc.TrackSource.SOURCE_MICROPHONE,
                    stereo=False,
                    dtx=False,  # Désactiver DTX pour diagnostic
                    red=True,
                    simulcast=False
                )
            )
            logger.info(f"✅ [DIAGNOSTIC] Track publiée - SID: {publication.sid}")
            
            # ÉTAPE 4 : Configurer callbacks de diagnostic
            await self.setup_diagnostic_callbacks(ctx, audio_source)
            
            # ÉTAPE 5 : Démarrer monitoring continu
            await self.start_continuous_monitoring(ctx, audio_source)
            
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC] Erreur critique agent: {e}")
            raise
    
    async def setup_diagnostic_callbacks(self, ctx: JobContext, audio_source: rtc.AudioSource):
        """Configure les callbacks de diagnostic audio"""
        
        logger.info("🔧 [DIAGNOSTIC] Configuration callbacks de diagnostic...")
        
        @ctx.room.on("track_subscribed")
        def on_track_subscribed(track, publication, participant):
            if track.kind == rtc.TrackKind.KIND_AUDIO:
                logger.info(f"🎤 [DIAGNOSTIC] Track audio souscrite: {track.sid}")
                logger.info(f"🎤 [DIAGNOSTIC] Participant: {participant.identity}")
                logger.info(f"🎤 [DIAGNOSTIC] Publication: {publication.sid}")
                
                # Démarrer le diagnostic de cette track
                asyncio.create_task(self.diagnose_audio_track(track, audio_source))
        
        @ctx.room.on("participant_connected")
        def on_participant_connected(participant):
            logger.info(f"👤 [DIAGNOSTIC] Participant connecté: {participant.identity}")
        
        @ctx.room.on("participant_disconnected")
        def on_participant_disconnected(participant):
            logger.info(f"👤 [DIAGNOSTIC] Participant déconnecté: {participant.identity}")
        
        logger.info("✅ [DIAGNOSTIC] Callbacks configurés")
    
    async def diagnose_audio_track(self, user_track, agent_audio_source):
        """Diagnostic complet d'une track audio utilisateur"""
        
        logger.info("🔍 [DIAGNOSTIC] === DÉMARRAGE DIAGNOSTIC TRACK AUDIO ===")
        
        try:
            # Créer un stream audio pour analyser les frames
            audio_stream = rtc.AudioStream(user_track)
            
            # Buffer pour accumuler les frames
            audio_buffer = []
            frame_count = 0
            
            async for audio_frame_event in audio_stream:
                frame_count += 1
                self.total_frames_received += 1
                
                # Extraire les données audio
                frame = audio_frame_event.frame
                
                # Diagnostic détaillé de la frame
                diagnostic = await self.analyze_audio_frame(frame, frame_count)
                self.diagnostic_data.append(diagnostic)
                
                # Log diagnostic toutes les 10 frames
                if frame_count % 10 == 0:
                    await self.log_diagnostic_summary(frame_count)
                
                # Accumuler dans le buffer
                audio_buffer.append(frame)
                
                # Traiter le buffer toutes les 100 frames (environ 1 seconde à 24kHz)
                if len(audio_buffer) >= 100:
                    await self.process_audio_buffer(audio_buffer, agent_audio_source)
                    audio_buffer = []
                
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC] Erreur diagnostic track: {e}")
    
    async def analyze_audio_frame(self, frame: rtc.AudioFrame, frame_number: int) -> AudioDiagnosticData:
        """Analyse détaillée d'une frame audio"""
        
        try:
            # Extraire les données brutes
            data = np.frombuffer(frame.data, dtype=np.int16)
            
            # Convertir en float pour les calculs
            data_float = data.astype(np.float32) / 32768.0
            
            # Calculs de diagnostic
            energy = float(np.sqrt(np.mean(data_float**2)))
            max_amp = float(np.max(np.abs(data_float))) if len(data_float) > 0 else 0.0
            min_amp = float(np.min(data_float)) if len(data_float) > 0 else 0.0
            rms = float(np.sqrt(np.mean(data_float**2))) if len(data_float) > 0 else 0.0
            
            # Zero crossing rate
            zero_crossings = np.sum(np.diff(np.sign(data_float)) != 0) if len(data_float) > 1 else 0
            zcr = zero_crossings / len(data_float) if len(data_float) > 0 else 0.0
            
            # Détection de silence
            is_silent = energy < 0.001  # Seuil très bas pour diagnostic
            
            # Échantillon des premières données pour debug
            raw_sample = data_float[:10].tolist() if len(data_float) >= 10 else data_float.tolist()
            
            # Compter les frames silencieuses
            if is_silent:
                self.silent_frames_count += 1
            else:
                self.non_silent_frames_count += 1
            
            diagnostic = AudioDiagnosticData(
                timestamp=time.time(),
                frame_count=frame_number,
                sample_rate=frame.sample_rate,
                num_channels=frame.num_channels,
                data_length=len(data),
                energy=energy,
                max_amplitude=max_amp,
                min_amplitude=min_amp,
                rms=rms,
                zero_crossing_rate=zcr,
                is_silent=is_silent,
                raw_data_sample=raw_sample
            )
            
            # Log détaillé pour les premières frames et frames non-silencieuses
            if frame_number <= 5 or not is_silent or frame_number % 100 == 0:
                logger.info(f"🔍 [FRAME {frame_number}] Énergie: {energy:.6f}, Max: {max_amp:.6f}, RMS: {rms:.6f}, ZCR: {zcr:.3f}")
                logger.info(f"🔍 [FRAME {frame_number}] Silencieux: {is_silent}, Données: {raw_sample[:5]}")
            
            return diagnostic
            
        except Exception as e:
            logger.error(f"❌ [DIAGNOSTIC] Erreur analyse frame {frame_number}: {e}")
            return AudioDiagnosticData(
                timestamp=time.time(),
                frame_count=frame_number,
                sample_rate=0,
                num_channels=0,
                data_length=0,
                energy=0.0,
                max_amplitude=0.0,
                min_amplitude=0.0,
                rms=0.0,
                zero_crossing_rate=0.0,
                is_silent=True,
                raw_data_sample=[]
            )
    
    async def process_audio_buffer(self, audio_buffer: List[rtc.AudioFrame], agent_audio_source):
        """Traite un buffer d'audio accumulé"""
        
        logger.info(f"🔧 [BUFFER] Traitement buffer de {len(audio_buffer)} frames")
        
        try:
            # Concaténer toutes les frames
            all_data = []
            for frame in audio_buffer:
                data = np.frombuffer(frame.data, dtype=np.int16)
                all_data.extend(data)
            
            if not all_data:
                logger.warning("⚠️ [BUFFER] Buffer vide")
                return
            
            # Convertir en numpy array
            audio_array = np.array(all_data, dtype=np.float32) / 32768.0
            
            # Analyse globale du buffer
            buffer_energy = float(np.sqrt(np.mean(audio_array**2)))
            buffer_max = float(np.max(np.abs(audio_array)))
            buffer_rms = float(np.sqrt(np.mean(audio_array**2)))
            
            logger.info(f"📊 [BUFFER] Énergie globale: {buffer_energy:.6f}")
            logger.info(f"📊 [BUFFER] Amplitude max: {buffer_max:.6f}")
            logger.info(f"📊 [BUFFER] RMS: {buffer_rms:.6f}")
            
            # Test de traitement même si "silencieux"
            if buffer_energy > 0.0001:  # Seuil très bas
                logger.info("🎯 [BUFFER] Audio détecté - traitement STT")
                await self.test_stt_processing(audio_array)
            else:
                logger.warning(f"⚠️ [BUFFER] Audio trop silencieux (énergie: {buffer_energy:.6f})")
                
                # Diagnostic approfondi pour audio silencieux
                await self.diagnose_silent_audio(audio_array)
            
        except Exception as e:
            logger.error(f"❌ [BUFFER] Erreur traitement buffer: {e}")
    
    async def diagnose_silent_audio(self, audio_array: np.ndarray):
        """Diagnostic approfondi pour audio silencieux"""
        
        logger.info("🔍 [SILENT] === DIAGNOSTIC AUDIO SILENCIEUX ===")
        
        try:
            # Statistiques détaillées
            unique_values = np.unique(audio_array)
            logger.info(f"🔍 [SILENT] Valeurs uniques: {len(unique_values)}")
            logger.info(f"🔍 [SILENT] Premières valeurs: {unique_values[:10]}")
            
            # Vérifier si toutes les valeurs sont exactement 0
            all_zero = np.all(audio_array == 0)
            logger.info(f"🔍 [SILENT] Toutes valeurs = 0: {all_zero}")
            
            # Vérifier la distribution
            non_zero_count = np.count_nonzero(audio_array)
            logger.info(f"🔍 [SILENT] Échantillons non-zéro: {non_zero_count}/{len(audio_array)}")
            
            # Histogramme des valeurs
            if len(unique_values) <= 20:
                for val in unique_values:
                    count = np.sum(audio_array == val)
                    logger.info(f"🔍 [SILENT] Valeur {val:.6f}: {count} occurrences")
            
            # Test de forçage pour validation pipeline
            if all_zero:
                logger.info("🔧 [SILENT] Test avec audio synthétique...")
                synthetic_audio = np.sin(2 * np.pi * 440 * np.linspace(0, 1, len(audio_array))) * 0.1
                await self.test_stt_processing(synthetic_audio)
            
        except Exception as e:
            logger.error(f"❌ [SILENT] Erreur diagnostic silencieux: {e}")
    
    async def test_stt_processing(self, audio_array: np.ndarray):
        """Test du traitement STT"""
        
        logger.info("🎯 [STT] Test traitement STT...")
        
        try:
            # Simuler l'appel STT (remplacer par vraie logique)
            logger.info(f"🎯 [STT] Envoi {len(audio_array)} échantillons à Whisper")
            
            # Ici on pourrait appeler le vrai service Whisper
            # Pour le diagnostic, on simule
            if np.max(np.abs(audio_array)) > 0.01:
                logger.info("✅ [STT] Audio suffisant pour transcription")
            else:
                logger.warning("⚠️ [STT] Audio trop faible pour transcription")
            
        except Exception as e:
            logger.error(f"❌ [STT] Erreur test STT: {e}")
    
    async def log_diagnostic_summary(self, frame_count: int):
        """Log un résumé du diagnostic"""
        
        elapsed_time = time.time() - self.start_time
        
        logger.info(f"📊 [SUMMARY] === RÉSUMÉ DIAGNOSTIC (Frame {frame_count}) ===")
        logger.info(f"📊 [SUMMARY] Temps écoulé: {elapsed_time:.1f}s")
        logger.info(f"📊 [SUMMARY] Frames totales: {self.total_frames_received}")
        logger.info(f"📊 [SUMMARY] Frames silencieuses: {self.silent_frames_count}")
        logger.info(f"📊 [SUMMARY] Frames non-silencieuses: {self.non_silent_frames_count}")
        
        if self.total_frames_received > 0:
            silence_ratio = self.silent_frames_count / self.total_frames_received
            logger.info(f"📊 [SUMMARY] Ratio silence: {silence_ratio:.2%}")
        
        # Dernières données de diagnostic
        if self.diagnostic_data:
            recent_data = self.diagnostic_data[-10:]  # 10 dernières frames
            avg_energy = np.mean([d.energy for d in recent_data])
            max_energy = np.max([d.energy for d in recent_data])
            logger.info(f"📊 [SUMMARY] Énergie moyenne (10 dernières): {avg_energy:.6f}")
            logger.info(f"📊 [SUMMARY] Énergie max (10 dernières): {max_energy:.6f}")
    
    async def start_continuous_monitoring(self, ctx: JobContext, audio_source: rtc.AudioSource):
        """Démarrage du monitoring continu"""
        
        logger.info("🔄 [MONITOR] === DÉMARRAGE MONITORING CONTINU ===")
        
        try:
            monitor_counter = 0
            
            while True:
                # Attendre 15 secondes entre chaque rapport
                await asyncio.sleep(15)
                
                monitor_counter += 1
                logger.info(f"🔄 [MONITOR] Rapport #{monitor_counter}")
                
                # Générer rapport de diagnostic
                await self.generate_diagnostic_report(monitor_counter)
                
                # Test audio périodique pour vérifier la publication
                if monitor_counter % 4 == 0:  # Toutes les minutes
                    await self.test_audio_publication(audio_source)
                
        except Exception as e:
            logger.error(f"❌ [MONITOR] Erreur monitoring: {e}")
    
    async def generate_diagnostic_report(self, report_number: int):
        """Génère un rapport de diagnostic complet"""
        
        logger.info(f"📋 [REPORT] === RAPPORT DIAGNOSTIC #{report_number} ===")
        
        try:
            elapsed_time = time.time() - self.start_time
            
            # Statistiques globales
            logger.info(f"📋 [REPORT] Durée session: {elapsed_time:.1f}s")
            logger.info(f"📋 [REPORT] Frames totales reçues: {self.total_frames_received}")
            logger.info(f"📋 [REPORT] Frames silencieuses: {self.silent_frames_count}")
            logger.info(f"📋 [REPORT] Frames avec audio: {self.non_silent_frames_count}")
            
            if self.total_frames_received > 0:
                silence_ratio = self.silent_frames_count / self.total_frames_received
                logger.info(f"📋 [REPORT] Taux de silence: {silence_ratio:.2%}")
                
                # Diagnostic du problème
                if silence_ratio > 0.95:
                    logger.error("❌ [REPORT] PROBLÈME CRITIQUE: >95% de frames silencieuses")
                    logger.error("❌ [REPORT] Causes possibles:")
                    logger.error("❌ [REPORT] 1. Permissions microphone non accordées")
                    logger.error("❌ [REPORT] 2. Microphone défaillant")
                    logger.error("❌ [REPORT] 3. Configuration audio incorrecte")
                    logger.error("❌ [REPORT] 4. Problème de transmission LiveKit")
                elif silence_ratio > 0.8:
                    logger.warning("⚠️ [REPORT] ATTENTION: >80% de frames silencieuses")
                else:
                    logger.info("✅ [REPORT] Niveau audio acceptable")
            
            # Analyse des dernières données
            if self.diagnostic_data:
                recent_data = self.diagnostic_data[-50:]  # 50 dernières frames
                energies = [d.energy for d in recent_data]
                
                if energies:
                    avg_energy = np.mean(energies)
                    max_energy = np.max(energies)
                    min_energy = np.min(energies)
                    
                    logger.info(f"📋 [REPORT] Énergie récente - Moy: {avg_energy:.6f}, Max: {max_energy:.6f}, Min: {min_energy:.6f}")
            
        except Exception as e:
            logger.error(f"❌ [REPORT] Erreur génération rapport: {e}")
    
    async def test_audio_publication(self, audio_source: rtc.AudioSource):
        """Test de publication audio pour vérifier le pipeline sortant"""
        
        logger.info("🎵 [TEST] Test publication audio...")
        
        try:
            # Générer un signal de test
            sample_rate = 24000
            duration = 2.0
            frequency = 880  # Note A5
            
            t = np.linspace(0, duration, int(sample_rate * duration))
            test_signal = np.sin(2 * np.pi * frequency * t) * 0.2
            
            # Convertir en int16
            test_audio = (test_signal * 32767).astype(np.int16)
            
            # Publier par chunks
            samples_per_frame = 240  # 10ms à 24kHz
            
            for i in range(0, len(test_audio), samples_per_frame):
                frame_samples = test_audio[i:i+samples_per_frame]
                
                if len(frame_samples) == samples_per_frame:
                    audio_frame = rtc.AudioFrame.create(
                        sample_rate=24000,
                        num_channels=1,
                        samples_per_channel=samples_per_frame
                    )
                    
                    audio_frame.data[:len(frame_samples)*2] = frame_samples.tobytes()
                    await audio_source.capture_frame(audio_frame)
                    await asyncio.sleep(0.01)
            
            logger.info("✅ [TEST] Signal de test publié")
            
        except Exception as e:
            logger.error(f"❌ [TEST] Erreur test publication: {e}")

# Point d'entrée pour l'agent de diagnostic
async def diagnostic_entrypoint(ctx: JobContext):
    """Point d'entrée pour l'agent de diagnostic"""
    diagnostic_agent = AudioDiagnosticAgent()
    await diagnostic_agent.entrypoint(ctx)

if __name__ == "__main__":
    print("🔍 [DIAGNOSTIC] Démarrage agent de diagnostic audio...")
    
    async def main():
        try:
            worker_opts = agents.WorkerOptions(
                entrypoint_fnc=diagnostic_entrypoint,
                ws_url=os.environ.get("LIVEKIT_URL"),
                api_key=os.environ.get("LIVEKIT_API_KEY"),
                api_secret=os.environ.get("LIVEKIT_API_SECRET")
            )
            
            worker = agents.Worker(worker_opts)
            await worker.run()
            
        except Exception as e:
            print(f"❌ [DIAGNOSTIC] Erreur: {e}")
            raise
    
    asyncio.run(main())