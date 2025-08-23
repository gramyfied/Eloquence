#!/usr/bin/env python3
"""
Correction SIMPLE pour les logs TTS dans elevenlabs_flash_tts_service.py
Ajoute seulement des logs sans modifier la logique
"""

import os
import sys

def add_tts_logs_in_service():
    """Ajoute des logs dans elevenlabs_flash_tts_service.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    
    # Lire le fichier actuel
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Chercher la méthode _call_elevenlabs_api et ajouter des logs
    old_api_call = '''async def _call_elevenlabs_api(self, text: str, voice_id: str, settings: Dict[str, Any]) -> bytes:
        """Appel API ElevenLabs avec paramètres personnalisés"""
        
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"'''
    
    new_api_call = '''async def _call_elevenlabs_api(self, text: str, voice_id: str, settings: Dict[str, Any]) -> bytes:
        """Appel API ElevenLabs avec paramètres personnalisés"""
        
        # LOGS AJOUTÉS POUR DIAGNOSTIC
        logger.info(f"🌐 APPEL TTS: voix {voice_id} - {text[:30]}...")
        
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"'''
    
    if old_api_call in content:
        content = content.replace(old_api_call, new_api_call)
        print("✅ Logs TTS ajoutés dans _call_elevenlabs_api")
    else:
        print("⚠️ Méthode _call_elevenlabs_api non trouvée")
    
    # Ajouter aussi un log dans synthesize_with_emotion
    old_synthesize = '''async def synthesize_with_emotion(self, text: str, agent_id: str, 
                                     emotion: str = "neutre", intensity: float = 0.5) -> bytes:
        """Synthèse vocale avec émotion ElevenLabs v2.5 - ÉMOTIONS SILENCIEUSES"""
        
        try:'''
    
    new_synthesize = '''async def synthesize_with_emotion(self, text: str, agent_id: str, 
                                     emotion: str = "neutre", intensity: float = 0.5) -> bytes:
        """Synthèse vocale avec émotion ElevenLabs v2.5 - ÉMOTIONS SILENCIEUSES"""
        
        # LOG DIAGNOSTIC AJOUTÉ
        logger.info(f"🎵 TTS DÉBUT: {agent_id} - {emotion} - {text[:30]}...")
        
        try:'''
    
    if old_synthesize in content:
        content = content.replace(old_synthesize, new_synthesize)
        print("✅ Logs TTS ajoutés dans synthesize_with_emotion")
    else:
        print("⚠️ Méthode synthesize_with_emotion non trouvée")
    
    # Sauvegarder le fichier modifié
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Logs TTS service appliqués")
    return True

def main():
    """Fonction principale"""
    print("🚀 AJOUT LOGS TTS SIMPLES")
    
    try:
        add_tts_logs_in_service()
        
        print("\n✅ LOGS TTS AJOUTÉS !")
        print("🎯 Maintenant vous verrez dans les logs :")
        print("- 🎵 TTS DÉBUT: agent_id - émotion - texte...")
        print("- 🌐 APPEL TTS: voix voice_id - texte...")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

