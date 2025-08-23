#!/usr/bin/env python3
"""
Correction SIMPLE et CIBLÉE pour l'introduction d'Eloquence
Ajoute seulement l'appel à generate_introduction sans casser le flux existant
"""

import os
import sys

def fix_introduction_call():
    """Ajoute l'appel à generate_introduction dans multi_agent_main.py de façon minimale"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/multi_agent_main.py"
    
    # Lire le fichier actuel
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Chercher le point d'insertion après la connexion LiveKit
    insertion_point = "logging.getLogger(__name__).info(\"✅ Connexion LiveKit multi-agents établie avec succès\")"
    
    if insertion_point in content:
        # Code minimal pour ajouter l'introduction
        introduction_code = '''
        
        # 🎬 GÉNÉRATION INTRODUCTION SIMPLE
        try:
            logging.getLogger(__name__).info("🎬 Génération introduction...")
            
            # Récupération user_data depuis le contexte
            user_data = {
                'user_name': getattr(ctx, 'user_name', 'notre invité'),
                'user_subject': getattr(ctx, 'user_subject', 'un sujet passionnant')
            }
            
            # Génération introduction avec manager
            intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
            logging.getLogger(__name__).info(f"✅ Introduction générée: {len(intro_text)} caractères")
            
            # Note: L'audio sera géré par le système TTS existant
            
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération introduction: {e}")
            # Continuer sans introduction
            pass'''
        
        # Insérer le code après la connexion
        content = content.replace(insertion_point, insertion_point + introduction_code)
        print("✅ Code introduction ajouté après connexion LiveKit")
    else:
        print("⚠️ Point d'insertion non trouvé")
        return False
    
    # Sauvegarder le fichier modifié
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Correction introduction simple appliquée")
    return True

def add_tts_logs_minimal():
    """Ajoute des logs TTS minimaux sans casser la logique existante"""
    
    file_path = "/home/ubuntu/Eloquence/services/livekit-agent/enhanced_multi_agent_manager.py"
    
    # Lire le fichier actuel
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Chercher la méthode synthesize_with_emotion et ajouter un log simple
    old_synthesize = 'async def synthesize_with_emotion(self, text: str, agent_id: str,'
    
    if old_synthesize in content:
        # Ajouter juste un log au début de la méthode
        log_addition = '''async def synthesize_with_emotion(self, text: str, agent_id: str,
                                     emotion: str = "neutre", intensity: float = 0.5) -> bytes:
        """Synthèse vocale avec émotion ElevenLabs v2.5 - ÉMOTIONS SILENCIEUSES"""
        
        # LOG AJOUTÉ POUR DIAGNOSTIC
        logger.info(f"🎵 TTS DÉBUT: {agent_id} - {text[:30]}...")
        
        try:'''
        
        # Remplacer seulement le début de la méthode
        content = content.replace(
            old_synthesize + '\n                                     emotion: str = "neutre", intensity: float = 0.5) -> bytes:\n        """Synthèse vocale avec émotion ElevenLabs v2.5 - ÉMOTIONS SILENCIEUSES"""\n        \n        try:',
            log_addition
        )
        print("✅ Log TTS minimal ajouté")
    else:
        print("⚠️ Méthode synthesize_with_emotion non trouvée")
    
    # Sauvegarder le fichier modifié
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Logs TTS minimaux appliqués")
    return True

def main():
    """Fonction principale de correction minimale"""
    print("🚀 CORRECTION MINIMALE ELOQUENCE - SANS CASSER L'EXISTANT")
    
    try:
        # 1. Corriger l'introduction de façon minimale
        print("\n1️⃣ Ajout appel introduction minimal...")
        fix_introduction_call()
        
        # 2. Ajouter logs TTS minimaux
        print("\n2️⃣ Ajout logs TTS minimaux...")
        add_tts_logs_minimal()
        
        print("\n✅ CORRECTIONS MINIMALES APPLIQUÉES !")
        print("\n🎯 RÉSULTAT ATTENDU :")
        print("- Marcus et Sarah parlent toujours (pas de régression)")
        print("- Introduction de Michel ajoutée")
        print("- Logs TTS pour diagnostic")
        print("\n🔄 REDÉMARRER : docker-compose restart")
        
        return True
        
    except Exception as e:
        print(f"❌ ERREUR LORS DE LA CORRECTION: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

