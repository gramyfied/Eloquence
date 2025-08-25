#!/usr/bin/env python3
"""
Script de validation finale de toutes les corrections Eloquence
"""
import asyncio
import logging
import os
import sys
from typing import List, Tuple

# Configuration logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Ajout du chemin pour imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def validate_correction_1_emotions_silencieuses() -> Tuple[bool, str]:
    """Valide que les émotions sont silencieuses"""
    try:
        from elevenlabs_flash_tts_service import apply_emotional_preprocessing, validate_emotion_silence
        
        # Test suppression marqueurs
        test_text = "*avec enthousiasme* Bonjour ! *de manière réfléchie* Que pensez-vous ?"
        cleaned = apply_emotional_preprocessing(test_text, "enthousiasme", 0.8)
        
        if not validate_emotion_silence(cleaned):
            return False, "Marqueurs émotionnels encore présents"
        
        if "*" in cleaned:
            return False, "Astérisques non supprimées"
        
        return True, "Émotions silencieuses validées"
        
    except Exception as e:
        return False, f"Erreur validation émotions: {e}"

async def validate_correction_2_michel_actif() -> Tuple[bool, str]:
    """Valide que Michel est un animateur actif"""
    try:
        from enhanced_multi_agent_manager import get_enhanced_manager
        from multi_agent_config import MultiAgentConfig
        
        config = MultiAgentConfig("test", "test", [], {}, "test")
        manager = get_enhanced_manager("test", "test", config)
        
        michel_prompt = manager.agents["michel_dubois_animateur"]["system_prompt"]
        
        # Vérifications rôle actif
        if "MÈNES LE DÉBAT" not in michel_prompt and "MÈNE LE DÉBAT" not in michel_prompt:
            return False, "Michel n'est pas configuré pour mener le débat"
        
        # Vérification que l'interdiction est présente (pas le comportement)
        if "Ne dis JAMAIS \"Je suis là pour vous écouter\"" not in michel_prompt:
            return False, "Interdiction passive manquante dans le prompt"
        
        # Test validation rôle
        passive_response = "Je suis là pour vous écouter"
        if manager._validate_michel_active_role(passive_response):
            return False, "Validation rôle actif défaillante"
        
        return True, "Michel animateur actif validé"
        
    except Exception as e:
        return False, f"Erreur validation Michel actif: {e}"

async def validate_correction_3_contexte_utilisateur() -> Tuple[bool, str]:
    """Valide l'intégration du contexte utilisateur"""
    try:
        from enhanced_multi_agent_manager import get_enhanced_manager
        from multi_agent_config import MultiAgentConfig
        
        config = MultiAgentConfig("test", "test", [], {}, "test")
        manager = get_enhanced_manager("test", "test", config)
        
        # Configuration contexte
        manager.set_user_context("TestUser", "Test Subject")
        
        # Vérification intégration
        context = manager.get_user_context()
        if context['user_name'] != "TestUser":
            return False, "Nom utilisateur non configuré"
        
        # Vérification prompts
        michel_prompt = manager.agents["michel_dubois_animateur"]["system_prompt"]
        if "TestUser" not in michel_prompt:
            return False, "Nom utilisateur non intégré dans prompt"
        
        return True, "Contexte utilisateur validé"
        
    except Exception as e:
        return False, f"Erreur validation contexte: {e}"

async def validate_correction_4_integration_main() -> Tuple[bool, str]:
    """Valide l'intégration dans multi_agent_main"""
    try:
        from multi_agent_main import MultiAgentLiveKitService
        from multi_agent_config import ExerciseTemplates
        
        user_data = {'user_name': 'TestUser', 'user_subject': 'Test Subject'}
        config = ExerciseTemplates.get_studio_debate_tv_config()
        
        service = MultiAgentLiveKitService(config, user_data)
        
        # Vérifications
        if service.user_data['user_name'] != 'Testuser':  # Normalisé par title()
            return False, "User_data non transmises au service"
        
        if hasattr(service.manager, 'get_user_context'):
            context = service.manager.get_user_context()
            if context['user_name'] != 'Testuser':  # Normalisé par title()
                return False, "Contexte non transmis au manager"
        
        return True, "Intégration main validée"
        
    except Exception as e:
        return False, f"Erreur validation intégration main: {e}"

async def validate_correction_5_voix_neutres() -> Tuple[bool, str]:
    """Valide les voix neutres sans accent"""
    try:
        from elevenlabs_flash_tts_service import VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL
        
        expected_voices = {
            "michel_dubois_animateur": "JBFqnCBsd6RMkjVDRZzb",  # George
            "sarah_johnson_journaliste": "EXAVITQu4vr4xnSDxMaL",  # Bella
            "marcus_thompson_expert": "VR6AewLTigWG4xSOukaG"   # Arnold
        }
        
        for agent_id, expected_voice in expected_voices.items():
            if agent_id not in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
                return False, f"Agent {agent_id} non configuré"
            
            actual_voice = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]["voice_id"]
            if actual_voice != expected_voice:
                return False, f"Voix incorrecte pour {agent_id}: {actual_voice} != {expected_voice}"
        
        return True, "Voix neutres validées"
        
    except Exception as e:
        return False, f"Erreur validation voix neutres: {e}"

async def run_all_validations() -> None:
    """Exécute toutes les validations"""
    
    logger.info("🚀 DÉMARRAGE VALIDATION FINALE ELOQUENCE")
    logger.info("=" * 60)
    
    validations = [
        ("CORRECTION 1: Émotions Silencieuses", validate_correction_1_emotions_silencieuses),
        ("CORRECTION 2: Michel Animateur Actif", validate_correction_2_michel_actif),
        ("CORRECTION 3: Contexte Utilisateur", validate_correction_3_contexte_utilisateur),
        ("CORRECTION 4: Intégration Main", validate_correction_4_integration_main),
        ("CORRECTION 5: Voix Neutres", validate_correction_5_voix_neutres)
    ]
    
    results = []
    
    for name, validation_func in validations:
        logger.info(f"🔍 Validation: {name}")
        
        try:
            success, message = await validation_func()
            
            if success:
                logger.info(f"✅ {name}: {message}")
                results.append((name, True, message))
            else:
                logger.error(f"❌ {name}: {message}")
                results.append((name, False, message))
                
        except Exception as e:
            logger.error(f"💥 {name}: Erreur critique - {e}")
            results.append((name, False, f"Erreur critique: {e}"))
        
        logger.info("-" * 40)
    
    # Résumé final
    logger.info("🎯 RÉSUMÉ VALIDATION FINALE")
    logger.info("=" * 60)
    
    success_count = sum(1 for _, success, _ in results if success)
    total_count = len(results)
    
    for name, success, message in results:
        status = "✅ PASSÉ" if success else "❌ ÉCHEC"
        logger.info(f"{status}: {name}")
        if not success:
            logger.info(f"   Détail: {message}")
    
    logger.info("-" * 60)
    logger.info(f"📊 SCORE FINAL: {success_count}/{total_count} corrections validées")
    
    if success_count == total_count:
        logger.info("🎉 TOUTES LES CORRECTIONS SONT VALIDÉES !")
        logger.info("🚀 ELOQUENCE EST PRÊT POUR PRODUCTION !")
    else:
        logger.error(f"⚠️ {total_count - success_count} correction(s) à corriger")
        logger.error("🔧 Veuillez corriger les problèmes avant mise en production")
    
    return success_count == total_count

if __name__ == "__main__":
    asyncio.run(run_all_validations())
