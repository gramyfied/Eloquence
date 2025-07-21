#!/usr/bin/env python3
"""
Service de reconnaissance vocale et analyse prosodique avec VOSK
Remplace complètement Whisper pour une solution 100% locale et rapide
"""

import os
import json
import asyncio
import numpy as np
import wave
import tempfile
import unicodedata
import re
import subprocess
from typing import Optional, Dict, Any, List
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import vosk
import librosa
import soundfile as sf
from contextlib import asynccontextmanager
import logging
from pathlib import Path

# Configuration des logs avec encodage UTF-8
log_dir = Path('/app/logs')
log_dir.mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(log_dir / 'vosk.log', encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

# Configuration VOSK
MODEL_PATH = "/app/models/vosk-model-fr-0.22"
SAMPLE_RATE = 16000

# Variables globales pour le modèle
vosk_model: Optional[vosk.Model] = None

def normalize_unicode_text(text: str) -> str:
    """Normalise le texte Unicode et convertit les émojis en texte ASCII"""
    if not text:
        return ""
    
    normalized = unicodedata.normalize('NFC', text)
    
    emoji_map = {
        '🌟': 'Excellent', '👍': 'Tres bien', '✅': 'Bon', '💪': 'Encourageant',
        '😊': 'Content', '🎉': 'Felicitations', '😞': 'Peut mieux faire',
        '⚡': 'Energie', '📊': 'Statistiques', '•': '-', '→': '->',
        '←': '<-', '↑': '^', '↓': 'v'
    }
    
    for emoji, text_replacement in emoji_map.items():
        normalized = normalized.replace(emoji, text_replacement)
    
    ascii_text = normalized.encode('ascii', 'ignore').decode('ascii')
    ascii_text = re.sub(r'\s+', ' ', ascii_text).strip()
    
    return ascii_text

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie avec téléchargement automatique"""
    global vosk_model
    logger.info("🚀 Démarrage du service VOSK...")
    
    try:
        # Téléchargement automatique du modèle si manquant
        if not os.path.exists(MODEL_PATH):
            logger.warning(f"⚠️ Modèle manquant à {MODEL_PATH}")
            logger.info("📥 Téléchargement automatique du modèle...")
            
            result = subprocess.run(["/app/download_model.sh"], 
                                  capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"❌ Échec téléchargement: {result.stderr}")
                raise RuntimeError(f"Impossible de télécharger le modèle Vosk")
            
            logger.info(f"✅ Modèle téléchargé avec succès. stdout: {result.stdout}")
        
        # Vérification finale du modèle
        if not os.path.exists(MODEL_PATH):
            logger.error(f"Modèle VOSK non trouvé à {MODEL_PATH} après tentative de téléchargement.")
            raise RuntimeError(f"Modèle VOSK non trouvé à {MODEL_PATH}")
        
        # Initialisation du modèle Vosk
        logger.info(f"Chargement du modele VOSK depuis {MODEL_PATH}...")
        vosk_model = vosk.Model(MODEL_PATH)
        logger.info("✅ Modèle VOSK chargé avec succès")
        yield
        
    except Exception as e:
        logger.error(f"❌ Erreur critique lors de l'initialisation: {e}")
        raise
    finally:
        logger.info("🛑 Arrêt du service VOSK")

# Création de l'app FastAPI
app = FastAPI(
    title="VOSK Speech Analysis Service",
    description="Service de reconnaissance vocale et analyse prosodique avec VOSK",
    version="1.0.0",
    lifespan=lifespan
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modèles Pydantic
class TranscriptionResult(BaseModel):
    text: str
    confidence: float
    words: List[Dict[str, Any]]
    duration: float
    language: str = "fr"

class ProsodyAnalysis(BaseModel):
    pitch_mean: float
    pitch_std: float
    energy_mean: float
    energy_std: float
    speaking_rate: float
    pause_ratio: float
    voice_quality: float

class AnalysisResult(BaseModel):
    transcription: TranscriptionResult
    prosody: ProsodyAnalysis
    confidence_score: float
    fluency_score: float
    clarity_score: float
    energy_score: float
    overall_score: float
    processing_time: float
    strengths: List[str]
    improvements: List[str]
    feedback: str

@app.get("/health")
async def health_check():
    """Vérification de santé du service"""
    return {
        "status": "healthy",
        "service": "vosk-stt-analysis",
        "model_loaded": vosk_model is not None,
        "model_path": MODEL_PATH,
        "timestamp": datetime.utcnow().isoformat()
    }

def convert_audio_to_wav(audio_data: bytes, original_filename: str) -> tuple[str, float]:
    """Convertit l'audio en WAV 16kHz mono pour VOSK"""
    with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(original_filename)[1]) as tmp_input:
        tmp_input.write(audio_data)
        tmp_input_path = tmp_input.name
    
    try:
        audio, sr = librosa.load(tmp_input_path, sr=None, mono=True)
        
        if sr != SAMPLE_RATE:
            audio = librosa.resample(audio, orig_sr=sr, target_sr=SAMPLE_RATE)
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_output:
            sf.write(tmp_output.name, audio, SAMPLE_RATE, subtype='PCM_16')
            return tmp_output.name, len(audio) / SAMPLE_RATE
            
    finally:
        os.unlink(tmp_input_path)

def transcribe_with_vosk(wav_path: str) -> Dict[str, Any]:
    """Transcription avec VOSK"""
    if not vosk_model:
        raise RuntimeError("VOSK model is not loaded.")
    rec = vosk.KaldiRecognizer(vosk_model, SAMPLE_RATE)
    rec.SetWords(True)
    
    results = []
    
    with wave.open(wav_path, 'rb') as wf:
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                results.append(json.loads(rec.Result()))
        
        final_result = json.loads(rec.FinalResult())
        if final_result.get('text'):
            results.append(final_result)
    
    all_words = []
    full_text = []
    
    for result in results:
        if 'text' in result and result['text']:
            normalized_text = normalize_unicode_text(result['text'])
            full_text.append(normalized_text)
        if 'result' in result:
            for word in result['result']:
                if 'word' in word:
                    word['word'] = normalize_unicode_text(word['word'])
            all_words.extend(result['result'])
    
    final_text = ' '.join(full_text)
    return {
        'text': final_text,
        'words': all_words,
        'confidence': calculate_confidence(all_words)
    }

def calculate_confidence(words: List[Dict[str, Any]]) -> float:
    """Calcule la confiance moyenne des mots"""
    if not words:
        return 0.0
    
    confidences = [w.get('conf', 0.0) for w in words]
    return sum(confidences) / len(confidences) if confidences else 0.0

def analyze_prosody(wav_path: str) -> Dict[str, float]:
    """Analyse prosodique de l'audio"""
    y, sr = librosa.load(wav_path, sr=SAMPLE_RATE)
    
    pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
    pitch_values = []
    
    for t in range(pitches.shape[1]):
        index = magnitudes[:, t].argmax()
        pitch = pitches[index, t]
        if pitch > 0:
            pitch_values.append(pitch)
    
    pitch_mean = np.mean(pitch_values) if pitch_values else 0.0
    pitch_std = np.std(pitch_values) if pitch_values else 0.0
    
    rms = librosa.feature.rms(y=y)[0]
    energy_mean = float(np.mean(rms))
    energy_std = float(np.std(rms))
    
    threshold = energy_mean * 0.1
    is_pause = rms < threshold
    pause_frames = np.sum(is_pause)
    total_frames = len(rms)
    pause_ratio = pause_frames / total_frames if total_frames > 0 else 0.0
    
    speaking_segments = ~is_pause
    speaking_time = np.sum(speaking_segments) * (len(y) / sr) / len(rms)
    
    peaks = librosa.onset.onset_detect(y=y, sr=sr, units='time')
    syllable_rate = len(peaks) / (len(y) / sr) * 60 if len(y) > 0 else 0.0
    
    voice_quality = 1.0 - min(pitch_std / (pitch_mean + 1e-6), 1.0) if pitch_mean > 0 else 0.5
    
    return {
        'pitch_mean': float(pitch_mean),
        'pitch_std': float(pitch_std),
        'energy_mean': float(energy_mean),
        'energy_std': float(energy_std),
        'speaking_rate': float(syllable_rate),
        'pause_ratio': float(pause_ratio),
        'voice_quality': float(voice_quality)
    }

def calculate_scores(transcription: Dict[str, Any], prosody: Dict[str, float]) -> Dict[str, float]:
    """Calcule les scores d'évaluation"""
    confidence_score = transcription['confidence']
    
    pause_penalty = min(prosody['pause_ratio'] * 2, 0.5)
    rate_score = 1.0 - abs(prosody['speaking_rate'] - 150) / 150
    fluency_score = max(0.0, min(1.0, rate_score - pause_penalty))
    
    clarity_score = prosody['voice_quality']
    
    energy_variation = prosody['energy_std'] / (prosody['energy_mean'] + 1e-6)
    energy_score = min(1.0, energy_variation * 2)
    
    overall_score = (
        confidence_score * 0.3 +
        fluency_score * 0.25 +
        clarity_score * 0.25 +
        energy_score * 0.2
    )
    
    return {
        'confidence_score': confidence_score,
        'fluency_score': fluency_score,
        'clarity_score': clarity_score,
        'energy_score': energy_score,
        'overall_score': overall_score
    }

def generate_feedback(scores: Dict[str, float], transcription: Dict[str, Any], prosody: Dict[str, float]) -> tuple[str, List[str], List[str]]:
    """Génère le feedback et les points forts/améliorations"""
    strengths = []
    improvements = []
    
    if scores['confidence_score'] > 0.8:
        strengths.append("Excellente articulation et prononciation")
    if scores['fluency_score'] > 0.8:
        strengths.append("Débit de parole fluide et naturel")
    if scores['clarity_score'] > 0.8:
        strengths.append("Voix claire et stable")
    if scores['energy_score'] > 0.7:
        strengths.append("Bonne variation d'intonation")
    
    if scores['confidence_score'] < 0.6:
        improvements.append("Articuler plus clairement les mots")
    if prosody['pause_ratio'] > 0.3:
        improvements.append("Réduire les pauses et hésitations")
    if prosody['speaking_rate'] < 100:
        improvements.append("Parler un peu plus rapidement")
    elif prosody['speaking_rate'] > 200:
        improvements.append("Ralentir légèrement le débit")
    if scores['energy_score'] < 0.5:
        improvements.append("Varier davantage l'intonation")
    
    overall = scores['overall_score']
    if overall >= 0.8:
        feedback = "Excellente performance ! Votre communication est claire, fluide et engageante."
    elif overall >= 0.7:
        feedback = "Tres bonne performance ! Quelques ajustements mineurs ameliorent encore votre impact."
    elif overall >= 0.6:
        feedback = "Bonne performance avec des points a ameliorer pour gagner en confiance."
    else:
        feedback = "Performance encourageante ! Continuez a pratiquer pour developper votre aisance."
    
    word_count = len(transcription.get('text', '').split())
    feedback += f"\n\nAnalyse detaillee :\n"
    feedback += f"- Mots detectes : {word_count}\n"
    feedback += f"- Debit : {prosody['speaking_rate']:.0f} syllabes/minute\n"
    feedback += f"- Temps de pause : {prosody['pause_ratio']*100:.1f}%\n"
    
    return normalize_unicode_text(feedback), [normalize_unicode_text(s) for s in strengths], [normalize_unicode_text(i) for i in improvements]

@app.post("/analyze", response_model=AnalysisResult)
async def analyze_speech(
    audio: UploadFile = File(...),
    scenario_type: Optional[str] = Form(None),
    scenario_context: Optional[str] = Form(None)
):
    """Analyse complète de la parole avec VOSK"""
    start_time = datetime.utcnow()
    
    try:
        audio_data = await audio.read()
        
        wav_path, duration = convert_audio_to_wav(audio_data, audio.filename)
        
        try:
            transcription_result = transcribe_with_vosk(wav_path)
            
            prosody_result = analyze_prosody(wav_path)
            
            scores = calculate_scores(transcription_result, prosody_result)
            
            feedback, strengths, improvements = generate_feedback(
                scores, transcription_result, prosody_result
            )
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            result = AnalysisResult(
                transcription=TranscriptionResult(
                    text=transcription_result['text'],
                    confidence=transcription_result['confidence'],
                    words=transcription_result['words'],
                    duration=duration
                ),
                prosody=ProsodyAnalysis(**prosody_result),
                **scores,
                overall_score=scores['overall_score'] * 100,
                processing_time=processing_time,
                strengths=strengths,
                improvements=improvements,
                feedback=feedback
            )
            
            logger.info(f"✅ Analyse terminée en {processing_time:.2f}s - Score: {result.overall_score:.1f}%")
            return result
            
        finally:
            if os.path.exists(wav_path):
                os.unlink(wav_path)
                
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'analyse: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transcribe", response_model=TranscriptionResult)
async def transcribe_only(audio: UploadFile = File(...)):
    """Transcription simple sans analyse prosodique"""
    try:
        audio_data = await audio.read()
        wav_path, duration = convert_audio_to_wav(audio_data, audio.filename)
        
        try:
            result = transcribe_with_vosk(wav_path)
            
            return TranscriptionResult(
                text=result['text'],
                confidence=result['confidence'],
                words=result['words'],
                duration=duration
            )
            
        finally:
            if os.path.exists(wav_path):
                os.unlink(wav_path)
                
    except Exception as e:
        logger.error(f"❌ Erreur lors de la transcription: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=2700, # Port standard pour ce service
        reload=False,
        log_level="info"
    )