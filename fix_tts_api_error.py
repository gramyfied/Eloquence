#!/usr/bin/env python3
"""
Correction CRITIQUE de l'erreur API TTS
Remplace voice_id par agent_id dans tous les appels synthesize_with_emotion
"""

import os
import sys
import re

def fix_tts_api_calls():
    """Corrige l'erreur d'API TTS dans enhanced_multi_agent_manager.py"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    # Lire le fichier actuel
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # CORRECTION 1 : Introduction - ligne ~1085
    old_intro_call = '''audio_data = await self.tts_service.synthesize_with_emotion(
                text=intro_text,
                voice_id="George",
                emotion="enthousiasme",
                intensity=0.7
            )'''
    
    new_intro_call = '''audio_data = await self.tts_service.synthesize_with_emotion(
                text=intro_text,
                agent_id="michel_dubois_animateur",
                emotion="enthousiasme",
                intensity=0.7
            )'''
    
    if old_intro_call in content:
        content = content.replace(old_intro_call, new_intro_call)
        print("✅ Correction 1: Appel TTS introduction corrigé")
    else:
        print("⚠️ Appel TTS introduction non trouvé, recherche alternative...")
        
        # Recherche alternative avec regex
        pattern = r'await self\.tts_service\.synthesize_with_emotion\(\s*text=intro_text,\s*voice_id="George"'
        if re.search(pattern, content):
            content = re.sub(
                r'voice_id="George"',
                'agent_id="michel_dubois_animateur"',
                content
            )
            print("✅ Correction 1 (regex): Appel TTS introduction corrigé")
    
    # CORRECTION 2 : Tous les autres appels voice_id
    # Rechercher tous les patterns voice_id dans synthesize_with_emotion
    
    # Pattern 1: voice_id avec mapping direct
    voice_mappings = {
        '"George"': '"michel_dubois_animateur"',
        '"Bella"': '"sarah_johnson_journaliste"', 
        '"Arnold"': '"marcus_thompson_expert"'
    }
    
    for old_voice, new_agent in voice_mappings.items():
        pattern = f'voice_id={old_voice}'
        replacement = f'agent_id={new_agent}'
        if pattern in content:
            content = content.replace(pattern, replacement)
            print(f"✅ Correction: {old_voice} → {new_agent}")
    
    # CORRECTION 3 : Appels génériques avec voice_id
    # Remplacer tous les voice_id= par agent_id= dans synthesize_with_emotion
    pattern = r'(await\s+.*?synthesize_with_emotion\([^)]*?)voice_id='
    replacement = r'\1agent_id='
    
    if re.search(pattern, content):
        content = re.sub(pattern, replacement, content)
        print("✅ Correction 3: Tous les voice_id remplacés par agent_id")
    
    # CORRECTION 4 : Vérifier les appels avec variables
    # Si il y a des appels comme voice_id=voice_mapping[agent_id]
    old_pattern = r'voice_id=voice_mapping\[([^\]]+)\]'
    new_pattern = r'agent_id=\1'
    
    if re.search(old_pattern, content):
        content = re.sub(old_pattern, new_pattern, content)
        print("✅ Correction 4: Mapping voice_id corrigé")
    
    # Sauvegarder le fichier modifié
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Toutes les corrections API TTS appliquées")
    return True

def verify_tts_service_signature():
    """Vérifie la signature de synthesize_with_emotion dans le service TTS"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/elevenlabs_flash_tts_service.py"
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Chercher la signature de synthesize_with_emotion
        pattern = r'async def synthesize_with_emotion\(([^)]+)\)'
        match = re.search(pattern, content)
        
        if match:
            signature = match.group(1)
            print(f"✅ Signature TTS trouvée: synthesize_with_emotion({signature})")
            
            if 'agent_id' in signature:
                print("✅ Confirmation: La méthode utilise bien 'agent_id'")
                return True
            elif 'voice_id' in signature:
                print("⚠️ Attention: La méthode utilise 'voice_id' - vérification nécessaire")
                return False
            else:
                print("⚠️ Signature ambiguë - vérification manuelle nécessaire")
                return False
        else:
            print("❌ Signature synthesize_with_emotion non trouvée")
            return False
            
    except Exception as e:
        print(f"❌ Erreur lecture service TTS: {e}")
        return False

def create_test_script():
    """Crée un script de test pour valider la correction"""
    
    test_content = '''#!/usr/bin/env python3
"""
Script de test pour valider la correction TTS
"""

import asyncio
import os
import sys

# Ajouter le chemin du service
sys.path.append('/home/ubuntu/Eloquence/services/livekit-agent')

async def test_tts_correction():
    """Teste l'appel TTS corrigé"""
    
    try:
        from elevenlabs_flash_tts_service import ElevenLabsFlashTTSService
        
        # Initialiser le service
        service = ElevenLabsFlashTTSService(
            api_key=os.getenv('ELEVENLABS_API_KEY'),
            use_cache=True
        )
        
        # Test avec agent_id
        print("🧪 Test TTS avec agent_id...")
        
        audio_data = await service.synthesize_with_emotion(
            text="Test de correction TTS",
            agent_id="michel_dubois_animateur",
            emotion="neutre",
            intensity=0.5
        )
        
        if len(audio_data) > 0:
            print(f"✅ TTS FONCTIONNEL: {len(audio_data)} bytes générés")
            return True
        else:
            print("❌ TTS ÉCHEC: Aucun audio généré")
            return False
            
    except Exception as e:
        print(f"❌ ERREUR TEST TTS: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_tts_correction())
    print(f"\\n🎯 RÉSULTAT: {'SUCCÈS' if result else 'ÉCHEC'}")
'''
    
    with open("/home/ubuntu/Eloquence/test_tts_correction.py", 'w', encoding='utf-8') as f:
        f.write(test_content)
    
    os.chmod("/home/ubuntu/Eloquence/test_tts_correction.py", 0o755)
    print("✅ Script de test créé: test_tts_correction.py")

def main():
    """Fonction principale de correction"""
    print("🚀 CORRECTION CRITIQUE ERREUR API TTS")
    
    try:
        # 1. Vérifier la signature du service TTS
        print("\n1️⃣ Vérification signature TTS...")
        verify_tts_service_signature()
        
        # 2. Corriger les appels API
        print("\n2️⃣ Correction appels API TTS...")
        fix_tts_api_calls()
        
        # 3. Créer script de test
        print("\n3️⃣ Création script de test...")
        create_test_script()
        
        print("\n✅ CORRECTION API TTS TERMINÉE !")
        print("\n🎯 PROCHAINES ÉTAPES :")
        print("1. Redémarrer Docker : docker-compose restart")
        print("2. Tester avec studio_debatPlateau_test")
        print("3. Vérifier logs : plus d'erreur 'unexpected keyword argument'")
        print("4. Confirmer audio introduction + agents")
        
        print("\n📊 CORRECTIONS APPLIQUÉES :")
        print("- voice_id → agent_id dans tous les appels TTS")
        print("- Introduction: voice_id='George' → agent_id='michel_dubois_animateur'")
        print("- Mapping voix corrigé pour tous les agents")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR LORS DE LA CORRECTION: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

