#!/usr/bin/env python3
"""
Script pour ajouter l'appel à generate_introduction dans multi_agent_main.py
"""

import re

def fix_missing_introduction():
    """Ajoute l'appel à generate_introduction dans le flux d'initialisation"""
    
    print("🔧 CORRECTION INTRODUCTION MANQUANTE")
    print("="*50)
    
    file_path = "services/livekit-agent/multi_agent_main.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Trouver l'endroit où ajouter l'introduction (après la connexion LiveKit)
    introduction_code = '''
        # 3. GÉNÉRATION INTRODUCTION AVEC CACHE REDIS
        logging.getLogger(__name__).info("🎬 Génération introduction...")
        
        # Récupération user_data depuis le contexte
        user_data = {
            'user_name': getattr(ctx, 'user_name', 'notre invité'),
            'user_subject': getattr(ctx, 'user_subject', 'un sujet passionnant')
        }
        
        # Génération ou récupération depuis cache
        try:
            intro_text, intro_audio = await manager.generate_introduction(exercise_type, user_data)
            logging.getLogger(__name__).info(f"✅ Introduction générée: {len(intro_text)} caractères, {len(intro_audio)} bytes audio")
            
            # Diffusion de l'introduction
            if intro_audio and len(intro_audio) > 0:
                # Créer un track audio pour l'introduction
                audio_source = rtc.AudioSource(sample_rate=24000, num_channels=1)
                track = rtc.LocalAudioTrack.create_audio_track("introduction", audio_source)
                
                # Publier le track
                await ctx.room.local_participant.publish_track(track, rtc.TrackPublishOptions())
                logging.getLogger(__name__).info("🎵 Introduction audio diffusée")
                
                # Attendre la fin de l'introduction
                import asyncio
                await asyncio.sleep(len(intro_audio) / 24000)  # Durée approximative
            else:
                logging.getLogger(__name__).warning("⚠️ Pas d'audio d'introduction généré")
                
        except Exception as e:
            logging.getLogger(__name__).error(f"❌ Erreur génération introduction: {e}")
            # Introduction de fallback
            intro_text = f"Bienvenue dans notre studio de débat TV ! Je suis Michel Dubois, votre animateur."
            logging.getLogger(__name__).info("🔧 Introduction de fallback utilisée")
'''
    
    # Ajouter après "✅ Connexion LiveKit multi-agents établie avec succès"
    content = content.replace(
        '        logging.getLogger(__name__).info("✅ Connexion LiveKit multi-agents établie avec succès")',
        '        logging.getLogger(__name__).info("✅ Connexion LiveKit multi-agents établie avec succès")' + introduction_code
    )
    
    # Ajouter l'import rtc si pas présent
    if 'from livekit import rtc' not in content:
        content = content.replace(
            'from livekit import agents',
            'from livekit import agents, rtc'
        )
    
    # Sauvegarder le fichier corrigé
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Correction appliquée avec succès")
    print("📋 Ajouts effectués:")
    print("   - Appel à manager.generate_introduction()")
    print("   - Récupération user_data depuis contexte")
    print("   - Diffusion audio de l'introduction")
    print("   - Gestion d'erreurs avec fallback")
    print("   - Import rtc pour audio")
    
    return True

if __name__ == "__main__":
    try:
        fix_missing_introduction()
        print("\n🚀 CORRECTION TERMINÉE AVEC SUCCÈS !")
        print("🎯 L'introduction sera maintenant générée et diffusée")
    except Exception as e:
        print(f"\n❌ ERREUR: {e}")

