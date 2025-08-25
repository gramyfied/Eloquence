#!/usr/bin/env python3
"""
Script de correction pour intégrer le TTS ElevenLabs dans enhanced_multi_agent_manager.py
Remplace la simulation audio par de vrais appels ElevenLabs
"""

import os
import re

def fix_tts_integration():
    """Corrige l'intégration TTS dans enhanced_multi_agent_manager.py"""
    
    file_path = "services/livekit-agent/enhanced_multi_agent_manager.py"
    
    print("🔧 CORRECTION TTS ELEVENLABS")
    print("="*50)
    
    # Lire le fichier
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Ajouter l'import ElevenLabs TTS service
    import_fix = '''"""
Gestionnaire multi-agents révolutionnaire avec GPT-4o + ElevenLabs v2.5
Intègre naturalité maximale et émotions vocales pour Eloquence
"""
import asyncio
import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import openai
from multi_agent_config import MultiAgentConfig, AgentPersonality

# ✅ IMPORT TTS ELEVENLABS
try:
    from elevenlabs_flash_tts_service import ElevenLabsFlashTTSService
    TTS_AVAILABLE = True
    print("✅ ElevenLabs TTS Service importé avec succès")
except ImportError as e:
    print(f"❌ Erreur import ElevenLabs TTS: {e}")
    TTS_AVAILABLE = False

logger = logging.getLogger(__name__)'''
    
    # Remplacer les imports
    content = re.sub(
        r'"""[\s\S]*?logger = logging\.getLogger\(__name__\)',
        import_fix + '\n\nlogger = logging.getLogger(__name__)',
        content,
        count=1
    )
    
    # 2. Ajouter l'initialisation TTS dans __init__
    init_fix = '''    def __init__(self, openai_api_key: str, elevenlabs_api_key: str, config: MultiAgentConfig):
        self.openai_client = openai.OpenAI(api_key=openai_api_key)
        self.elevenlabs_api_key = elevenlabs_api_key
        self.config = config
        
        # ✅ INITIALISATION TTS ELEVENLABS
        if TTS_AVAILABLE:
            try:
                self.tts_service = ElevenLabsFlashTTSService(elevenlabs_api_key)
                logger.info("✅ ElevenLabs TTS Service initialisé")
            except Exception as e:
                logger.error(f"❌ Erreur initialisation TTS: {e}")
                self.tts_service = None
        else:
            logger.warning("⚠️ TTS Service non disponible")
            self.tts_service = None
        
        # Agents avec prompts révolutionnaires français
        self.agents = self._initialize_revolutionary_agents()
        
        # Système anti-répétition intelligent
        self.conversation_memory = {}
        self.last_responses = {}
        
        # Système d'émotions vocales
        self.emotional_states = {}
        
        # Contexte utilisateur par défaut
        self.user_context = {
            'user_name': 'Participant',
            'user_subject': 'votre présentation'
        }
        
        # NOUVEAU : Système d'interpellation intelligente'''
    
    # Remplacer l'initialisation
    content = re.sub(
        r'def __init__\(self, openai_api_key: str, elevenlabs_api_key: str, config: MultiAgentConfig\):[\s\S]*?# NOUVEAU : Système d\'interpellation intelligente',
        init_fix,
        content,
        count=1
    )
    
    # 3. Corriger la fonction generate_complete_agent_response
    tts_fix = '''    async def generate_complete_agent_response(self, agent_id: str, user_message: str, session_id: str) -> Tuple[str, bytes, Dict]:
        """Génère une réponse complète avec texte et audio pour l'agent"""
        try:
            # Générer la réponse texte
            response, emotion = await self.generate_agent_response(
                agent_id, 
                f"Session: {session_id}", 
                user_message, 
                []
            )
            
            # ✅ GÉNÉRATION AUDIO RÉELLE AVEC ELEVENLABS
            audio_data = b""
            if self.tts_service and response:
                try:
                    # Sélection de la voix selon l'agent
                    voice_mapping = {
                        'michel_dubois_animateur': 'George',  # Voix masculine neutre
                        'sarah_johnson_journaliste': 'Bella',  # Voix féminine neutre
                        'marcus_thompson_expert': 'Arnold'     # Voix masculine mesurée
                    }
                    
                    voice_id = voice_mapping.get(agent_id, 'George')
                    
                    # Génération audio avec émotion
                    audio_data = await self.tts_service.synthesize_with_emotion(
                        text=response,
                        voice_id=voice_id,
                        emotion=emotion.primary_emotion,
                        intensity=emotion.intensity
                    )
                    
                    logger.info(f"✅ Audio généré pour {agent_id}: {len(audio_data)} bytes")
                    
                except Exception as e:
                    logger.error(f"❌ Erreur génération audio TTS: {e}")
                    audio_data = b""
            else:
                logger.warning("⚠️ TTS Service non disponible, pas d'audio généré")
            
            # Contexte de la réponse
            context = {
                "agent_id": agent_id,
                "emotion": emotion.primary_emotion,
                "intensity": emotion.intensity,
                "session_id": session_id,
                "audio_generated": len(audio_data) > 0
            }
            
            return response, audio_data, context
            
        except Exception as e:
            logger.error(f"❌ Erreur génération réponse complète: {e}")
            return "Erreur système", b"", {}'''
    
    # Remplacer la fonction TTS
    content = re.sub(
        r'async def generate_complete_agent_response\(self, agent_id: str, user_message: str, session_id: str\) -> Tuple\[str, bytes, Dict\]:[\s\S]*?return "Erreur système", b"", \{\}',
        tts_fix,
        content,
        count=1
    )
    
    # 4. Ajouter une méthode pour tester le TTS
    test_method = '''
    async def test_tts_integration(self) -> bool:
        """Teste l'intégration TTS ElevenLabs"""
        if not self.tts_service:
            logger.error("❌ TTS Service non initialisé")
            return False
        
        try:
            # Test simple
            test_audio = await self.tts_service.synthesize_with_emotion(
                text="Test de connexion ElevenLabs",
                voice_id="George",
                emotion="neutre",
                intensity=0.5
            )
            
            if len(test_audio) > 0:
                logger.info("✅ Test TTS réussi")
                return True
            else:
                logger.error("❌ Test TTS échoué: audio vide")
                return False
                
        except Exception as e:
            logger.error(f"❌ Test TTS échoué: {e}")
            return False
'''
    
    # Ajouter la méthode de test avant la dernière fonction
    content = content.replace(
        'def get_enhanced_manager(openai_api_key: str, elevenlabs_api_key: str,',
        test_method + '\n\ndef get_enhanced_manager(openai_api_key: str, elevenlabs_api_key: str,'
    )
    
    # Sauvegarder le fichier corrigé
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Corrections TTS appliquées avec succès")
    print("📋 Corrections effectuées:")
    print("   - Import ElevenLabsFlashTTSService")
    print("   - Initialisation TTS dans __init__")
    print("   - Remplacement simulation audio par vrais appels TTS")
    print("   - Mapping voix neutres (George/Bella/Arnold)")
    print("   - Méthode de test TTS")
    
    return True

if __name__ == "__main__":
    try:
        fix_tts_integration()
        print("\n🚀 CORRECTION TTS TERMINÉE AVEC SUCCÈS !")
        print("🎯 Redémarrez les services Docker pour appliquer les changements")
    except Exception as e:
        print(f"\n❌ ERREUR: {e}")

