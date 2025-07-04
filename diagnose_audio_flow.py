#!/usr/bin/env python3
"""
Script de diagnostic du flux audio LiveKit
Vérifie la capture et le traitement de l'audio
"""

import asyncio
import os
import sys
import logging
from datetime import datetime

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def analyze_agent_config():
    """Analyser la configuration de l'agent"""
    print("\n" + "="*80)
    print("🔍 ANALYSE DE LA CONFIGURATION DE L'AGENT")
    print("="*80)
    
    # Paramètres critiques dans l'agent
    config_issues = []
    
    print("\n📊 Paramètres de traitement audio:")
    print(f"  - MIN_CHUNK_SIZE: 6000 échantillons (0.25s à 24kHz)")
    print(f"  - MAX_CHUNK_SIZE: 48000 échantillons (2s à 24kHz)")
    print(f"  - AUDIO_INTERVAL_MS: 3000ms (3 secondes)")
    print(f"  - Frames minimum avant traitement: 25")
    print(f"  - Frames par chunk: 100")
    
    # Problème 1: Intervalle trop long
    config_issues.append({
        "problème": "Intervalle de traitement trop long (3s)",
        "impact": "L'utilisateur doit parler pendant 3 secondes avant traitement",
        "solution": "Réduire AUDIO_INTERVAL_MS à 1000ms (1 seconde)"
    })
    
    # Problème 2: Buffer minimum trop petit
    config_issues.append({
        "problème": "Buffer minimum de 25 frames insuffisant",
        "impact": "Audio trop court envoyé à Whisper (3000 échantillons)",
        "solution": "Augmenter le nombre minimum de frames à 50-100"
    })
    
    # Problème 3: Taux d'échantillonnage
    config_issues.append({
        "problème": "Confusion entre 24kHz (Whisper) et 48kHz (LiveKit)",
        "impact": "Rééchantillonnage incorrect ou perte de données",
        "solution": "Vérifier le taux d'échantillonnage des frames reçues"
    })
    
    print("\n❌ PROBLÈMES IDENTIFIÉS:")
    for i, issue in enumerate(config_issues, 1):
        print(f"\n{i}. {issue['problème']}")
        print(f"   Impact: {issue['impact']}")
        print(f"   Solution: {issue['solution']}")
    
    return config_issues

def generate_fix_recommendations():
    """Générer les recommandations de correction"""
    print("\n" + "="*80)
    print("🔧 RECOMMANDATIONS DE CORRECTION")
    print("="*80)
    
    fixes = [
        {
            "fichier": "services/api-backend/services/real_time_voice_agent_force_audio.py",
            "ligne": 299,
            "modification": "AUDIO_INTERVAL_MS = 1000  # Réduire de 3000 à 1000"
        },
        {
            "fichier": "services/api-backend/services/real_time_voice_agent_force_audio.py",
            "ligne": 527,
            "modification": "if len(self._audio_buffer) >= 50:  # Augmenter de 25 à 50"
        },
        {
            "fichier": "services/api-backend/services/real_time_voice_agent_force_audio.py",
            "ligne": 428,
            "modification": "self.frames_per_chunk = 200  # Augmenter de 100 à 200"
        }
    ]
    
    print("\n📝 Modifications à appliquer:")
    for fix in fixes:
        print(f"\n- Fichier: {fix['fichier']}")
        print(f"  Ligne: {fix['ligne']}")
        print(f"  Modification: {fix['modification']}")
    
    return fixes

async def test_whisper_with_longer_audio():
    """Tester Whisper avec un audio plus long"""
    print("\n" + "="*80)
    print("🧪 TEST WHISPER AVEC AUDIO PLUS LONG")
    print("="*80)
    
    import aiohttp
    import numpy as np
    import wave
    import tempfile
    
    # Générer un audio de test plus long (2 secondes)
    sample_rate = 24000
    duration = 2.0  # secondes
    frequency = 440  # Hz (La 440)
    
    t = np.linspace(0, duration, int(sample_rate * duration))
    audio_data = np.sin(2 * np.pi * frequency * t)
    audio_int16 = (audio_data * 32767).astype(np.int16)
    
    print(f"\n📊 Audio de test généré:")
    print(f"  - Durée: {duration}s")
    print(f"  - Échantillons: {len(audio_int16)}")
    print(f"  - Taux: {sample_rate}Hz")
    
    # Créer un fichier WAV
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
        with wave.open(tmp_file.name, 'wb') as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(audio_int16.tobytes())
        
        # Lire le fichier pour l'envoyer
        with open(tmp_file.name, 'rb') as f:
            wav_data = f.read()
        
        os.unlink(tmp_file.name)
    
    # Tester avec Whisper
    try:
        async with aiohttp.ClientSession() as session:
            form = aiohttp.FormData()
            form.add_field('audio', wav_data, filename='test.wav', content_type='audio/wav')
            form.add_field('language', 'fr')
            
            print("\n🚀 Envoi à Whisper...")
            async with session.post(
                "http://localhost:8001/transcribe",
                data=form,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    print(f"✅ Réponse Whisper: {result}")
                else:
                    print(f"❌ Erreur Whisper: {response.status}")
                    print(await response.text())
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")

def main():
    """Fonction principale"""
    print("\n" + "="*80)
    print("🔍 DIAGNOSTIC DU FLUX AUDIO LIVEKIT")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    
    # 1. Analyser la configuration
    config_issues = analyze_agent_config()
    
    # 2. Générer les recommandations
    fixes = generate_fix_recommendations()
    
    # 3. Tester Whisper avec un audio plus long
    print("\n🧪 Test de Whisper avec audio plus long...")
    asyncio.run(test_whisper_with_longer_audio())
    
    # 4. Résumé
    print("\n" + "="*80)
    print("📋 RÉSUMÉ DU DIAGNOSTIC")
    print("="*80)
    
    print(f"\n❌ {len(config_issues)} problèmes de configuration identifiés")
    print(f"🔧 {len(fixes)} modifications recommandées")
    
    print("\n🎯 ACTIONS PRIORITAIRES:")
    print("1. Réduire l'intervalle de traitement audio à 1 seconde")
    print("2. Augmenter la taille minimale du buffer audio")
    print("3. Vérifier le taux d'échantillonnage des frames LiveKit")
    print("4. Tester avec l'application mobile après les corrections")
    
    print("\n✅ Diagnostic terminé")

if __name__ == "__main__":
    main()