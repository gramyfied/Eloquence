#!/usr/bin/env python3
"""
Script de correction pour :
1. Introduction pré-générée dans Redis (démarrage rapide)
2. Correction mapping voix Marcus/Sarah
"""

import os
import re

def fix_startup_and_voices():
    """Corrige le démarrage lent et les voix Marcus/Sarah"""
    
    print("🔧 CORRECTION DÉMARRAGE RAPIDE + VOIX MARCUS/SARAH")
    print("="*60)
    
    # 1. CORRECTION ENHANCED_MULTI_AGENT_MANAGER
    file_path = "services/livekit-agent/enhanced_multi_agent_manager.py"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ajouter introduction pré-générée dans Redis
    redis_intro_code = '''
    async def get_cached_introduction(self, exercise_type: str) -> Optional[Tuple[str, bytes]]:
        """Récupère l'introduction pré-générée depuis Redis"""
        try:
            import redis
            r = redis.Redis(host='redis', port=6379, decode_responses=False)
            
            # Clé pour l'introduction
            intro_key = f"intro:{exercise_type}:text"
            audio_key = f"intro:{exercise_type}:audio"
            
            # Récupérer depuis Redis
            intro_text = r.get(intro_key)
            intro_audio = r.get(audio_key)
            
            if intro_text and intro_audio:
                logger.info("✅ Introduction récupérée depuis Redis")
                return intro_text.decode('utf-8'), intro_audio
            else:
                logger.info("⚠️ Introduction non trouvée dans Redis, génération nécessaire")
                return None
                
        except Exception as e:
            logger.error(f"❌ Erreur récupération Redis: {e}")
            return None
    
    async def cache_introduction(self, exercise_type: str, text: str, audio: bytes):
        """Met en cache l'introduction dans Redis"""
        try:
            import redis
            r = redis.Redis(host='redis', port=6379, decode_responses=False)
            
            # Clés pour l'introduction
            intro_key = f"intro:{exercise_type}:text"
            audio_key = f"intro:{exercise_type}:audio"
            
            # Sauvegarder dans Redis (expire après 24h)
            r.setex(intro_key, 86400, text.encode('utf-8'))
            r.setex(audio_key, 86400, audio)
            
            logger.info("✅ Introduction mise en cache dans Redis")
            
        except Exception as e:
            logger.error(f"❌ Erreur mise en cache Redis: {e}")
'''
    
    # Ajouter avant la méthode test_tts_integration
    content = content.replace(
        'async def test_tts_integration(self) -> bool:',
        redis_intro_code + '\n    async def test_tts_integration(self) -> bool:'
    )
    
    # 2. CORRECTION MAPPING VOIX MARCUS/SARAH
    voice_mapping_fix = '''                    # Sélection de la voix selon l'agent - MAPPING CORRIGÉ
                    voice_mapping = {
                        'michel_dubois_animateur': 'George',    # Voix masculine neutre - TESTÉ OK
                        'sarah_johnson_journaliste': 'Bella',   # Voix féminine neutre - CORRECTION
                        'marcus_thompson_expert': 'Arnold',     # Voix masculine mesurée - CORRECTION
                        # Fallbacks pour compatibilité
                        'michel_dubois': 'George',
                        'sarah_johnson': 'Bella', 
                        'marcus_thompson': 'Arnold'
                    }
                    
                    voice_id = voice_mapping.get(agent_id, 'George')
                    logger.info(f"🎭 Agent {agent_id} → Voix {voice_id}")'''
    
    # Remplacer le mapping voix existant
    content = re.sub(
        r'# Sélection de la voix selon l\'agent[\s\S]*?voice_id = voice_mapping\.get\(agent_id, \'George\'\)',
        voice_mapping_fix,
        content,
        count=1
    )
    
    # 3. AMÉLIORER LES LOGS TTS
    tts_logs_fix = '''                    # Génération audio avec émotion - LOGS AMÉLIORÉS
                    logger.info(f"🎵 Génération TTS pour {agent_id} avec voix {voice_id}")
                    logger.info(f"🎭 Émotion: {emotion.primary_emotion}, Intensité: {emotion.intensity}")
                    
                    audio_data = await self.tts_service.synthesize_with_emotion(
                        text=response,
                        voice_id=voice_id,
                        emotion=emotion.primary_emotion,
                        intensity=emotion.intensity
                    )
                    
                    if len(audio_data) > 0:
                        logger.info(f"✅ Audio généré pour {agent_id}: {len(audio_data)} bytes")
                    else:
                        logger.error(f"❌ Audio vide pour {agent_id} avec voix {voice_id}")'''
    
    # Remplacer la génération audio
    content = re.sub(
        r'# Génération audio avec émotion[\s\S]*?logger\.info\(f"✅ Audio généré pour \{agent_id\}: \{len\(audio_data\)\} bytes"\)',
        tts_logs_fix,
        content,
        count=1
    )
    
    # 4. UTILISER INTRODUCTION CACHÉE
    intro_usage_fix = '''    async def generate_introduction(self, exercise_type: str, user_data: dict) -> Tuple[str, bytes]:
        """Génère ou récupère l'introduction depuis le cache"""
        
        # 1. ESSAYER DE RÉCUPÉRER DEPUIS REDIS
        cached = await self.get_cached_introduction(exercise_type)
        if cached:
            intro_text, intro_audio = cached
            logger.info("🚀 Introduction récupérée depuis Redis - DÉMARRAGE RAPIDE")
            return intro_text, intro_audio
        
        # 2. GÉNÉRATION SI PAS EN CACHE
        logger.info("⏳ Génération nouvelle introduction...")
        
        if exercise_type == 'studio_debate_tv':
            intro_text = f\"\"\"Bonsoir et bienvenue dans notre studio de débat TV ! 
Je suis Michel Dubois, votre animateur. Nous accueillons aujourd'hui {user_data.get('user_name', 'notre invité')} 
pour débattre sur le sujet : {user_data.get('user_subject', 'un sujet passionnant')}.
Nous sommes également rejoints par Sarah Johnson, journaliste d'investigation, 
et Marcus Thompson, expert reconnu dans le domaine.
Commençons ce débat enrichissant !\"\"\"
        else:
            intro_text = "Bienvenue dans notre studio !"
        
        # 3. GÉNÉRATION AUDIO
        audio_data = b""
        if self.tts_service:
            try:
                audio_data = await self.tts_service.synthesize_with_emotion(
                    text=intro_text,
                    voice_id="George",  # Michel pour l'introduction
                    emotion="enthousiasme",
                    intensity=0.7
                )
                logger.info(f"✅ Audio introduction généré: {len(audio_data)} bytes")
            except Exception as e:
                logger.error(f"❌ Erreur génération audio introduction: {e}")
        
        # 4. MISE EN CACHE POUR LA PROCHAINE FOIS
        if audio_data:
            await self.cache_introduction(exercise_type, intro_text, audio_data)
        
        return intro_text, audio_data'''
    
    # Remplacer ou ajouter la méthode generate_introduction
    if 'async def generate_introduction(' in content:
        content = re.sub(
            r'async def generate_introduction\([\s\S]*?return intro_text, audio_data',
            intro_usage_fix.strip() + '\n        return intro_text, audio_data',
            content,
            count=1
        )
    else:
        # Ajouter avant test_tts_integration
        content = content.replace(
            'async def test_tts_integration(self) -> bool:',
            intro_usage_fix + '\n\n    async def test_tts_integration(self) -> bool:'
        )
    
    # Sauvegarder le fichier corrigé
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Corrections appliquées avec succès")
    print("📋 Corrections effectuées:")
    print("   - Introduction pré-générée dans Redis")
    print("   - Mapping voix corrigé (Sarah→Bella, Marcus→Arnold)")
    print("   - Logs TTS améliorés pour diagnostic")
    print("   - Méthode generate_introduction avec cache")
    
    return True

if __name__ == "__main__":
    try:
        fix_startup_and_voices()
        print("\n🚀 CORRECTIONS TERMINÉES AVEC SUCCÈS !")
        print("🎯 Redémarrez Docker pour appliquer les changements")
    except Exception as e:
        print(f"\n❌ ERREUR: {e}")

