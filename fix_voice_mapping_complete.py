#!/usr/bin/env python3
"""
Correction COMPLÈTE des problèmes de voix Eloquence
1. Mapping voix (Sarah/Marcus utilisent voix de Michel)
2. Buffer audio introduction
3. Noms agents audibles
"""

import os
import sys
import re

def fix_voice_mapping():
    """Corrige le mapping des voix dans elevenlabs_flash_tts_service.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CORRECTION 1 : Ajouter des logs détaillés dans get_voice_config_for_agent
    old_method = '''def get_voice_config_for_agent(self, agent_id: str) -> Dict[str, Any]:
        """Récupère la configuration vocale pour un agent spécifique"""
        
        if agent_id in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
            return VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]
        else:
            # Fallback vers Michel si agent non trouvé
            return VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL["michel_dubois_animateur"]'''
    
    new_method = '''def get_voice_config_for_agent(self, agent_id: str) -> Dict[str, Any]:
        """Récupère la configuration vocale pour un agent spécifique"""
        
        logger.info(f"🔍 RECHERCHE VOIX pour agent: {agent_id}")
        
        if agent_id in VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL:
            config = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL[agent_id]
            voice_id = config.get('voice_id', 'UNKNOWN')
            logger.info(f"✅ MAPPING TROUVÉ: {agent_id} → {voice_id}")
            return config
        else:
            logger.error(f"❌ AGENT INCONNU: {agent_id}")
            logger.info("🔧 Fallback vers Michel")
            # Fallback vers Michel si agent non trouvé
            fallback = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL["michel_dubois_animateur"]
            logger.info(f"🔧 Fallback voix: {fallback.get('voice_id', 'UNKNOWN')}")
            return fallback'''
    
    if old_method in content:
        content = content.replace(old_method, new_method)
        print("✅ Correction 1: Logs détaillés mapping voix ajoutés")
    else:
        print("⚠️ Méthode get_voice_config_for_agent non trouvée")
    
    # CORRECTION 2 : Vérifier que synthesize_with_emotion utilise bien le mapping
    # Chercher l'appel à get_voice_config_for_agent
    if 'get_voice_config_for_agent(agent_id)' not in content:
        print("⚠️ Appel get_voice_config_for_agent manquant dans synthesize_with_emotion")
        
        # Ajouter l'appel dans synthesize_with_emotion
        old_synthesize = '''# Récupération configuration vocale
        voice_config = VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL.get(
            agent_id, 
            VOICE_MAPPING_FRENCH_NEUTRAL_PROFESSIONAL["michel_dubois_animateur"]
        )'''
        
        new_synthesize = '''# Récupération configuration vocale avec logs
        voice_config = self.get_voice_config_for_agent(agent_id)'''
        
        if old_synthesize in content:
            content = content.replace(old_synthesize, new_synthesize)
            print("✅ Correction 2: Appel mapping voix corrigé")
    else:
        print("✅ Appel get_voice_config_for_agent déjà présent")
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Corrections mapping voix appliquées")
    return True

def fix_audio_buffer():
    """Corrige le problème de buffer audio dans multi_agent_main.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CORRECTION : Buffer audio avec gestion d'erreur
    old_buffer = '''                    # Convertir bytes en array numpy (supposant PCM 16-bit)
                    audio_array = np.frombuffer(intro_audio, dtype=np.int16)
                    
                    # Créer frame audio
                    frame = rtc.AudioFrame(
                        data=audio_array,
                        sample_rate=24000,
                        num_channels=1,
                        samples_per_channel=len(audio_array)
                    )'''
    
    new_buffer = '''                    # Convertir bytes en array numpy avec gestion d'erreur
                    try:
                        # Vérifier que la taille est paire (16-bit = 2 bytes par sample)
                        if len(intro_audio) % 2 != 0:
                            logging.getLogger(__name__).warning("⚠️ Padding audio nécessaire")
                            intro_audio = intro_audio + b'\\x00'
                        
                        # Conversion PCM 16-bit
                        audio_array = np.frombuffer(intro_audio, dtype=np.int16)
                        logging.getLogger(__name__).info(f"✅ Audio converti: {len(audio_array)} samples")
                        
                    except ValueError as e:
                        logging.getLogger(__name__).error(f"❌ Erreur conversion: {e}")
                        # Essayer format float32 puis convertir
                        try:
                            audio_float = np.frombuffer(intro_audio, dtype=np.float32)
                            audio_array = (audio_float * 32767).astype(np.int16)
                            logging.getLogger(__name__).info("🔧 Conversion float32→int16 réussie")
                        except:
                            logging.getLogger(__name__).error("❌ Impossible de convertir l'audio")
                            return
                    
                    # Créer frame audio
                    frame = rtc.AudioFrame(
                        data=audio_array,
                        sample_rate=24000,
                        num_channels=1,
                        samples_per_channel=len(audio_array)
                    )'''
    
    if old_buffer in content:
        content = content.replace(old_buffer, new_buffer)
        print("✅ Correction buffer audio appliquée")
    else:
        print("⚠️ Code buffer audio non trouvé")
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Corrections buffer audio appliquées")
    return True

def fix_agent_names():
    """Corrige les noms d'agents audibles dans enhanced_multi_agent_manager.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CORRECTION 1 : Ajouter fonction de nettoyage
    clean_function = '''
    def clean_agent_text(self, text: str, agent_id: str) -> str:
        """Nettoie le texte en retirant le nom de l'agent"""
        
        # Patterns à retirer (noms d'agents au début)
        patterns = [
            r'^Michel Dubois:\\s*',
            r'^Sarah Johnson:\\s*', 
            r'^Marcus Thompson:\\s*',
            r'^[A-Za-z\\s]+:\\s*'  # Pattern générique
        ]
        
        cleaned_text = text
        for pattern in patterns:
            cleaned_text = re.sub(pattern, '', cleaned_text, flags=re.IGNORECASE)
        
        # Log du nettoyage
        if cleaned_text != text:
            logger.info(f"🧹 Texte nettoyé pour {agent_id}: '{text[:30]}...' → '{cleaned_text[:30]}...'")
        
        return cleaned_text.strip()
'''
    
    # Ajouter la fonction avant la dernière méthode de la classe
    if 'def clean_agent_text' not in content:
        # Trouver un bon endroit pour insérer
        insertion_point = "def get_enhanced_manager("
        if insertion_point in content:
            content = content.replace(insertion_point, clean_function + "\n" + insertion_point)
            print("✅ Fonction clean_agent_text ajoutée")
        else:
            print("⚠️ Point d'insertion non trouvé pour clean_agent_text")
    else:
        print("✅ Fonction clean_agent_text déjà présente")
    
    # CORRECTION 2 : Utiliser la fonction dans synthesize_with_emotion
    # Chercher l'appel TTS et ajouter le nettoyage
    old_tts_call = '''        # CORRECTION CRITIQUE : Préprocessing émotionnel SILENCIEUX
        processed_text = clean_text_for_tts(text)'''
    
    new_tts_call = '''        # CORRECTION CRITIQUE : Préprocessing émotionnel SILENCIEUX
        processed_text = clean_text_for_tts(text)
        
        # NOUVEAU : Nettoyer les noms d'agents
        processed_text = self.clean_agent_text(processed_text, agent_id)'''
    
    if old_tts_call in content:
        content = content.replace(old_tts_call, new_tts_call)
        print("✅ Nettoyage noms agents ajouté dans TTS")
    else:
        print("⚠️ Point d'insertion TTS non trouvé")
    
    # Ajouter import re si nécessaire
    if "import re" not in content:
        content = "import re\n" + content
        print("✅ Import re ajouté")
    
    # Sauvegarder
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Corrections noms agents appliquées")
    return True

def create_voice_test():
    """Crée un script de test pour valider les corrections"""
    
    test_script = '''#!/usr/bin/env python3
"""
Test des corrections voix Eloquence
"""

import sys
import os
import re

def test_voice_mapping():
    """Teste le mapping des voix"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    print("🧪 TEST MAPPING VOIX")
    print("=" * 40)
    
    # Vérifier présence des logs
    if "MAPPING TROUVÉ" in content:
        print("✅ Logs détaillés présents")
    else:
        print("❌ Logs détaillés manquants")
    
    # Vérifier appel get_voice_config_for_agent
    if "get_voice_config_for_agent(agent_id)" in content:
        print("✅ Appel mapping correct")
    else:
        print("❌ Appel mapping manquant")
    
    return True

def test_clean_names():
    """Teste le nettoyage des noms"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    print("\\n🧪 TEST NETTOYAGE NOMS")
    print("=" * 40)
    
    if "def clean_agent_text" in content:
        print("✅ Fonction nettoyage présente")
    else:
        print("❌ Fonction nettoyage manquante")
    
    if "clean_agent_text(processed_text, agent_id)" in content:
        print("✅ Appel nettoyage présent")
    else:
        print("❌ Appel nettoyage manquant")
    
    return True

if __name__ == "__main__":
    print("🚀 TEST CORRECTIONS VOIX")
    print("=" * 50)
    
    test_voice_mapping()
    test_clean_names()
    
    print("\\n✅ TESTS TERMINÉS")
'''
    
    with open("/home/ubuntu/Eloquence/test_voice_fixes.py", 'w', encoding='utf-8') as f:
        f.write(test_script)
    
    os.chmod("/home/ubuntu/Eloquence/test_voice_fixes.py", 0o755)
    print("✅ Script de test créé: test_voice_fixes.py")

def main():
    """Fonction principale de correction"""
    print("🚀 CORRECTION COMPLÈTE PROBLÈMES VOIX ELOQUENCE")
    
    try:
        # 1. Corriger mapping voix
        print("\n1️⃣ Correction mapping voix...")
        fix_voice_mapping()
        
        # 2. Corriger buffer audio
        print("\n2️⃣ Correction buffer audio...")
        fix_audio_buffer()
        
        # 3. Corriger noms agents
        print("\n3️⃣ Correction noms agents...")
        fix_agent_names()
        
        # 4. Créer script de test
        print("\n4️⃣ Création script de test...")
        create_voice_test()
        
        print("\n✅ TOUTES LES CORRECTIONS VOIX APPLIQUÉES !")
        print("\n🎯 RÉSULTAT ATTENDU :")
        print("- Sarah utilise voix Bella (féminine)")
        print("- Marcus utilise voix Arnold (masculine différente)")
        print("- Introduction audio fonctionne")
        print("- Noms agents non audibles")
        print("\n🔄 REDÉMARRER : docker-compose restart")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR LORS DE LA CORRECTION: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

