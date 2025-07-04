import asyncio
import numpy as np
import os
import time
from typing import AsyncGenerator
import piper as piper_tts # Renommer pour éviter le conflit avec la fonction synthesize
import logging
import re
from typing import AsyncGenerator, Optional
import io
import json
import torch
import torchaudio.transforms as T

logger = logging.getLogger(__name__)
# Augmenter le niveau de log pour le débogage de ce module
logging.getLogger(__name__).setLevel(logging.DEBUG)

class RealTimeStreamingTTS:
    # Singleton pattern pour éviter les rechargements
    _instance = None
    _model_loaded = False
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        # Éviter la réinitialisation si déjà fait
        if hasattr(self, '_initialized'):
            return
            
        self.voice_model_name = "fr_FR-tom-medium.onnx"
        self.voice_config_name = "fr_FR-tom-medium.onnx.json"
        self.models_base_path = os.getenv("PIPER_MODELS_PATH", "/app/voices")
        self.voice_model_path = os.path.join(self.models_base_path, self.voice_model_name)
        self.voice_config_path = os.path.join(self.models_base_path, self.voice_config_name)

        self.sample_rate = 22050  # Valeur par défaut, sera mise à jour depuis le JSON
        self.chunk_size = 1024
        
        self.synthesizer_model: Optional[piper_tts.PiperVoice] = None # L'instance du modèle Piper
        self.target_sample_rate = 48000 # Cible le sample rate de LiveKit/Flutter
        self.resampler = None
        
        logger.info(f"🚀 RealTimeStreamingTTS initialisé (singleton) avec modèle: {self.voice_model_path}")
        
        # LAZY LOADING : Le modèle sera chargé seulement lors de la première utilisation
        self._initialized = True

    def _load_piper_model(self):
        """Charge le modèle Piper TTS avec lazy loading."""
        if RealTimeStreamingTTS._model_loaded and self.synthesizer_model:
            logger.info("⚡ Modèle Piper déjà chargé (réutilisation)")
            return
            
        if not os.path.exists(self.voice_model_path):
            logger.error(f"Modèle Piper NON TROUVÉ: {self.voice_model_path}")
            return
        if not os.path.exists(self.voice_config_path):
            logger.error(f"Configuration Piper NON TROUVÉE: {self.voice_config_path}")
            return

        try:
            logger.info("🔄 Chargement du modèle Piper TTS...")
            start_time = asyncio.get_event_loop().time() if hasattr(asyncio, 'get_event_loop') else 0
            
            self.synthesizer_model = piper_tts.PiperVoice.load(
                self.voice_model_path,
                self.voice_config_path
            )
            
            # Une fois le modèle correctement chargé, lire le sample_rate depuis le JSON
            sample_rate = self._get_sample_rate_safe()
            if sample_rate:
                self.sample_rate = sample_rate
                logger.info(f"Sample rate configuré depuis le modèle Piper: {self.sample_rate}")
            else:
                logger.warning(f"Utilisation du sample_rate par défaut: {self.sample_rate}")
            
            # Initialiser le resampler maintenant que nous avons le sample rate
            if self.sample_rate != self.target_sample_rate:
                self.resampler = T.Resample(orig_freq=self.sample_rate, new_freq=self.target_sample_rate)
                logger.info(f"Initialisation du resampler de {self.sample_rate}Hz à {self.target_sample_rate}Hz.")
            else:
                logger.info(f"Pas besoin de resampler, le sample rate du modèle ({self.sample_rate}Hz) correspond à la cible ({self.target_sample_rate}Hz).")
            
            RealTimeStreamingTTS._model_loaded = True
            load_time = (asyncio.get_event_loop().time() - start_time) if start_time else 0
            logger.info(f"✅ Modèle Piper TTS chargé avec succès en {load_time:.2f}s")
            
        except Exception as e:
            logger.error(f"Erreur lors du chargement du modèle Piper TTS - vérifier les chemins et la validité du fichier: {e}", exc_info=True)
            logger.error(f"Chemins tentés: Modèle: {self.voice_model_path}, Config: {self.voice_config_path}")
            self.synthesizer_model = None # S'assurer que le modèle est None en cas d'échec

    def _get_sample_rate_safe(self) -> Optional[int]:
        """Obtient le sample_rate de manière sécurisée selon l'API Piper officielle"""
        if not self.synthesizer_model:
            logger.error("Modèle Piper non chargé")
            return None

        try:
            # Méthode principale (recommandée selon la documentation Piper)
            # Lire le sample_rate depuis le fichier JSON de configuration
            with open(self.voice_config_path, 'r') as f:
                config_data = json.load(f)
            sample_rate = config_data['audio']['sample_rate']
            logger.info(f"✅ Sample rate obtenu depuis JSON: {sample_rate}")
            return sample_rate
        except Exception as e: # Simplifié, TypeError et AttributeError sont des sous-classes d'Exception
            logger.error(f"❌ Erreur accès sample_rate ou fichier de config mal formé: {e}")
            logger.warning(f"⚠️ Utilisation du sample_rate par défaut pré-configuré (depuis __init__): {self.sample_rate}")
            return self.sample_rate # Retourne le sample_rate déjà initialisé dans __init__

    def get_sample_rate(self) -> int:
        """Retourne le sample_rate actuel (pour les tests)"""
        return self.sample_rate

    def configure_tom_voice(self):
        """Configure la voix Tom français pour streaming (surcharge les valeurs par défaut du modèle si nécessaire)"""
        if not self.synthesizer_model:
            logger.error("Modèle Piper non chargé, impossible de configurer la voix.")
            return None # Renvoie None si le modèle n'est pas prêt

        config = {
            "model_path": self.voice_model_path, # Gardé pour information, mais pas utilisé directement par synthesize une fois le modèle chargé
            "config_path": self.voice_config_path, # Idem
            "speaker_id": 0, # Par défaut, ajuster si le modèle supporte plusieurs voix
            "length_scale": 1.0,
            "noise_scale": 0.667,
            "noise_w": 0.8,
            "sample_rate": self.sample_rate,
        }
        return config
        
    async def stream_generate_audio(self, text: str) -> AsyncGenerator[bytes, None]:
        """Génère l'audio en streaming temps réel"""
        stream_start_time = time.time()
        logger.info(f"TTS_STREAM_DEBUG: Début stream_generate_audio pour: '{text[:50]}...' à {stream_start_time}")
        
        try:
            config = self.configure_tom_voice()
            logger.debug(f"TTS_STREAM_DEBUG: Configuration TTS obtenue: {config}")
            
            if not os.path.exists(config["model_path"]) or not os.path.exists(config["config_path"]):
                logger.error(f"TTS_STREAM_DEBUG: Modèle ou config Piper manquant. Model: {config['model_path']}, Config: {config['config_path']}")
                # Fallback: générer un silence ou une erreur audio identifiable
                silence_chunk = b'\x00' * self.chunk_size
                yield silence_chunk
                return

            sentences = self._split_text_for_streaming(text)
            logger.debug(f"TTS_STREAM_DEBUG: Texte découpé en {len(sentences)} phrases: {sentences}")
            
            if not sentences:
                logger.warning("TTS_STREAM_DEBUG: Aucune phrase à synthétiser après découpage.")
                yield b'' # Renvoyer un chunk vide pour éviter de bloquer
                return

            sentence_count = 0
            total_chunks_yielded = 0
            
            for sentence in sentences:
                if not sentence.strip():
                    continue
                    
                sentence_count += 1
                sentence_start_time = time.time()
                logger.info(f"TTS_STREAM_DEBUG: Phrase #{sentence_count}: '{sentence[:50]}...' - début à {sentence_start_time - stream_start_time:.2f}s")
                
                audio_chunk_full_sentence = await self._generate_audio_chunk(sentence, config)
                
                sentence_generation_time = time.time() - sentence_start_time
                logger.debug(f"TTS_STREAM_DEBUG: Phrase #{sentence_count} générée en {sentence_generation_time:.2f}s, taille: {len(audio_chunk_full_sentence) if audio_chunk_full_sentence else 0} bytes")
                
                if not audio_chunk_full_sentence:
                    logger.warning(f"TTS_STREAM_DEBUG: Aucun audio généré pour la phrase #{sentence_count}: '{sentence[:50]}...'")
                    continue

                chunks = self._split_audio_chunks(audio_chunk_full_sentence)
                logger.debug(f"TTS_STREAM_DEBUG: Phrase #{sentence_count} découpée en {len(chunks)} chunks")
                
                for chunk_idx, chunk in enumerate(chunks):
                    chunk_time = time.time() - stream_start_time
                    logger.debug(f"TTS_STREAM_DEBUG: Yield chunk #{chunk_idx+1}/{len(chunks)} de la phrase #{sentence_count} à {chunk_time:.2f}s - {len(chunk)} bytes")
                    yield chunk
                    total_chunks_yielded += 1
                    # OPTIMISATION: Suppression du délai artificiel pour latence temps réel
                    # await asyncio.sleep(0.01) # Simule le temps de traitement/réseau pour le streaming
            
            total_time = time.time() - stream_start_time
            logger.info(f"TTS_STREAM_DEBUG: ✅ Streaming TTS terminé en {total_time:.2f}s. {sentence_count} phrases, {total_chunks_yielded} chunks au total.")
                    
        except Exception as e:
            total_time = time.time() - stream_start_time
            logger.error(f"TTS_STREAM_DEBUG: ÉCHEC STREAMING TTS après {total_time:.2f}s: {e}", exc_info=True)
            # En cas d'erreur, envoyer un chunk de silence pour ne pas bloquer le pipeline
            silence_chunk = b'\x00' * self.chunk_size
            yield silence_chunk
            # Ne pas lever d'exception ici pour permettre au reste du système de continuer si possible
            
    def _split_text_for_streaming(self, text: str) -> list:
        """Découpe le texte en phrases pour streaming"""
        # Découpage par phrases avec ponctuation, en gardant la ponctuation
        sentences = re.split(r'([.!?]+)', text)
        # Regrouper les phrases avec leur ponctuation
        result = []
        for i in range(0, len(sentences) -1, 2):
            sentence_text = sentences[i].strip()
            punctuation = sentences[i+1].strip() if (i+1) < len(sentences) else ""
            if sentence_text:
                result.append(sentence_text + punctuation)
        # S'il reste un bout de phrase sans ponctuation à la fin
        if len(sentences) % 2 == 1 and sentences[-1].strip():
            result.append(sentences[-1].strip())
            
        return [s for s in result if s]
        
    async def _generate_audio_chunk(self, sentence: str, config: dict) -> bytes:
        """Génère un chunk audio pour une phrase"""
        chunk_start_time = time.time()
        logger.debug(f"TTS_CHUNK_DEBUG: Début _generate_audio_chunk pour: '{sentence[:50]}...'")
        
        loop = asyncio.get_event_loop()
        try:
            # piper.synthesize est bloquant, donc exécution dans un thread executor
            logger.debug(f"TTS_CHUNK_DEBUG: Appel run_in_executor pour _piper_synthesize")
            executor_start = time.time()
            
            audio_data_np = await loop.run_in_executor(
                None,
                self._piper_synthesize,
                sentence,
                config
            )
            
            executor_time = time.time() - executor_start
            logger.debug(f"TTS_CHUNK_DEBUG: run_in_executor terminé en {executor_time:.2f}s")
            
            if audio_data_np is None or audio_data_np.size == 0:
                logger.warning(f"TTS_CHUNK_DEBUG: Aucun audio généré par Piper pour: '{sentence[:50]}...'")
                return b""

            logger.debug(f"TTS_CHUNK_DEBUG: Audio numpy reçu: {audio_data_np.shape}, dtype: {audio_data_np.dtype}")

            # Resampler si nécessaire
            if self.resampler:
                resample_start = time.time()
                logger.debug(f"TTS_CHUNK_DEBUG: Début resampling de {self.sample_rate}Hz à {self.target_sample_rate}Hz")
                
                audio_tensor = torch.from_numpy(audio_data_np).float()
                audio_tensor = self.resampler(audio_tensor)
                audio_data_np = audio_tensor.numpy()
                
                resample_time = time.time() - resample_start
                logger.debug(f"TTS_CHUNK_DEBUG: Resampling terminé en {resample_time:.2f}s. Nouvelle forme: {audio_data_np.shape}")

            # Convertir en bytes (PCM 16-bit)
            convert_start = time.time()
            audio_bytes = (audio_data_np * 32767).astype(np.int16).tobytes()
            convert_time = time.time() - convert_start
            
            total_time = time.time() - chunk_start_time
            logger.debug(f"TTS_CHUNK_DEBUG: ✅ Chunk généré en {total_time:.2f}s (conversion: {convert_time:.3f}s). Taille finale: {len(audio_bytes)} bytes")
            
            return audio_bytes
        except Exception as e:
            total_time = time.time() - chunk_start_time
            logger.error(f"TTS_CHUNK_DEBUG: Erreur pendant _generate_audio_chunk après {total_time:.2f}s pour '{sentence[:50]}...': {e}", exc_info=True)
            return b"" # Retourner des bytes vides en cas d'erreur
        
    def _piper_synthesize(self, text: str, config: dict) -> np.ndarray:
        """Synthèse Piper synchrone avec debug - Retourne un numpy array float32."""
        import traceback
        import wave
        import time
        
        start_time = time.time()
        logger.info(f"🔍 DEBUG: Début _piper_synthesize pour: '{text[:50]}...'")
        
        # LAZY LOADING : Charger le modèle seulement maintenant si nécessaire
        if not self.synthesizer_model:
            logger.info("🔄 Chargement lazy du modèle Piper pour la première synthèse...")
            load_start = time.time()
            self._load_piper_model()
            load_time = time.time() - load_start
            logger.info(f"⏱️ Temps de chargement modèle Piper: {load_time:.2f}s")
            
        if not self.synthesizer_model:
            logger.error("Modèle Piper TTS non disponible pour la synthèse après tentative de chargement.")
            return np.array([], dtype=np.float32)
            
        try:
            # Test avec buffer mémoire
            logger.info("🔍 DEBUG: Tentative avec io.BytesIO()...")
            buffer_start = time.time()
            
            wav_buffer = io.BytesIO()
            
            # Synthesize directement dans le buffer mémoire
            synth_start = time.time()
            with wave.open(wav_buffer, 'wb') as wav_file:
                self.synthesizer_model.synthesize(text, wav_file)
            synth_time = time.time() - synth_start
            logger.info(f"⏱️ Temps synthèse Piper: {synth_time:.2f}s")
            
            # Récupérer les bytes WAV du buffer
            wav_bytes = wav_buffer.getvalue()
            wav_buffer.close()
            
            logger.info(f"🔍 DEBUG: Buffer produit {len(wav_bytes)} bytes WAV")
            
            if not wav_bytes:
                logger.warning(f"Synthèse Piper n'a produit aucun audio (bytes vides) pour le texte: '{text[:50]}...'")
                return np.array([], dtype=np.float32)

            # Lire les bytes WAV pour les convertir en numpy array float32
            convert_start = time.time()
            with io.BytesIO(wav_bytes) as wav_io:
                with wave.open(wav_io, 'rb') as wf:
                    num_frames = wf.getnframes()
                    frames_bytes = wf.readframes(num_frames)
                    
                    # Vérifier si le sample width est correct (devrait être 2 pour int16)
                    if wf.getsampwidth() != 2:
                        logger.error(f"Sample width inattendu du WAV Piper: {wf.getsampwidth()}. Attendu: 2 (pour int16).")
                        return np.array([], dtype=np.float32)
                    
                    # Convertir les frames (bytes) en int16 numpy array
                    audio_int16 = np.frombuffer(frames_bytes, dtype=np.int16)
                    
                    # Convertir en float32 et normaliser
                    audio_float32 = audio_int16.astype(np.float32) / 32767.0
                    
            convert_time = time.time() - convert_start
            total_time = time.time() - start_time
            
            logger.info(f"⏱️ Temps conversion: {convert_time:.2f}s")
            logger.info(f"⏱️ TOTAL _piper_synthesize: {total_time:.2f}s")
            logger.info(f"⚡ Audio généré: {len(audio_float32)} échantillons float32.")
            return audio_float32
            
        except Exception as e:
            total_time = time.time() - start_time
            logger.error(f"❌ ERREUR _piper_synthesize après {total_time:.2f}s: {e}")
            logger.error(f"DEBUG: Traceback complet: {traceback.format_exc()}")
            return np.array([], dtype=np.float32)
        
    def _split_audio_chunks(self, audio_data: bytes) -> list:
        """Découpe l'audio en chunks pour streaming"""
        chunks = []
        if not audio_data:
            return chunks
        for i in range(0, len(audio_data), self.chunk_size):
            chunk = audio_data[i:i + self.chunk_size]
            chunks.append(chunk)
        return chunks

# Code de test (peut être décommenté pour des tests unitaires)
# async def test_tom_streaming():
#     # S'assurer que les modèles sont au bon endroit pour ce test, ex: /app/voices/
#     # Créer un dossier /app/voices et y mettre les modèles .onnx et .json
#     # ou ajuster self.models_base_path pour pointer vers le bon dossier localement.
#     if not os.path.exists("/app/voices"):
#         os.makedirs("/app/voices", exist_ok=True)
#         # Simuler la présence des modèles pour un test local si nécessaire
#         # Exemple: open("/app/voices/fr_FR-tom-high.onnx", "w").write("dummy onnx")
#         # open("/app/voices/fr_FR-tom-high.onnx.json", "w").write("dummy json")

#     logging.basicConfig(level=logging.INFO)
#     tts = RealTimeStreamingTTS()
#     test_text = "Bonjour, je suis Tom. Votre assistant vocal français en streaming temps réel! Comment allez-vous aujourd'hui?"
    
#     logger.info("Début du test de streaming TTS...")
#     chunk_count = 0
#     total_bytes = 0
#     async for chunk in tts.stream_generate_audio(test_text):
#         chunk_count += 1
#         total_bytes += len(chunk)
#         logger.info(f"Chunk {chunk_count} reçu: {len(chunk)} bytes")
#         # Simuler le traitement du chunk (ex: envoi à LiveKit)
#         await asyncio.sleep(0.05)
        
#     logger.info(f"Streaming terminé. Total chunks: {chunk_count}, Total bytes: {total_bytes}")
#     if total_bytes == 0 and chunk_count <=1 : # <=1 car un chunk vide peut être envoyé
#          logger.error("ERREUR: Aucun audio n'a été généré pendant le test.")
#     elif chunk_count > 1:
#         logger.info(" Test de streaming TTS réussi (plusieurs chunks générés).")
#     else:
#         logger.warning(" Test de streaming TTS: Un seul chunk ou des chunks vides générés. Vérifier la sortie.")

# if __name__ == '__main__':
#     # Pour exécuter ce test, il faut que la librairie piper soit installée
#     # et que les modèles fr_FR-tom-high.onnx et .json soient accessibles
#     # dans le chemin attendu (ex: /app/voices/ ou ajuster la classe).
#     # asyncio.run(test_tom_streaming())
#     print("Décommenter asyncio.run(test_tom_streaming()) et configurer les modèles pour tester.")