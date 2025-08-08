#!/usr/bin/env python3
"""
Point d'entrée unifié pour router les exercices LiveKit
Détecte automatiquement le type d'exercice et route vers le bon système
"""

import os
import logging
from typing import Optional
from livekit import agents
from livekit.agents import AutoSubscribe, JobContext, JobRequest, WorkerOptions, cli

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('unified_entrypoint')

# Définition des types d'exercices
MULTI_AGENT_EXERCISES = {
    'studio_situations_pro',
    'simulation_entretien',
    'negociation_commerciale',
    'presentation_investisseurs',
    'reunion_equipe',
    'pitch_elevator',
    'conference_presse',
    'debat_contradictoire',
    'mediation_conflit',
    'formation_equipe',
    'entretien_evaluation',
    'vente_produit'
}

INDIVIDUAL_EXERCISES = {
    'tribunal_idees_impossibles',
    'confidence_boost'
}

async def unified_entrypoint(ctx: JobContext):
    """Point d'entrée unifié qui route vers le bon système"""
    
    logger.info("🚀 === UNIFIED ENTRYPOINT STARTED ===")
    logger.info(f"📍 Room: {ctx.room.name}")
    logger.info(f"👥 Participant count: {len(ctx.room.remote_participants)}")
    logger.info(f"🔍 DIAGNOSTIC: Unified router actif - Version Multi-Agents")
    
    # Récupération des métadonnées pour identifier l'exercice
    exercise_type = None
    participant_metadata = {}
    
    # Chercher les métadonnées dans les participants
    for participant in ctx.room.remote_participants.values():
        if participant.metadata:
            logger.info(f"Participant {participant.identity} metadata: {participant.metadata}")
            try:
                import json
                metadata = json.loads(participant.metadata)
                participant_metadata = metadata
                
                # Détecter le type d'exercice
                if 'exercise' in metadata:
                    exercise_type = metadata['exercise']
                elif 'exerciseType' in metadata:
                    exercise_type = metadata['exerciseType']
                elif 'exercise_type' in metadata:
                    exercise_type = metadata['exercise_type']
                    
                logger.info(f"Detected exercise type: {exercise_type}")
                break
            except Exception as e:
                logger.error(f"Error parsing metadata: {e}")
    
    # Si pas d'exercice détecté dans les métadonnées, essayer le nom de la room
    if not exercise_type and ctx.room.name:
        room_name_lower = ctx.room.name.lower()
        logger.info(f"🔎 Analyse du nom de room: '{ctx.room.name}'")
        
        # Détecter depuis le nom de la room
        if 'studio' in room_name_lower or 'situation' in room_name_lower:
            exercise_type = 'studio_situations_pro'
            logger.info("✅ Détecté: STUDIO SITUATIONS PRO (multi-agents)")
        elif 'tribunal' in room_name_lower:
            exercise_type = 'tribunal_idees_impossibles'
            logger.info("✅ Détecté: TRIBUNAL IDÉES (individuel)")
        elif 'confidence' in room_name_lower or 'boost' in room_name_lower:
            exercise_type = 'confidence_boost'
            logger.info("✅ Détecté: CONFIDENCE BOOST (individuel)")
        else:
            logger.warning(f"⚠️ Type d'exercice non reconnu dans '{ctx.room.name}'")
    
    logger.info(f"🎯 Final exercise type determined: {exercise_type}")
    logger.info("="*60)
    
    # Router vers le bon système
    if exercise_type in MULTI_AGENT_EXERCISES:
        logger.info("🎭 ROUTING TO MULTI-AGENT SYSTEM 🎭")
        logger.info(f"   Exercise: {exercise_type}")
        logger.info(f"   Loading: multi_agent_main.multiagent_entrypoint")
        logger.info("="*60)
        from multi_agent_main import multiagent_entrypoint, detect_exercise_from_metadata
        import json
        
        # La logique multi-agent a besoin de la route et des données utilisateur parsées
        route, user_data = detect_exercise_from_metadata(json.dumps(participant_metadata))
        
        await multiagent_entrypoint(ctx, route, user_data)
        logger.info("✅ Multi-agent session completed")
        
    elif exercise_type in INDIVIDUAL_EXERCISES:
        logger.info("👤 ROUTING TO INDIVIDUAL SYSTEM 👤")
        logger.info(f"   Exercise: {exercise_type}")
        logger.info(f"   Loading: main.robust_entrypoint")
        logger.info("="*60)
        from main import robust_entrypoint
        await robust_entrypoint(ctx)
        logger.info("✅ Individual session completed")
        
    else:
        logger.warning(f"⚠️ Unknown exercise type: {exercise_type}, defaulting to individual system")
        logger.info("🔄 FALLBACK TO INDIVIDUAL SYSTEM")
        from main import robust_entrypoint
        await robust_entrypoint(ctx)

async def request_fnc(req: JobRequest) -> None:
    """Accepter toutes les requêtes de job"""
    logger.info(f"Job request received for room: {req.room.name}")
    # Note: Dans LiveKit 1.2.4, accept() ne prend plus de paramètre
    # L'entrypoint est défini dans WorkerOptions
    await req.accept()

if __name__ == "__main__":
    # Configuration depuis les variables d'environnement
    livekit_url = os.getenv("LIVEKIT_URL", "ws://localhost:7880")
    api_key = os.getenv("LIVEKIT_API_KEY", "devkey")
    api_secret = os.getenv("LIVEKIT_API_SECRET", "devsecret123456789abcdef0123456789abcdef")
    
    logger.info("🚀 === UNIFIED LIVEKIT AGENT STARTING ===")
    logger.info("📌 MODE: UNIFIED ROUTER (Multi-Agents + Individual)")
    logger.info(f"🔗 LiveKit URL: {livekit_url}")
    logger.info(f"🔑 API Key: {api_key[:10]}...")
    logger.info("📋 Supported exercise types:")
    logger.info(f"  🎭 Multi-Agent ({len(MULTI_AGENT_EXERCISES)}): {MULTI_AGENT_EXERCISES}")
    logger.info(f"  👤 Individual ({len(INDIVIDUAL_EXERCISES)}): {INDIVIDUAL_EXERCISES}")
    logger.info("🎯 Router will automatically detect and route to correct system")
    logger.info("="*60)
    
    # Lancer le worker avec le point d'entrée unifié
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=unified_entrypoint,
            request_fnc=request_fnc,
            ws_url=livekit_url,
            api_key=api_key,
            api_secret=api_secret,
        )
    )
