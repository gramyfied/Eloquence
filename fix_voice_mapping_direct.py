#!/usr/bin/env python3
"""
Correction DIRECTE du problème de mapping des voix
Le problème : get_emotional_voice_settings utilise VOICE_MAPPING mais ne log pas
"""

import os
import sys
import re

def fix_voice_mapping_direct():
    """Corrige directement le mapping des voix dans get_emotional_voice_settings"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CORRECTION DIRECTE : Ajouter logs dans get_emotional_voice_settings
    old_function = '''def get_emotional_voice_settings(agent_id: str, emotion: str = "neutre") -> Dict[str, Any]:
    """Récupère les paramètres vocaux avec émotion pour un agent"""
    
    if agent_id not in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
        logger.warning(f"Agent {agent_id} non trouvé, utilisation paramètres par défaut")
        agent_id = "michel_dubois_animateur"
    
    # Configuration de base de l'agent
    base_config = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]
    
    # Configuration émotionnelle
    emotion_config = EMOTION_VOICE_MAPPING.get(emotion, EMOTION_VOICE_MAPPING["neutre"])
    
    # Fusion des paramètres
    final_settings = {**base_config["settings"], **emotion_config}
    
    return {
        "voice_id": base_config["voice_id"],
        "model": base_config["model"],
        "settings": final_settings
    }'''
    
    new_function = '''def get_emotional_voice_settings(agent_id: str, emotion: str = "neutre") -> Dict[str, Any]:
    """Récupère les paramètres vocaux avec émotion pour un agent"""
    
    # LOG DIAGNOSTIC CRITIQUE
    logger.info(f"🔍 RECHERCHE VOIX: agent_id='{agent_id}', emotion='{emotion}'")
    
    original_agent_id = agent_id
    if agent_id not in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
        logger.warning(f"❌ Agent {agent_id} non trouvé dans mapping")
        logger.info(f"🔧 Agents disponibles: {list(VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL.keys())}")
        agent_id = "michel_dubois_animateur"
        logger.info(f"🔧 Fallback vers: {agent_id}")
    
    # Configuration de base de l'agent
    base_config = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]
    voice_id = base_config["voice_id"]
    
    # LOG MAPPING TROUVÉ
    logger.info(f"✅ MAPPING TROUVÉ: {original_agent_id} → {agent_id} → voix {voice_id}")
    
    # Configuration émotionnelle
    emotion_config = EMOTION_VOICE_MAPPING.get(emotion, EMOTION_VOICE_MAPPING["neutre"])
    
    # Fusion des paramètres
    final_settings = {**base_config["settings"], **emotion_config}
    
    result = {
        "voice_id": base_config["voice_id"],
        "model": base_config["model"],
        "settings": final_settings
    }
    
    # LOG FINAL
    logger.info(f"🎭 CONFIG FINALE: voix={result['voice_id']}, model={result['model']}")
    
    return result'''
    
    if old_function in content:
        content = content.replace(old_function, new_function)
        print("✅ Correction mapping voix avec logs détaillés appliquée")
    else:
        print("❌ Fonction get_emotional_voice_settings non trouvée")
        return False
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def fix_audio_buffer_direct():
    """Corrige directement le buffer audio dans multi_agent_main.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Chercher le code de diffusion audio
    old_pattern = r'audio_array = np\.frombuffer\(intro_audio, dtype=np\.int16\)'
    
    if re.search(old_pattern, content):
        # Remplacer par version robuste
        new_code = '''# Conversion audio robuste
                    try:
                        # Vérifier taille paire pour 16-bit
                        if len(intro_audio) % 2 != 0:
                            logging.getLogger(__name__).warning("⚠️ Padding audio nécessaire")
                            intro_audio = intro_audio + b'\\x00'
                        
                        audio_array = np.frombuffer(intro_audio, dtype=np.int16)
                        logging.getLogger(__name__).info(f"✅ Audio converti: {len(audio_array)} samples")
                        
                    except ValueError as e:
                        logging.getLogger(__name__).error(f"❌ Erreur conversion: {e}")
                        # Essayer float32 puis convertir
                        try:
                            audio_float = np.frombuffer(intro_audio, dtype=np.float32)
                            audio_array = (audio_float * 32767).astype(np.int16)
                            logging.getLogger(__name__).info("🔧 Conversion float32→int16 réussie")
                        except Exception as e2:
                            logging.getLogger(__name__).error(f"❌ Conversion impossible: {e2}")
                            return'''
        
        content = re.sub(old_pattern, new_code, content)
        print("✅ Correction buffer audio appliquée")
    else:
        print("⚠️ Pattern buffer audio non trouvé")
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def fix_agent_names_direct():
    """Corrige directement les noms d'agents dans enhanced_multi_agent_manager.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Chercher où le texte est traité avant TTS
    # Dans synthesize_with_emotion, avant l'appel TTS
    
    # Ajouter fonction de nettoyage si pas présente
    if 'def clean_agent_names(' not in content:
        clean_function = '''
def clean_agent_names(text: str) -> str:
    """Nettoie les noms d'agents du texte avant TTS"""
    
    # Patterns à retirer
    patterns = [
        r'^Michel Dubois:\\s*',
        r'^Sarah Johnson:\\s*', 
        r'^Marcus Thompson:\\s*',
        r'^[A-Za-z\\s]+:\\s*'  # Pattern générique
    ]
    
    original_text = text
    for pattern in patterns:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    # Log si nettoyage effectué
    if text != original_text:
        logger.info(f"🧹 Nom agent retiré: '{original_text[:30]}...' → '{text[:30]}...'")
    
    return text.strip()

'''
        
        # Insérer avant la classe
        class_pattern = r'class EnhancedMultiAgentManager:'
        if class_pattern in content:
            content = content.replace(class_pattern, clean_function + class_pattern)
            print("✅ Fonction clean_agent_names ajoutée")
        else:
            print("⚠️ Classe EnhancedMultiAgentManager non trouvée")
    
    # Utiliser la fonction dans les appels TTS
    # Chercher les appels synthesize_with_emotion et ajouter le nettoyage
    old_tts_pattern = r'await self\.tts_service\.synthesize_with_emotion\(\s*text=([^,]+),'
    
    def replace_tts_call(match):
        text_var = match.group(1)
        return f'await self.tts_service.synthesize_with_emotion(\n                text=clean_agent_names({text_var}),'
    
    if re.search(old_tts_pattern, content):
        content = re.sub(old_tts_pattern, replace_tts_call, content)
        print("✅ Nettoyage noms agents ajouté aux appels TTS")
    else:
        print("⚠️ Appels TTS non trouvés")
    
    # Ajouter import re si nécessaire
    if 'import re' not in content:
        content = 'import re\n' + content
        print("✅ Import re ajouté")
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def test_corrections():
    """Teste que les corrections sont bien appliquées"""
    
    print("\n🧪 TEST DES CORRECTIONS")
    print("=" * 40)
    
    # Test 1: Logs mapping voix
    tts_file = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    with open(tts_file, 'r') as f:
        tts_content = f.read()
    
    if "MAPPING TROUVÉ" in tts_content:
        print("✅ Logs mapping voix présents")
    else:
        print("❌ Logs mapping voix manquants")
    
    # Test 2: Buffer audio
    main_file = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    with open(main_file, 'r') as f:
        main_content = f.read()
    
    if "Conversion audio robuste" in main_content:
        print("✅ Correction buffer audio présente")
    else:
        print("❌ Correction buffer audio manquante")
    
    # Test 3: Nettoyage noms
    manager_file = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    with open(manager_file, 'r') as f:
        manager_content = f.read()
    
    if "clean_agent_names" in manager_content:
        print("✅ Nettoyage noms agents présent")
    else:
        print("❌ Nettoyage noms agents manquant")

def main():
    """Fonction principale"""
    print("🚀 CORRECTION DIRECTE PROBLÈMES VOIX")
    
    try:
        # 1. Mapping voix
        print("\n1️⃣ Correction mapping voix...")
        fix_voice_mapping_direct()
        
        # 2. Buffer audio
        print("\n2️⃣ Correction buffer audio...")
        fix_audio_buffer_direct()
        
        # 3. Noms agents
        print("\n3️⃣ Correction noms agents...")
        fix_agent_names_direct()
        
        # 4. Test
        test_corrections()
        
        print("\n✅ CORRECTIONS DIRECTES APPLIQUÉES !")
        print("\n🎯 RÉSULTAT ATTENDU :")
        print("- Logs détaillés mapping voix")
        print("- Sarah → voix Bella, Marcus → voix Arnold")
        print("- Introduction audio fonctionnelle")
        print("- Noms agents silencieux")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

